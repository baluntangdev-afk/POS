import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/api_clients.dart';
import '../../../utils/file_sniffer.dart';
import 'models/category.dart';
import 'models/import_products_csv_result.dart';
import 'models/modifier_group.dart';
import 'models/product.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final openClient = ref.watch(openApiClientProvider);
  final secureClient = ref.watch(secureApiClientProvider);
  return InventoryRepository(openClient, secureClient);
});

class InventoryRepository {
  const InventoryRepository(this._openClient, this._secureClient);

  final Dio _openClient;
  final Dio _secureClient;

  Future<List<InventoryCategory>> fetchCategories() async {
    final response = await _openClient.get<dynamic>('/api/v1/catalog/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => InventoryCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryCategory>> fetchAllCategoriesAdmin() async {
    final response = await _secureClient.get<dynamic>('/api/v1/catalog/admin/categories');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => InventoryCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryCategory> createCategory(
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
    return InventoryCategory.fromJson(data);
  }

  Future<InventoryCategory> updateCategory(
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
    return InventoryCategory.fromJson(data);
  }

  Future<List<InventoryProduct>> fetchProducts({String? categoryId, String? search}) async {
    final response = await _openClient.get<dynamic>(
      '/api/v1/catalog/products',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'search': search,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => InventoryProduct.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryProduct>> fetchAllProductsAdmin({String? categoryId, String? search}) async {
    final response = await _secureClient.get<dynamic>(
      '/api/v1/catalog/admin/products',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'search': search,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => InventoryProduct.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryModifierGroup>> fetchModifierGroups() async {
    final response = await _openClient.get<dynamic>('/api/v1/catalog/modifier-groups');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => InventoryModifierGroup.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> createProduct({
    required String name,
    required String categoryId,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'groupId': categoryId,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${imageBytes.fileExtension}',
          contentType: DioMediaType.parse(imageBytes.mimeType),
        ),
    });
    final response = await _secureClient.post<dynamic>('/api/v1/products', data: formData);
    final data = response.data as Map<String, dynamic>;
    return data['id'].toString();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    Uint8List? imageBytes,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'groupId': categoryId,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${imageBytes.fileExtension}',
          contentType: DioMediaType.parse(imageBytes.mimeType),
        ),
    });
    await _secureClient.patch<dynamic>('/api/v1/products/$id', data: formData);
  }

  Future<void> updateProductAvailability(String id, {required bool isAvailable}) async {
    await _secureClient.patch<dynamic>(
      '/api/v1/products/$id',
      data: {'isAvailable': isAvailable},
    );
  }

  Future<List<InventoryProductVariant>> fetchProductVariants(String productId) async {
    final response = await _secureClient.get<dynamic>('/api/v1/products/$productId');
    final data = response.data as Map<String, dynamic>;
    final variantsJson = data['variants'] as List<dynamic>? ?? [];
    return variantsJson
        .map((v) => InventoryProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryProductVariant> createVariant({
    required String productId,
    required String name,
    required double price,
    required bool isDefault,
  }) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/product-variants',
      data: {
        'productId': int.parse(productId),
        'name': name,
        'price': price,
        'isDefault': isDefault,
      },
    );
    return InventoryProductVariant.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateVariant({
    required String id,
    required String name,
    required double price,
    required bool isDefault,
    required bool isActive,
  }) async {
    await _secureClient.patch<dynamic>(
      '/api/v1/product-variants/$id',
      data: {'name': name, 'price': price, 'isDefault': isDefault, 'isActive': isActive},
    );
  }

  Future<List<String>> fetchVariantNames() async {
    final response = await _secureClient.get<dynamic>('/api/v1/product-variants/names');
    return (response.data as List<dynamic>).map((e) => e.toString()).toList();
  }

  Future<ImportProductsCsvResult> importProductsCsv({
    required Uint8List fileBytes,
    required String fileName,
    required String mode,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'mode': mode,
    });
    final response = await _secureClient.post<dynamic>(
      '/api/v1/products/import-csv',
      data: formData,
    );
    return ImportProductsCsvResult.fromJson(response.data as Map<String, dynamic>);
  }
}
