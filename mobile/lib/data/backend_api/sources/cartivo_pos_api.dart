import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/cartivo_order_status_request.dart';

final cartivoPosApiProvider = Provider<CartivoPosApi>((ref) {
  return CartivoPosApi(ref.watch(cartivoPosApiClientProvider));
});

class CartivoPosApi with ApiCall {
  const CartivoPosApi(this._httpClient);

  final Dio _httpClient;

  /// `GET /pos/orders/{order_number}`.
  Future<Map<String, dynamic>> fetchOrder(String orderNumber) => guard(() async {
    final response = await _httpClient.get<dynamic>(
      '/cartivo/pos/orders/${Uri.encodeComponent(orderNumber)}',
    );
    return _asMap(response.data);
  });

  /// `GET /pos/merchants/{merchant_id}/products`. Only `page`, `limit` and
  /// `updated_since` are forwarded by the backend.
  Future<Map<String, dynamic>> fetchMerchantProducts(
    String merchantId, {
    int? page,
    int? limit,
    DateTime? updatedSince,
  }) => guard(() async {
    final response = await _httpClient.get<dynamic>(
      '/cartivo/pos/merchants/${Uri.encodeComponent(merchantId)}/products',
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (updatedSince != null) 'updated_since': updatedSince.toUtc().toIso8601String(),
      },
    );
    return _asMap(response.data);
  });

  /// `POST /pos/orders/{order_number}/status`. Returns Cartivo's body as-is.
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderNumber,
    CartivoOrderStatusRequest request,
  ) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/cartivo/pos/orders/${Uri.encodeComponent(orderNumber)}/status',
      data: {
        'event_id': request.eventId,
        'status': request.status,
        'occurred_at': request.occurredAt.toUtc().toIso8601String(),
        if (request.reason != null) 'reason': request.reason,
      },
    );
    return _asMap(response.data);
  });

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data == null || (data is String && data.isEmpty)) return const {};
    throw const FormatException('Expected a JSON object in the response');
  }
}
