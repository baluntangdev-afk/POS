import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/product_details_dto.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductsApi(httpClient);
});

class ProductsApi {
  const ProductsApi(this._httpClient);

  final Dio _httpClient;

  Future<ProductDetailsDto> getById(int id) async {
    final response = await _httpClient.get<dynamic>('/api/v1/products/$id');
    final json = jsonEncode(response.data);
    return ProductDetailsDto.fromJson(json);
  }
}
