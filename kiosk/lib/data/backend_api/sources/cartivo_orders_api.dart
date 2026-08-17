import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/cartivo_order_dto.dart';

final cartivoOrdersApiProvider = Provider<CartivoOrdersApi>((ref) {
  final httpClient = ref.watch(cartivoAuthenticatedApiClientProvider);
  return CartivoOrdersApi(httpClient);
});

class CartivoOrdersApi {
  const CartivoOrdersApi(this._httpClient);

  final Dio _httpClient;

  Future<CartivoOrderDto> createOrder({
    required List<({String productId, int quantity})> items,
  }) async {
    final response = await _httpClient.post<dynamic>(
      '/api/orders',
      data: {
        'items': items
            .map((item) => {'product_id': item.productId, 'quantity': item.quantity})
            .toList(),
      },
    );
    return CartivoOrderDto.fromMap(response.data as Map<String, dynamic>);
  }

  Future<List<CartivoOrderDto>> getOrders() async {
    final response = await _httpClient.get<dynamic>('/api/orders');
    final list = response.data as List<dynamic>;
    return list.map((item) => CartivoOrderDto.fromMap(item as Map<String, dynamic>)).toList();
  }
}
