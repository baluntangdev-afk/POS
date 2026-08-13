import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/replenishment_order_dto.dart';
import '../schemas/replenishment_pay_order_response_dto.dart';

final replenishmentOrdersApiProvider = Provider<ReplenishmentOrdersApi>((ref) {
  final httpClient = ref.watch(replenishmentApiClientProvider);
  return ReplenishmentOrdersApi(httpClient);
});

class ReplenishmentOrdersApi {
  const ReplenishmentOrdersApi(this._httpClient);

  final Dio _httpClient;

  Future<ReplenishmentOrderDto> createOrder({
    required String customerId,
    required List<({String productId, int quantity})> items,
  }) async {
    final response = await _httpClient.post<dynamic>(
      '/api/orders',
      data: {
        'customer_id': customerId,
        'items': items
            .map((item) => {'product_id': item.productId, 'quantity': item.quantity})
            .toList(),
      },
    );
    return ReplenishmentOrderDto.fromMap(response.data as Map<String, dynamic>);
  }

  Future<List<ReplenishmentOrderDto>> getOrders({required String customerId}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/orders',
      queryParameters: {'customer_id': customerId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((item) => ReplenishmentOrderDto.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReplenishmentPayOrderResponseDto> payOrder(String orderId) async {
    final response = await _httpClient.post<dynamic>('/api/orders/$orderId/pay');
    return ReplenishmentPayOrderResponseDto.fromMap(response.data as Map<String, dynamic>);
  }
}
