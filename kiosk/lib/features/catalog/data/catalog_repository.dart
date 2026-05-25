import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/api_clients.dart';
import 'models/category.dart';
import 'models/modifier_group.dart';
import 'models/product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final httpClient = ref.watch(openApiClientProvider);
  return CatalogRepository(httpClient);
});

class CatalogRepository {
  const CatalogRepository(this._httpClient);

  final Dio _httpClient;

  Future<List<CatalogCategory>> fetchCategories() async {
    final response = await _httpClient.get<dynamic>('/api/v1/catalog/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogProduct>> fetchProducts({String? categoryId, String? search}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/catalog/products',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'search': search,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogProduct.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogModifierGroup>> fetchModifierGroups() async {
    final response = await _httpClient.get<dynamic>('/api/v1/catalog/modifier-groups');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogModifierGroup.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
