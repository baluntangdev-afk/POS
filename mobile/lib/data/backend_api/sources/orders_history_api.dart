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
