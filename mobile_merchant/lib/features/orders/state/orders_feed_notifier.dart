import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/storage/merchant_device_storage.dart';
import '../../merchant/data/merchant_api.dart';
import '../../merchant/state/merchant_notifier.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/orders_live_feed_repository.dart';
import 'orders_notifier.dart';

const _initialBackoff = Duration(seconds: 1);
const _maxBackoff = Duration(seconds: 30);
const _stableConnectionThreshold = Duration(seconds: 5);
const _readyTimeout = Duration(seconds: 10);

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
  StreamSubscription<String>? _subscription;
  OrdersSocketSession? _session;
  Timer? _retryTimer;
  Duration _backoff = _initialBackoff;
  DateTime? _connectedAt;
  String? _merchantId;

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
    if (merchant == null) {
      _teardown();
      state = const AsyncData(
        OrdersFeedState(connection: OrdersFeedConnection.disconnected),
      );
      return;
    }

    final current = state.value;
    final alreadyOnTarget =
        current != null &&
        current.merchantId == merchant.merchantId &&
        (current.connection == OrdersFeedConnection.connected ||
            current.connection == OrdersFeedConnection.connecting);
    if (alreadyOnTarget) return;

    _teardown();
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
    try {
      _merchantId = merchantId;

      final deviceToken = await _deviceTokenRepo.ensureToken(merchantId);
      final repository = OrdersLiveFeedRepository(EnvConfig.wsBaseUrl);
      final session = repository.connect(merchantId, bearerToken: deviceToken);
      _session = session;

      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.messages.listen(
        _onMessage,
        onError: _onDrop,
        onDone: _onDrop,
      );
      _setConnection(OrdersFeedConnection.connected, merchantId: merchantId);
    } catch (error, stackTrace) {
      debugPrint('[OrdersFeed] connect failed: $error\n$stackTrace');
      unawaited(_session?.close());
      _session = null;

      // Stale/revoked device token — drop it so the next attempt re-mints.
      if (_looksLikeAuthRejection(error)) {
        unawaited(_deviceTokenRepo.invalidate());
      }

      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect(merchantId);
    }
  }

  void _onMessage(String raw) {
    debugPrint('[OrdersFeed] message received');
    // Trigger a REST refresh so the orders list reflects the new event.
    ref.invalidate(ordersProvider);
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

  void _teardown() {
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_session?.close());
    _session = null;
    _backoff = _initialBackoff;
    _connectedAt = null;
    _merchantId = null;
  }
}
