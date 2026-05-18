import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/product_dto.dart';
import '../../../data/backend_api/schemas/product_query_dto.dart';
import '../../../data/backend_api/sources/products_api.dart';
import '../../../utils/paginated_data.dart';
import '../entities/product.dart';

abstract class GetProducts {
  Future<PaginatedData<Product>> call({
    required int page,
    required int limit,
    String? name,
    String? description,
    String? sort,
  });
}

final getProductsProvider = Provider<GetProducts>((ref) {
  return GetProductsImpl(
    productsApi: ref.watch(productsApiProvider),
  );
});

class GetProductsImpl implements GetProducts {
  const GetProductsImpl({
    required ProductsApi productsApi,
  }) : _productsApi = productsApi;

  final ProductsApi _productsApi;

  @override
  Future<PaginatedData<Product>> call({
    required int page,
    required int limit,
    String? name,
    String? description,
    String? sort,
  }) async {
    final query = ProductQueryDto(
      page: page,
      limit: limit,
      name: name,
      description: description,
      sort: sort,
    );
    final response = await _productsApi.getAll(query);
    return PaginatedData(
      page: response.page,
      limit: response.limit,
      total: response.total,
      data: response.data.map(_productFromProductDto).toIList(),
    );
  }

  Product _productFromProductDto(ProductDto dto) {
    return Product(
      id: dto.id,
      name: dto.name,
      description: dto.description ?? '',
      image: dto.imageUrl ?? Uint8List(0),
    );
  }
}
