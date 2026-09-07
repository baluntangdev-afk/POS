import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/storage/merchant_device_storage.dart';
import '../../merchant/data/merchant_api.dart';
import '../../merchant/state/merchant_notifier.dart';
import '../../../core/notifications/order_toast.dart';
import '../../../core/services/notifications/order_notifications_service.dart';
import '../data/models/order_event_dto.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/orders_live_feed_repository.dart';
import 'orders_notifier.dart';

const _initialBackoff = Duration(seconds: 1);
const _maxBackoff = Duration(seconds: 30);
const _stableConnectionThreshold = Duration(seconds: 5);
const _readyTimeout = Duration(seconds: 10);

/// After the first successful connect, the upstream service replays a backlog
/// of existing orders. Mute toasts + OS notifications for this window so that
/// initial burst doesn't spam the merchant. The list and local DB still update.
const _hydrationMuteWindow = Duration(seconds: 4);

enum OrdersFeedConnection { connecting, connected, reconnecting, disconnected }

class OrdersFeedState {
  const OrdersFeedState({required this.connection, this.merchantId});

  final OrdersFeedConnection connection;
  final String? merchantId;

  OrdersFeedState copyWith({
    OrdersFeedConnection? connection,
    String? merchantId,
  }) => OrdersFeedState(
    connection: connection ?? this.connection,
    merchantId: merchantId ?? this.merchantId,
  );
}

final ordersFeedNotifierProvider =
    AsyncNotifierProvider<OrdersFeedNotifier, OrdersFeedState>(
      OrdersFeedNotifier.new,
    );

class OrdersFeedNotifier extends AsyncNotifier<OrdersFeedState> {
  StreamSubscription<OrderEventDto>? _subscription;
  OrdersSocketSession? _session;
  Timer? _retryTimer;
  Duration _backoff = _initialBackoff;
  DateTime? _connectedAt;
  String? _merchantId;
  final Queue<String> _recentEventIds = Queue();
  final Set<String> _seenEventIds = {};

  /// Bumped on every [_connect] entry and on every teardown/reset. An in-flight
  /// connect whose captured generation no longer matches has been superseded
  /// (e.g. by [checkConnection] racing the provider's own `build`) and must
  /// abandon its socket instead of wiring it up.
  int _connectGeneration = 0;

  /// True while a [_connect] attempt is running. Lets [checkConnection]
  /// distinguish "nothing is happening, start a connect" from "a connect is
  /// already in flight, leave it alone".
  bool _connecting = false;

  /// Whether the feed has completed its first successful connect this session.
  bool _hasHydrated = false;

  /// Toasts + OS notifications are suppressed until this instant (see
  /// [_hydrationMuteWindow]).
  DateTime _muteNotificationsUntil = DateTime.fromMillisecondsSinceEpoch(0);

  late final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository(
    getIt<MerchantApi>(),
    getIt<MerchantDeviceStorage>(),
  );

  @override
  Future<OrdersFeedState> build() async {
    ref.keepAlive();
    ref.onDispose(_teardown);
    ref.listen(connectivityStatusProvider, _onConnectivityChange);

    final merchant = await ref.watch(merchantProvider.future);
    if (merchant == null) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    // Only connect when the device is registered (webhook token present).
    final webhookToken = await getIt<MerchantDeviceStorage>().token;
    if (webhookToken == null || webhookToken.isEmpty) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    unawaited(_connect(merchant.merchantId));
    return OrdersFeedState(
      connection: OrdersFeedConnection.connecting,
      merchantId: merchant.merchantId,
    );
  }

  /// Call from the dashboard after a merchant change or token refresh to verify
  /// the socket is targeting the right merchant and reconnect if needed.
  Future<void> checkConnection() async {
    final merchant = await ref.read(merchantProvider.future);
    final webhookToken = await getIt<MerchantDeviceStorage>().token;

    // Mirror [build]'s guard: no merchant, or an unregistered device (no
    // webhook token), means there's nothing to connect to.
    if (merchant == null || webhookToken == null || webhookToken.isEmpty) {
      _teardown();
      state = const AsyncData(
        OrdersFeedState(connection: OrdersFeedConnection.disconnected),
      );
      return;
    }

    final merchantChanged =
        _merchantId != null && _merchantId != merchant.merchantId;

    // A connect for the right merchant is already running or established. On
    // app start the provider's own `build` kicks off `_connect`, and this call
    // (from the dashboard's post-frame callback) races it — without this guard
    // it would tear that attempt down and start a duplicate, replaying the
    // backlog twice. Leave the in-flight/live connection alone.
    if (!merchantChanged && (_connecting || _session != null)) return;

    final current = state.value;
    final alreadyOnTarget =
        current != null &&
        !merchantChanged &&
        current.merchantId == merchant.merchantId &&
        (current.connection == OrdersFeedConnection.connected ||
            current.connection == OrdersFeedConnection.connecting);
    if (alreadyOnTarget) return;

    // Either nothing's connected yet, or the merchant ID changed underneath an
    // existing session. A same-merchant reconnect keeps the de-dupe ring (so
    // the replayed backlog stays de-duplicated); a merchant change wipes it.
    if (merchantChanged) {
      _teardown();
    } else {
      _resetConnection();
    }
    state = AsyncData(
      (current ??
              const OrdersFeedState(
                connection: OrdersFeedConnection.connecting,
              ))
          .copyWith(
            connection: OrdersFeedConnection.connecting,
            merchantId: merchant.merchantId,
          ),
    );
    unawaited(_connect(merchant.merchantId));
  }

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
    final merchantId = _merchantId ?? state.value?.merchantId;
    if (merchantId == null || merchantId.isEmpty) return;
    unawaited(_connect(merchantId));
  }

  Future<void> _connect(String merchantId) async {
    _retryTimer?.cancel();

    // Supersede any older in-flight attempt and drop any live socket.
    final generation = ++_connectGeneration;
    _connecting = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;

    try {
      _merchantId = merchantId;

      final deviceToken = await _deviceTokenRepo.ensureToken(merchantId);
      if (generation != _connectGeneration) return;

      final repository = OrdersLiveFeedRepository(EnvConfig.wsBaseUrl);
      final session = repository.connect(merchantId, bearerToken: deviceToken);

      try {
        await session.ready.timeout(_readyTimeout);
      } catch (_) {
        unawaited(session.close());
        rethrow;
      }

      // A newer attempt started while we waited on the handshake — this socket
      // is orphaned, close it without touching state.
      if (generation != _connectGeneration) {
        unawaited(session.close());
        return;
      }

      _session = session;
      _connectedAt = DateTime.now();
      if (!_hasHydrated) {
        _hasHydrated = true;
        _muteNotificationsUntil = DateTime.now().add(_hydrationMuteWindow);
      }
      _subscription = session.events.listen(
        _onEvent,
        onError: _onDrop,
        onDone: _onDrop,
      );
      _setConnection(OrdersFeedConnection.connected, merchantId: merchantId);
    } catch (error, stackTrace) {
      if (generation != _connectGeneration) return;
      debugPrint('[OrdersFeed] connect failed: $error\n$stackTrace');
      _session = null;

      // Stale/revoked device token — drop it so the next attempt re-mints.
      if (_looksLikeAuthRejection(error)) {
        unawaited(_deviceTokenRepo.invalidate());
      }

      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect(merchantId);
    } finally {
      if (generation == _connectGeneration) _connecting = false;
    }
  }

  void _onEvent(OrderEventDto event) {
    // Drop duplicate deliveries. The upstream service can redeliver, and it
    // replays a backlog on every resubscribe — the ring survives reconnects
    // (only a full teardown clears it) so those replays are de-duplicated here.
    if (!_seenEventIds.add(event.eventId)) return;
    _recentEventIds.add(event.eventId);
    if (_recentEventIds.length > 200) {
      _seenEventIds.remove(_recentEventIds.removeFirst());
    }

    // Suppress the notification burst from the first-connect backlog replay.
    if (DateTime.now().isAfter(_muteNotificationsUntil)) {
      showOrderToast(event);
      unawaited(getIt<OrderNotificationsService>().notify(event));
    }

    final merchantId = _merchantId;
    if (merchantId != null) {
      unawaited(
        ref.read(ordersProvider.notifier).applyLiveEvent(event, merchantId),
      );
    }
  }

  void _onDrop([Object? error, StackTrace? stackTrace]) {
    if (_subscription == null) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;

    final wasStable =
        _connectedAt != null &&
        DateTime.now().difference(_connectedAt!) > _stableConnectionThreshold;
    if (wasStable) _backoff = _initialBackoff;

    _setConnection(OrdersFeedConnection.reconnecting);
    final merchantId = _merchantId;
    if (merchantId != null) _scheduleReconnect(merchantId);
  }

  void _scheduleReconnect(String merchantId) {
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff, () => unawaited(_connect(merchantId)));
    final doubled = _backoff * 2;
    _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  void _setConnection(
    OrdersFeedConnection connection, {
    String? merchantId,
  }) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        connection: connection,
        merchantId: merchantId ?? current.merchantId,
      ),
    );
  }

  bool _looksLikeAuthRejection(Object error) {
    final text = error.toString();
    return text.contains('401') ||
        text.contains('403') ||
        text.toLowerCase().contains('unauthorized') ||
        text.toLowerCase().contains('forbidden');
  }

  /// Drops the socket, cancels any pending retry, and invalidates in-flight
  /// connect attempts — but keeps the de-dupe ring and target merchant. Used
  /// when reconnecting to the *same* merchant so the backlog replay stays
  /// de-duplicated.
  void _resetConnection() {
    _connectGeneration++;
    _connecting = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;
    _backoff = _initialBackoff;
    _connectedAt = null;
  }

  /// Full reset — also forgets the de-dupe ring, the target merchant, and the
  /// hydration state. Used on dispose and on a merchant change.
  void _teardown() {
    _resetConnection();
    _merchantId = null;
    _recentEventIds.clear();
    _seenEventIds.clear();
    _hasHydrated = false;
    _muteNotificationsUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
