import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/api_clients.dart';
import 'models/category.dart';
import 'models/modifier_group.dart';
import 'models/product.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final openClient = ref.watch(openApiClientProvider);
  final secureClient = ref.watch(secureApiClientProvider);
  return CatalogRepository(openClient, secureClient);
});

class CatalogRepository {
  const CatalogRepository(this._openClient, this._secureClient);

  final Dio _openClient;
  final Dio _secureClient;

  Future<List<CatalogCategory>> fetchCategories() async {
    final response = await _openClient.get<dynamic>('/api/v1/catalog/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogCategory>> fetchAllCategoriesAdmin() async {
    final response = await _secureClient.get<dynamic>('/api/v1/catalog/admin/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CatalogCategory> createCategory(
    String name,
    String? description,
    bool isActive,
  ) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/catalog/admin/categories',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'isActive': isActive,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CatalogCategory.fromJson(data);
  }

  Future<CatalogCategory> updateCategory(
    String id,
    String name,
    String? description,
    bool isActive,
  ) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/catalog/admin/categories/$id',
      data: {
        'name': name,
        'description': description,
        'isActive': isActive,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CatalogCategory.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _secureClient.delete<dynamic>('/api/v1/catalog/admin/categories/$id');
  }

  Future<List<CatalogProduct>> fetchProducts({String? categoryId, String? search}) async {
    final response = await _openClient.get<dynamic>(
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
    final response = await _openClient.get<dynamic>('/api/v1/catalog/modifier-groups');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => CatalogModifierGroup.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
