import 'dart:async';
import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/connectivity/connectivity_status_provider.dart';
import '../../../data/backend_api/sources/orders_history_api.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../auth/state/login_state_notifier.dart';
import '../entities/order_event.dart';
import '../entities/orders_feed_state.dart';
import '../repositories/order_events_local_repository.dart';
import '../repositories/orders_live_feed_repository.dart';
import '../use_cases/latest_event_per_order.dart';

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
    ref.onDispose(_teardown);
    ref.listen(isOnlineProvider, _onConnectivityChange);

    if (!loggedIn) {
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
      _kioskId = terminal.kioskId;
      await _syncHistory(terminal.kioskId);
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(terminal.kioskId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(_onEvent, onError: _onDrop, onDone: _onDrop);
      _setConnection(OrdersFeedConnection.connected, kioskId: terminal.kioskId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect();
    }
  }

  /// Backfills local order history for [kioskId] from the REST endpoint,
  /// merging with write-if-newer semantics so it can never overwrite an
  /// order the live socket has already updated more recently. Runs before
  /// the socket opens in [_connect] (covering login and kiosk-ID changes
  /// for free, since both already rebuild this notifier); also callable
  /// standalone via [refreshHistory]. Best-effort: a failure here doesn't
  /// stop the socket from connecting, and doesn't surface an error to the
  /// UI — the screen keeps showing whatever's already persisted.
  Future<void> _syncHistory(String kioskId) async {
    try {
      final events = await ref.read(ordersHistoryApiProvider).fetchEvents(kioskId);
      final latest = latestEventPerOrder(events);
      final repository = ref.read(orderEventsLocalRepositoryProvider);
      for (final event in latest) {
        await repository.saveIfNewer(event, kioskId: kioskId);
      }
    } catch (e, st) {
      debugPrint('[OrdersFeed] history backfill failed: $e\n$st');
    }
  }

  /// Re-fetches order history from the REST endpoint and merges it into
  /// local storage, without touching the live socket connection. Used by
  /// the Orders screen's on-mount load and pull-to-refresh. No-ops if this
  /// notifier hasn't resolved a kiosk ID yet (not logged in / still
  /// connecting for the first time).
  Future<void> refreshHistory() async {
    final kioskId = _kioskId;
    if (kioskId == null) return;
    await _syncHistory(kioskId);
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
