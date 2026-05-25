import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/file_sniffer.dart';
import '../api_clients.dart';
import '../schemas/create_product_dto.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/product_details_dto.dart';
import '../schemas/product_dto.dart';
import '../schemas/product_query_dto.dart';
import '../schemas/update_product_dto.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductsApi(httpClient);
});

class ProductsApi {
  const ProductsApi(this._httpClient);

  final Dio _httpClient;

  Future<ProductDto> create(CreateProductDto request, {Uint8List? image}) async {
    final formData = FormData.fromMap({
      ...request.toMap(),
      if (image != null)
        'image': MultipartFile.fromBytes(
          image,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${image.fileExtension}',
          contentType: DioMediaType.parse(image.mimeType),
        ),
    });

    final response = await _httpClient.post<dynamic>('/api/v1/products', data: formData);

    final json = jsonEncode(response.data);
    return ProductDtoMapper.fromJson(json);
  }

  Future<ProductDto> update(int id, UpdateProductDto request, {Uint8List? image}) async {
    final formData = FormData.fromMap({
      ...request.toMap(),
      if (image != null)
        'image': MultipartFile.fromBytes(
          image,
          filename: '${DateTime.now().millisecondsSinceEpoch}.${image.fileExtension}',
          contentType: DioMediaType.parse(image.mimeType),
        ),
    });

    final response = await _httpClient.patch<dynamic>('/api/v1/products/$id', data: formData);

    final json = jsonEncode(response.data);
    return ProductDtoMapper.fromJson(json);
  }

  Future<bool> delete(int id) async {
    await _httpClient.delete<dynamic>('/api/v1/products/$id');
    return true;
  }

  Future<PaginatedResponseDto<ProductDto>> getAll(ProductQueryDto query) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/products',
      queryParameters: query.toMap(),
    );
    // Pass raw response data to the isolate so jsonEncode + base64Decode
    // both happen off the main thread.
    return compute(_parseProductsData, response.data);
  }

  Future<ProductDetailsDto> getById(int id) async {
    final response = await _httpClient.get<dynamic>('/api/v1/products/$id');
    final json = jsonEncode(response.data);
    return ProductDetailsDto.fromJson(json);
  }
}

PaginatedResponseDto<ProductDto> _parseProductsData(dynamic data) {
  ProductDtoMapper.ensureInitialized();
  final json = jsonEncode(data);
  return PaginatedResponseDtoMapper.fromJson<ProductDto>(json);
}
