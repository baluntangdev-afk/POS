import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/products_api.dart';
import '../entities/product.dart';

abstract class DeleteProduct {
  Future<bool> call(Product product);
}

final deleteProductProvider = Provider<DeleteProduct>((ref) {
  return DeleteProductImpl(
    productsApi: ref.watch(productsApiProvider),
  );
});

class DeleteProductImpl implements DeleteProduct {
  const DeleteProductImpl({
    required ProductsApi productsApi,
  }) : _productsApi = productsApi;

  final ProductsApi _productsApi;

  @override
  Future<bool> call(Product product) async {
    return _productsApi.delete(product.id);
  }
}
