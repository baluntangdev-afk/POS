import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/file_sniffer.dart';
import '../api_clients.dart';
import '../schemas/create_product_group_dto.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/product_group_dto.dart';
import '../schemas/product_group_query_dto.dart';
import '../schemas/product_list_item_dto.dart';
import '../schemas/update_product_group_dto.dart';

final productGroupsApiProvider = Provider<ProductGroupsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductGroupsApi(httpClient);
});

class ProductGroupsApi {
  const ProductGroupsApi(this._httpClient);

  final Dio _httpClient;

  Future<ProductGroupDto> create(CreateProductGroupDto request, {Uint8List? image}) async {
    final formData = FormData.fromMap({
      ...request.toMap(),
      if (image != null)
        'image': MultipartFile.fromBytes(
          image,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${image.fileExtension}',
          contentType: DioMediaType.parse(image.mimeType),
        ),
    });

    final response = await _httpClient.post<dynamic>('/api/v1/product-groups', data: formData);

    final json = jsonEncode(response.data);
    return ProductGroupDtoMapper.fromJson(json);
  }

  Future<ProductGroupDto> update(int id, UpdateProductGroupDto request, {Uint8List? image}) async {
    final formData = FormData.fromMap({
      ...request.toMap(),
      if (image != null)
        'image': MultipartFile.fromBytes(
          image,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${image.fileExtension}',
          contentType: DioMediaType.parse(image.mimeType),
        ),
    });

    final response = await _httpClient.patch<dynamic>('/api/v1/product-groups/$id', data: formData);

    final json = jsonEncode(response.data);
    return ProductGroupDtoMapper.fromJson(json);
  }

  Future<bool> delete(int id) async {
    await _httpClient.delete<dynamic>('/api/v1/product-groups/$id');
    return true;
  }

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
    final response = await _httpClient.get<dynamic>('/api/v1/product-groups/$id/products');
    final json = jsonEncode(response.data);
    ProductListItemDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<ProductListItemDto>(json);
  }
}
