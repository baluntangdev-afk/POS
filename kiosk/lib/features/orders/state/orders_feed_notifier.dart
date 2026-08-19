import 'dart:async';
import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../auth/state/login_state_notifier.dart';
import '../entities/order_event.dart';
import '../entities/orders_feed_state.dart';
import '../repositories/orders_live_feed_repository.dart';

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
  final Queue<String> _recentEventIds = Queue();
  final Set<String> _seenEventIds = {};

  @override
  Future<OrdersFeedState> build() async {
    ref.keepAlive();
    final loggedIn = ref.watch(loginStateProvider.select((auth) => auth.value != null));
    ref.onDispose(_teardown);

    if (!loggedIn) {
      _teardown();
      return const OrdersFeedState(connection: OrdersFeedConnection.disconnected);
    }

    unawaited(_connect());
    return const OrdersFeedState(connection: OrdersFeedConnection.connecting);
  }

  Future<void> _connect() async {
    _retryTimer?.cancel();
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(terminal.kioskId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(_onEvent, onError: _onDrop, onDone: _onDrop);
      _setConnection(OrdersFeedConnection.connected);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect();
    }
  }

  void _onEvent(OrderEvent event) {
    if (!_seenEventIds.add(event.eventId)) return;
    _recentEventIds.add(event.eventId);
    if (_recentEventIds.length > 200) {
      _seenEventIds.remove(_recentEventIds.removeFirst());
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

  void _setConnection(OrdersFeedConnection connection) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(connection: connection));
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
  }
}
