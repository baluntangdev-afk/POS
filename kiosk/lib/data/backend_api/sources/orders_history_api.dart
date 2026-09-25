import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/orders/entities/order_event.dart';
import '../api_clients.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return OrdersHistoryApi(httpClient);
});

class OrdersHistoryApi {
  const OrdersHistoryApi(this._httpClient);

  final Dio _httpClient;

  /// Throws [DioException] on failure — callers own the retry/silence
  /// decision, so this must not swallow errors into an empty list (that
  /// makes a broken connection indistinguishable from "no orders yet").
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
}
