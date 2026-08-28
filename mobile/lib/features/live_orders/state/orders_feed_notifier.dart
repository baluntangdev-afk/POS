import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/connectivity/connectivity_status_provider.dart';
import '../../../core/result/result.dart';
import '../../../data/backend_api/sources/orders_history_api.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../settings/state/store_info_notifier.dart';
import '../entities/order_event.dart';
import '../entities/orders_feed_state.dart';
import '../repositories/order_events_local_repository.dart';
import '../repositories/orders_live_feed_repository.dart';
import '../repositories/webhook_auth_repository.dart';
import '../use_cases/latest_event_per_order.dart';
import '../use_cases/order_update_error.dart';

const _initialBackoff = Duration(seconds: 1);
const _maxBackoff = Duration(seconds: 30);
const _stableConnectionThreshold = Duration(seconds: 5);
const _readyTimeout = Duration(seconds: 10);

final ordersFeedNotifierProvider =
    AsyncNotifierProvider<OrdersFeedNotifier, OrdersFeedState>(
      OrdersFeedNotifier.new,
      name: 'ordersFeedNotifierProvider',
    );

class OrdersFeedNotifier extends AsyncNotifier<OrdersFeedState> {
  StreamSubscription<OrderEvent>? _subscription;
  OrdersSocketSession? _session;
  Timer? _retryTimer;
  Duration _backoff = _initialBackoff;
  DateTime? _connectedAt;
  String? _storeId;
  final Queue<String> _recentEventIds = Queue();
  final Set<String> _seenEventIds = {};

  @override
  Future<OrdersFeedState> build() async {
    ref.keepAlive();
    final authed = ref.watch(authNotifierProvider) is AuthAuthenticated;
    final storeInfo = await ref.watch(storeInfoProvider.future);
    final storeId = storeInfo?.storeId ?? '';
    ref.onDispose(_teardown);
    ref.listen(isOnlineProvider, _onConnectivityChange);

    if (!authed || storeId.isEmpty) {
      _teardown();
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    unawaited(_connect(storeId));
    return const OrdersFeedState(connection: OrdersFeedConnection.connecting);
  }

  Future<void> checkConnection() async {
    final authed = ref.read(authNotifierProvider) is AuthAuthenticated;
    final storeInfo = await ref.read(storeInfoProvider.future);
    final storeId = storeInfo?.storeId ?? '';

    if (!authed || storeId.isEmpty) {
      _teardown();
      state = const AsyncData(
        OrdersFeedState(connection: OrdersFeedConnection.disconnected),
      );
      return;
    }

    final current = state.value;
    final alreadyOnTarget =
        current != null &&
        current.storeId == storeId &&
        (current.connection == OrdersFeedConnection.connected ||
            current.connection == OrdersFeedConnection.connecting);
    if (alreadyOnTarget) return;

    // Either nothing's connected yet, or the store ID changed underneath an
    // existing session — tear down any stale socket for the old ID first.
    _teardown();
    state = AsyncData(
      (current ??
              const OrdersFeedState(
                connection: OrdersFeedConnection.connecting,
              ))
          .copyWith(
            connection: OrdersFeedConnection.connecting,
            storeId: storeId,
          ),
    );
    unawaited(_connect(storeId));
  }

  /// Reconnects immediately when the device comes back online while the
  /// socket is mid-backoff, instead of waiting out whatever delay
  /// [_scheduleReconnect] left in flight.
  void _onConnectivityChange(
    AsyncValue<bool>? previous,
    AsyncValue<bool> next,
  ) {
    final wasOnline = previous?.value ?? false;
    final isOnline = next.value ?? false;
    if (wasOnline || !isOnline) return;

    final connection = state.value?.connection;
    if (connection != OrdersFeedConnection.reconnecting &&
        connection != OrdersFeedConnection.disconnected) {
      return;
    }
    final storeId = _storeId ?? state.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;
    unawaited(_connect(storeId));
  }

  Future<void> _connect(String storeId) async {
    _retryTimer?.cancel();
    try {
      _storeId = storeId;
      await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
      await _syncHistory(storeId);
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(storeId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(
        _onEvent,
        onError: _onDrop,
        onDone: _onDrop,
      );
      _setConnection(OrdersFeedConnection.connected, storeId: storeId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect(storeId);
    }
  }

  /// Backfills local order history for [storeId] from the REST endpoint,
  /// merging with write-if-newer semantics so it can never overwrite an
  /// order the live socket has already updated more recently. Runs before
  /// the socket opens in [_connect] (covering login and store-ID changes
  /// for free, since both already rebuild this notifier); also callable
  /// standalone via [refreshHistory]. Best-effort: a failure here doesn't
  /// stop the socket from connecting, and doesn't surface an error to the
  /// UI — the screen keeps showing whatever's already persisted.
  Future<void> _syncHistory(String storeId) async {
    try {
      final events = await ref
          .read(ordersHistoryApiProvider)
          .fetchEvents(storeId);
      final latest = latestEventPerOrder(events);
      final repository = ref.read(orderEventsLocalRepositoryProvider);
      for (final event in latest) {
        await repository.saveIfNewer(event, storeId: storeId);
      }
    } catch (e, st) {
      debugPrint('[OrdersFeed] history backfill failed: $e\n$st');
    }
  }

  /// Re-fetches order history from the REST endpoint and merges it into
  /// local storage, without touching the live socket connection. Used by
  /// the Orders screen's on-mount load and pull-to-refresh. No-ops if this
  /// notifier hasn't resolved a store ID yet (not logged in / still
  /// connecting for the first time).
  Future<void> refreshHistory() async {
    final storeId = _storeId;
    if (storeId == null) return;
    await _syncHistory(storeId);
  }

  /// Manually updates an order through the REST endpoint and persists the
  /// returned `order.updated` event locally, so the Orders screen (which
  /// reads the persisted `order_events` table) reflects the change right
  /// away instead of waiting on the WS echo. The live feed will also
  /// broadcast the same event — [_onEvent]'s `_seenEventIds` guard de-dupes
  /// it. Returns the reason on failure so the caller can surface it.
  Future<Result<OrderEvent, OrderUpdateError>> applyOrderUpdate(
    String orderId, {
    required Map<String, dynamic> updates,
  }) async {
    final storeId = _storeId ?? state.value?.storeId;
    if (storeId == null || storeId.isEmpty) {
      return const Failure(OrderUpdateError.unknown);
    }
    try {
      final event = await ref
          .read(ordersHistoryApiProvider)
          .updateOrder(orderId, updates: updates);
      // Pre-seed the de-dupe set so the WS echo of this same event is
      // ignored by [_onEvent]; track it in _recentEventIds too so it's
      // still subject to the normal ring-buffer eviction.
      if (_seenEventIds.add(event.eventId)) {
        _recentEventIds.add(event.eventId);
        if (_recentEventIds.length > 200) {
          _seenEventIds.remove(_recentEventIds.removeFirst());
        }
      }
      await ref
          .read(orderEventsLocalRepositoryProvider)
          .save(event, storeId: storeId);
      return Success(event);
    } catch (e, st) {
      debugPrint('[OrdersFeed] applyOrderUpdate failed: $e\n$st');
      return Failure(orderUpdateErrorFrom(e));
    }
  }

  /// Convenience wrapper over [applyOrderUpdate] for the common case of
  /// moving an order to a new [status] (including `cancelled`).
  Future<Result<OrderEvent, OrderUpdateError>> setOrderStatus(
    String orderId,
    String status,
  ) => applyOrderUpdate(orderId, updates: {'status': status});

  void _onEvent(OrderEvent event) {
    if (!_seenEventIds.add(event.eventId)) return;
    _recentEventIds.add(event.eventId);
    if (_recentEventIds.length > 200) {
      _seenEventIds.remove(_recentEventIds.removeFirst());
    }

    // Persist every event type, not just `created` — `updated`/`cancelled`
    // must overwrite the stored order state so the pending-orders badge
    // (driven by "latest event isn't a cancellation") stays accurate.
    final storeId = _storeId;
    if (storeId != null) {
      unawaited(
        ref
            .read(orderEventsLocalRepositoryProvider)
            .save(event, storeId: storeId),
      );
    }

    final current =
        state.value ??
        const OrdersFeedState(connection: OrdersFeedConnection.connected);
    final events = [event, ...current.events];
    state = AsyncData(
      current.copyWith(
        connection: OrdersFeedConnection.connected,
        events: events.take(ordersFeedMaxEvents).toList(),
      ),
    );
  }

  void _onDrop([Object? error, StackTrace? stackTrace]) {
    if (_subscription == null) return; // already handled by a prior call
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;

    final wasStable =
        _connectedAt != null &&
        DateTime.now().difference(_connectedAt!) > _stableConnectionThreshold;
    if (wasStable) _backoff = _initialBackoff;

    _setConnection(OrdersFeedConnection.reconnecting);
    final storeId = _storeId;
    if (storeId != null) _scheduleReconnect(storeId);
  }

  void _scheduleReconnect(String storeId) {
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff, () => unawaited(_connect(storeId)));
    final doubled = _backoff * 2;
    _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  void _setConnection(OrdersFeedConnection connection, {String? storeId}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        connection: connection,
        storeId: storeId ?? current.storeId,
      ),
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
    _storeId = null;
  }
}
