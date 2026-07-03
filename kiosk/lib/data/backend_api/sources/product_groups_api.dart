import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/product_group_dto.dart';
import '../schemas/product_group_query_dto.dart';
import '../schemas/product_list_item_dto.dart';

final productGroupsApiProvider = Provider<ProductGroupsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductGroupsApi(httpClient);
});

class ProductGroupsApi {
  const ProductGroupsApi(this._httpClient);

  final Dio _httpClient;

  Future<PaginatedResponseDto<ProductGroupDto>> getAll(ProductGroupQueryDto query) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/product-groups',
      queryParameters: query.toMap(),
    );
    final json = jsonEncode(response.data);
    ProductGroupDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<ProductGroupDto>(json);
  }

  Future<PaginatedResponseDto<ProductListItemDto>> getProductsByGroup(int id) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/product-groups/$id/products',
      queryParameters: {'limit': 100},
    );
    final json = jsonEncode(response.data);
    ProductListItemDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<ProductListItemDto>(json);
  }
}
