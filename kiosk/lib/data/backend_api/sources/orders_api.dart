import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) {
  final httpClient = ref.watch(cartivoApiClientProvider);
  return OrdersApi(httpClient);
});

/// Talks to the webhook-receiver's order mutation endpoints. Callers don't
/// need the response body — the resulting `order.updated`/`order.cancelled`
/// event arrives over the live WS feed (see `OrdersFeedNotifier`) and that's
/// what actually drives the kanban board, so these just need to succeed.
class OrdersApi {
  const OrdersApi(this._httpClient);

  final Dio _httpClient;

  Future<void> updateStatus(String orderId, String status) async {
    await _httpClient.patch<dynamic>('/api/orders/$orderId/status', data: {'status': status});
  }

  Future<void> cancel(String orderId) async {
    await _httpClient.post<dynamic>('/api/orders/$orderId/cancel');
  }
}
