import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/create_product_dto.dart';
import '../../../data/backend_api/schemas/product_dto.dart';
import '../../../data/backend_api/schemas/update_product_dto.dart';
import '../../../data/backend_api/sources/products_api.dart';
import '../entities/product.dart';

abstract class SaveProduct {
  Future<Product> call(Product product);
}

final saveProductProvider = Provider<SaveProduct>((ref) {
  return SaveProductImpl(productsApi: ref.watch(productsApiProvider));
});

class SaveProductImpl implements SaveProduct {
  const SaveProductImpl({required ProductsApi productsApi}) : _productsApi = productsApi;

  final ProductsApi _productsApi;

  @override
  Future<Product> call(Product product) async {
    ProductDto response;

    if (product.id != Product.draft().id) {
      final request = _updateProductDtoFromProduct(product);
      response = await _productsApi.update(product.id, request, image: product.image);
    } else {
      final request = _createProductDtoFromProduct(product);
      response = await _productsApi.create(request, image: product.image);
    }

    return product.copyWith(id: response.id);
  }

  CreateProductDto _createProductDtoFromProduct(Product product) {
    return CreateProductDto(name: product.name, description: product.description, groupId: 1);
  }

  UpdateProductDto _updateProductDtoFromProduct(Product product) {
    return UpdateProductDto(name: product.name, description: product.description, groupId: 1);
  }
}
