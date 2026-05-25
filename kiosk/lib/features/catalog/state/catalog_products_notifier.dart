import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/product.dart';

final catalogProductsProvider =
    AsyncNotifierProvider<CatalogProductsNotifier, CatalogProductsData>(
  CatalogProductsNotifier.new,
  name: 'catalogProductsProvider',
);

class CatalogProductsData {
  const CatalogProductsData({
    required this.products,
    this.categoryId,
    this.search,
  });

  final List<CatalogProduct> products;
  final String? categoryId;
  final String? search;
}

class CatalogProductsNotifier extends AsyncNotifier<CatalogProductsData> {
  @override
  Future<CatalogProductsData> build() async {
    final products = await ref.watch(catalogRepositoryProvider).fetchProducts();
    return CatalogProductsData(products: products);
  }

  Future<void> getResults({String? categoryId, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final products = await ref.read(catalogRepositoryProvider).fetchProducts(
            categoryId: categoryId,
            search: search,
          );
      return CatalogProductsData(
        products: products,
        categoryId: categoryId,
        search: search,
      );
    });
  }
}
