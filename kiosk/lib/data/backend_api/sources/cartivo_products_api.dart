import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/cartivo_product_dto.dart';

final cartivoProductsApiProvider = Provider<CartivoProductsApi>((ref) {
  final httpClient = ref.watch(cartivoAuthenticatedApiClientProvider);
  return CartivoProductsApi(httpClient);
});

class CartivoProductsApi {
  const CartivoProductsApi(this._httpClient);

  final Dio _httpClient;

  Future<List<CartivoProductDto>> getProducts() async {
    final response = await _httpClient.get<dynamic>('/api/products');
    final list = response.data as List<dynamic>;
    return list.map((item) => CartivoProductDto.fromMap(item as Map<String, dynamic>)).toList();
  }
}
