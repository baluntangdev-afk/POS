import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/live_orders/entities/order_event.dart';
import '../api_clients.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return OrdersHistoryApi(httpClient);
});

/// Fetches the full stored event log for a merchant from the
/// webhook-receiver's REST history endpoint. This is what backfills the
/// app's local order history — the WS feed only carries events from the
/// moment it connects onward.
class OrdersHistoryApi {
  const OrdersHistoryApi(this._httpClient);

  final Dio _httpClient;

  Future<List<OrderEvent>> fetchEvents(String merchantId) async {
    final response = await _httpClient.get<dynamic>(
      '/webhooks/events',
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
}
