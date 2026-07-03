import 'dart:typed_data';

import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/product.dart';

final catalogProductsProvider =
    AsyncNotifierProvider<CatalogProductsNotifier, CatalogProductsData>(
  CatalogProductsNotifier.new,
  name: 'catalogProductsProvider',
);

final catalogVariantNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchVariantNames();
});

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
  static final saveAction = Mutation<CatalogProduct>();
  static final deleteAction = Mutation<bool>();

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

  Future<CatalogProduct> save(
    CatalogProduct draft,
    List<CatalogProductVariant> variants, {
    Uint8List? imageBytes,
  }) async {
    final repo = ref.read(catalogRepositoryProvider);
    final categoryId = draft.category!.id;

    final String productId;
    if (draft.id.isEmpty) {
      productId = await repo.createProduct(
        name: draft.name,
        categoryId: categoryId,
        imageBytes: imageBytes,
      );
    } else {
      productId = draft.id;
      await repo.updateProduct(
        id: productId,
        name: draft.name,
        categoryId: categoryId,
        imageBytes: imageBytes,
      );
    }

    final existingIds = draft.id.isEmpty
        ? const <String>{}
        : (await repo.fetchProductVariants(productId)).map((v) => v.id).toSet();
    final incomingIds = variants.where((v) => v.id.isNotEmpty).map((v) => v.id).toSet();

    for (final variant in variants) {
      if (variant.id.isEmpty) {
        await repo.createVariant(
          productId: productId,
          name: variant.name,
          price: variant.price,
          isDefault: variant.isDefault,
        );
      } else {
        await repo.updateVariant(
          id: variant.id,
          name: variant.name,
          price: variant.price,
          isDefault: variant.isDefault,
        );
      }
    }

    for (final removedId in existingIds.difference(incomingIds)) {
      await repo.deleteVariant(removedId);
    }

    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);

    return draft.copyWith(id: productId);
  }

  Future<bool> delete(String id) async {
    await ref.read(catalogRepositoryProvider).deleteProduct(id);
    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);
    return true;
  }
}
