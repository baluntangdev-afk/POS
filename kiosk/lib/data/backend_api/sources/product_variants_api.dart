import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/file_sniffer.dart';
import '../api_clients.dart';
import '../schemas/create_product_variant_dto.dart';
import '../schemas/product_dto.dart';
import '../schemas/product_variant_dto.dart';
import '../schemas/update_product_dto.dart';

final productVariantsApiProvider = Provider<ProductVariantsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ProductVariantsApi(httpClient);
});

class ProductVariantsApi {
  const ProductVariantsApi(this._httpClient);

  final Dio _httpClient;

  Future<ProductVariantDto> create(CreateProductVariantDto request) async {
    final response = await _httpClient.post<dynamic>('/api/v1/products', data: request.toJson());
    final json = jsonEncode(response.data);
    return ProductVariantDtoMapper.fromJson(json);
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

    final response = await _httpClient.patch<dynamic>(
      '/api/v1/product-variants/$id',
      data: formData,
    );

    final json = jsonEncode(response.data);
    return ProductDtoMapper.fromJson(json);
  }

  Future<bool> delete(int id) async {
    await _httpClient.delete<dynamic>('/api/v1/product-variants/$id');
    return true;
  }

  Future<ProductVariantDto> getById(int id) async {
    final response = await _httpClient.get<dynamic>('/api/v1/product-variants/$id');
    final json = jsonEncode(response.data);
    return ProductVariantDto.fromJson(json);
  }

  Future<List<ProductVariantDto>> getByProductId(int productId) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/product-variants/by-product/$productId',
    );
    final data = response.data as List<dynamic>;
    return data.map((e) => ProductVariantDto.fromJson(jsonEncode(e))).toList();
  }
}
