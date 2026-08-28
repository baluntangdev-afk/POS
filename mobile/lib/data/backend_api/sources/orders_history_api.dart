import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../../../features/live_orders/entities/order_event.dart';
import '../api_clients.dart';
import '../schemas/webhook_token_dto.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  final env = ref.watch(appEnvProvider);
  return OrdersHistoryApi(httpClient, env);
});

/// Fetches the full stored event log for a merchant from the
/// webhook-receiver's REST history endpoint. This is what backfills the
/// app's local order history — the WS feed only carries events from the
/// moment it connects onward.
class OrdersHistoryApi {
  const OrdersHistoryApi(this._httpClient, this._env);

  final Dio _httpClient;
  final AppEnv _env;

  Future<List<OrderEvent>> fetchEvents(String merchantId) async {
    final response = await _httpClient.get<dynamic>(
      '/merchant/orders',
      queryParameters: {'merchant_id': merchantId},
    );
    final json = response.data as Map<String, dynamic>;
    final rawEvents = json['events'] as List<dynamic>? ?? const <dynamic>[];
    return rawEvents
        .cast<Map<String, dynamic>>()
        .map(OrderEvent.fromWireJson)
        .whereType<OrderEvent>()
        .toList();
  }

  /// Applies a partial update to [orderId] via the webhook-receiver's
  /// manual-update endpoint. The server shallow-merges [updates] onto the
  /// order's last snapshot and returns the resulting `order.updated` event,
  /// which it also broadcasts on the live WS feed. Throws [DioException] on a
  /// non-2xx response (400/401/404/429) — callers map those to a UI reason.
  /// Throws [FormatException] if the 200 body can't be parsed into an
  /// [OrderEvent].
  Future<OrderEvent> updateOrder(
    String orderId, {
    required Map<String, dynamic> updates,
  }) async {
    final response = await _httpClient.patch<dynamic>(
      '/merchant/orders/$orderId',
      data: {'updates': updates},
    );
    final json = response.data as Map<String, dynamic>;
    final event = OrderEvent.fromWireJson(json['event'] as Map<String, dynamic>);
    if (event == null) {
      throw const FormatException(
        'order.updated event missing/unparseable in response',
      );
    }
    return event;
  }


  /// Exchanges the app's static webhook credentials for a merchant-scoped
  /// bearer token, used to authorize subsequent `/merchant/orders` calls.
  Future<WebhookTokenDto> fetchToken(String merchantId) async {
    final response = await _httpClient.post<dynamic>(
      '/auth/token',
      data: {
        'webhook_secret': _env.webhookSecret,
        'client_id': _env.clientId,
        'merchant_id': merchantId,
      },
    );
    return WebhookTokenDto.fromJson(jsonEncode(response.data));
  }
}
