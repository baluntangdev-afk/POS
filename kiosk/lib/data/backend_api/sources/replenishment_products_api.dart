import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/replenishment_product_dto.dart';

final replenishmentProductsApiProvider = Provider<ReplenishmentProductsApi>((ref) {
  final httpClient = ref.watch(replenishmentApiClientProvider);
  return ReplenishmentProductsApi(httpClient);
});

class ReplenishmentProductsApi {
  const ReplenishmentProductsApi(this._httpClient);

  final Dio _httpClient;

  Future<List<ReplenishmentProductDto>> getProducts() async {
    final response = await _httpClient.get<dynamic>('/api/products');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => ReplenishmentProductDto.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
