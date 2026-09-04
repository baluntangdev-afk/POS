import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/live_orders/entities/order_event.dart';
import '../api_clients.dart';
import '../errors/api_call.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return OrdersHistoryApi(httpClient);
});

class OrdersHistoryApi with ApiCall {
  const OrdersHistoryApi(this._httpClient);

  final Dio _httpClient;

  /// `GET /merchant/orders` — the full per-event order log for [merchantId].
  /// Throws an `ApiException` on any failure.
  Future<List<OrderEvent>> fetchEvents(String merchantId) => guard(() async {
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
  });

  /// `PATCH /merchant/orders/{orderId}` — applies [updates] and returns the
  /// resulting `order.updated` event. Throws an `ApiException` on any failure.
  Future<OrderEvent> updateOrder(
    String orderId, {
    required Map<String, dynamic> updates,
  }) => guard(() async {
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
  });
}
