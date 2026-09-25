import 'dart:async';
import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../core/connectivity/connectivity_status_provider.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../auth/state/login_state_notifier.dart';
import '../entities/merchant_device_state.dart';
import '../entities/order_event.dart';
import '../entities/orders_feed_state.dart';
import '../repositories/device_token_repository.dart';
import '../repositories/order_events_local_repository.dart';
import '../repositories/orders_history_repository.dart';
import '../repositories/orders_live_feed_repository.dart';
import '../repositories/webhook_auth_repository.dart';
import '../use_cases/device_registration_status.dart';
import '../use_cases/device_token_error.dart';
import '../use_cases/webhook_auth_error.dart';
import 'device_token_status_provider.dart';
import 'merchant_device_notifier.dart';
import 'webhook_auth_status_provider.dart';

const _initialBackoff = Duration(seconds: 1);
const _maxBackoff = Duration(seconds: 30);
const _stableConnectionThreshold = Duration(seconds: 5);
const _readyTimeout = Duration(seconds: 10);

final ordersFeedNotifierProvider = AsyncNotifierProvider<OrdersFeedNotifier, OrdersFeedState>(
  OrdersFeedNotifier.new,
  name: 'ordersFeedNotifierProvider',
);

/// Live feed of `order.created` / `order.updated` / `order.cancelled` events
/// from the (external) webhook-receiver, scoped to this terminal's kiosk ID.
///
/// Session-scoped: connects once a cashier is logged in and stays connected
/// regardless of which screen is active, so a new order isn't missed just
/// because nobody has the Orders screen open. Requires network reachability
/// to that external service (separate from — and independent of — reachability
/// to our own backend); reconnects with backoff whenever that's unavailable.
///
/// Unless [kSkipDeviceRegistration] is set, the socket only opens once this
/// kiosk is an `approved` device for the current Kiosk ID, authenticated with
/// the `/devices/token` bearer on the handshake.
class OrdersFeedNotifier extends AsyncNotifier<OrdersFeedState> {
  StreamSubscription<OrderEvent>? _subscription;
  OrdersSocketSession? _session;
  Timer? _retryTimer;
  Duration _backoff = _initialBackoff;
  DateTime? _connectedAt;
  String? _kioskId;
  final Queue<String> _recentEventIds = Queue();
  final Set<String> _seenEventIds = {};

  @override
  Future<OrdersFeedState> build() async {
    ref.keepAlive();
    final loggedIn = ref.watch(loginStateProvider.select((auth) => auth.value != null));
    // Re-runs whenever the device's registration status changes (a cached
    // status rehydrated on launch, or a fresh one from a login / manual
    // `/devices/register` re-check) — the feed connects only once the device
    // is a confirmed `approved` enrolment. A failed local read (e.g. secure
    // storage) is treated as "not approved" rather than throwing.
    MerchantDeviceState deviceState;
    try {
      deviceState = await ref.watch(merchantDeviceNotifierProvider.future);
    } catch (_) {
      deviceState = const MerchantDeviceState();
    }
    ref.onDispose(_teardown);
    ref.listen(isOnlineProvider, _onConnectivityChange);

    if (!loggedIn || !_isApproved(deviceState)) {
      _teardown();
      return const OrdersFeedState(connection: OrdersFeedConnection.disconnected);
    }

    unawaited(_connect());
    return const OrdersFeedState(connection: OrdersFeedConnection.connecting);
  }

  /// Reconnects immediately when the device comes back online while the
  /// socket is mid-backoff, instead of waiting out whatever delay
  /// [_scheduleReconnect] left in flight.
  void _onConnectivityChange(AsyncValue<bool>? previous, AsyncValue<bool> next) {
    final wasOnline = previous?.value ?? false;
    final isOnline = next.value ?? false;
    if (wasOnline || !isOnline) return;

    final connection = state.value?.connection;
    if (connection != OrdersFeedConnection.reconnecting && connection != OrdersFeedConnection.disconnected) {
      return;
    }
    unawaited(_connect());
  }

  Future<void> _connect() async {
    _retryTimer?.cancel();
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      final kioskId = terminal.kioskId;
      // An approval belongs to the Kiosk ID it was registered against. After a
      // Kiosk ID change the device re-registers (see the Kiosk ID save flow),
      // which rebuilds this notifier — until then, stay off.
      if (!kSkipDeviceRegistration) {
        final deviceState = await ref.read(merchantDeviceNotifierProvider.future);
        if (deviceState.registeredStoreId != kioskId) {
          _teardown();
          state = const AsyncData(OrdersFeedState(connection: OrdersFeedConnection.disconnected));
          return;
        }
      }
      _kioskId = kioskId;
      await _ensureToken(kioskId);
      final deviceToken = kSkipDeviceRegistration ? null : await _ensureDeviceToken(kioskId);
      await _syncHistory(kioskId);
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(kioskId, bearerToken: deviceToken);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(_onEvent, onError: _onDrop, onDone: _onDrop);
      _setConnection(OrdersFeedConnection.connected, kioskId: kioskId);
    } catch (error, stackTrace) {
      final reason = switch (error) {
        WebhookAuthException(:final message) => message,
        DeviceTokenException(:final message) => message,
        _ => error.toString(),
      };
      debugPrint('[OrdersFeed] connect failed: $reason\n$stackTrace');
      unawaited(_session?.close());
      _session = null;
      // A handshake the receiver rejected as unauthorized (401/403) means the
      // cached device token is stale/revoked — drop it so the next attempt
      // re-mints instead of replaying the same dead token.
      if (error is! DeviceTokenException && _looksLikeAuthRejection(error)) {
        unawaited(ref.read(deviceTokenRepositoryProvider).invalidate());
      }
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect();
    }
  }

  bool _isApproved(MerchantDeviceState deviceState) =>
      kSkipDeviceRegistration ||
      deviceRegistrationStatusFrom(deviceState.status) == DeviceRegistrationStatus.approved;

  /// Mints the orders-service token, reporting a rejected request to
  /// [webhookAuthStatusProvider] (which drives the toast) before letting the
  /// failure fall through to [_connect]'s reconnect handling.
  Future<void> _ensureToken(String kioskId) async {
    final status = ref.read(webhookAuthStatusProvider.notifier);
    try {
      await ref.read(webhookAuthRepositoryProvider).ensureToken(kioskId);
      status.clear();
    } on WebhookAuthException catch (error) {
      status.reportFailure(error.reason, error.message);
      rethrow;
    }
  }

  /// Mints (or reuses) the `/devices/token` bearer for [kioskId] that
  /// authenticates the WS handshake, reporting a rejection to
  /// [deviceTokenStatusProvider] (which drives the toast) before letting the
  /// failure fall through to [_connect]'s reconnect handling.
  Future<String> _ensureDeviceToken(String kioskId) async {
    final status = ref.read(deviceTokenStatusProvider.notifier);
    try {
      final token = await ref.read(deviceTokenRepositoryProvider).ensureToken(kioskId);
      status.clear();
      return token;
    } on DeviceTokenException catch (error) {
      status.reportFailure(error.reason, error.message);
      rethrow;
    }
  }

  /// Whether a failed handshake looks like the receiver rejecting the bearer
  /// (`IOWebSocketChannel` surfaces the HTTP status in the exception text).
  bool _looksLikeAuthRejection(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('401') ||
        text.contains('403') ||
        text.contains('unauthorized') ||
        text.contains('forbidden');
  }

  /// Backfills local order history for [kioskId], swallowing errors. Runs
  /// before the socket opens in [_connect] (covering login and kiosk-ID
  /// changes for free, since both already rebuild this notifier).
  /// Best-effort: a failure here doesn't stop the socket from connecting,
  /// and doesn't surface an error to the UI — the screen keeps showing
  /// whatever's already persisted.
  Future<void> _syncHistory(String kioskId) async {
    try {
      await ref.read(ordersHistoryRepositoryProvider).syncHistory(kioskId);
    } catch (e, st) {
      debugPrint('[OrdersFeed] history backfill failed: $e\n$st');
    }
  }

  /// Re-syncs order history from the REST endpoint, without touching the
  /// live socket connection. Used by the Orders screen's on-mount load and
  /// pull-to-refresh. No-ops if this notifier hasn't resolved a kiosk ID yet
  /// (not logged in / still connecting for the first time). Unlike
  /// [_syncHistory], this rethrows so the screen can tell the user the
  /// refresh failed.
  Future<void> refreshHistory() async {
    final kioskId = _kioskId;
    if (kioskId == null) return;
    await ref.read(ordersHistoryRepositoryProvider).syncHistory(kioskId);
  }

  void _onEvent(OrderEvent event) {
    debugPrint('[OrdersFeed] event received: ${event.type.name} ${event.eventId} (order ${event.data})');
    if (!_seenEventIds.add(event.eventId)) return;
    _recentEventIds.add(event.eventId);
    if (_recentEventIds.length > 200) {
      _seenEventIds.remove(_recentEventIds.removeFirst());
    }

    // Persist every event type, not just `created` — `updated`/`cancelled`
    // must overwrite the stored order state so the pending-orders badge
    // (driven by "latest event isn't a cancellation") stays accurate.
    final kioskId = _kioskId;
    if (kioskId != null) {
      unawaited(ref.read(orderEventsLocalRepositoryProvider).save(event, kioskId: kioskId));
    }

    final current = state.value ?? const OrdersFeedState(connection: OrdersFeedConnection.connected);
    final events = [event, ...current.events];
    state = AsyncData(
      current.copyWith(
        connection: OrdersFeedConnection.connected,
        events: events.take(ordersFeedMaxEvents).toIList(),
      ),
    );
  }

  void _onDrop([Object? error, StackTrace? stackTrace]) {
    if (_subscription == null) return; // already handled by a prior call
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;

    final wasStable = _connectedAt != null && DateTime.now().difference(_connectedAt!) > _stableConnectionThreshold;
    if (wasStable) _backoff = _initialBackoff;

    _setConnection(OrdersFeedConnection.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff, () => unawaited(_connect()));
    final doubled = _backoff * 2;
    _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  void _setConnection(OrdersFeedConnection connection, {String? kioskId}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(connection: connection, kioskId: kioskId ?? current.kioskId),
    );
  }

  void _teardown() {
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;
    _backoff = _initialBackoff;
    _connectedAt = null;
    _kioskId = null;
  }
}
