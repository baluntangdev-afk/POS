import 'dart:typed_data';

import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/inventory_repository.dart';
import '../data/models/import_products_csv_result.dart';
import '../data/models/product.dart';

final inventoryProductsProvider =
    AsyncNotifierProvider<InventoryProductsNotifier, InventoryProductsData>(
  InventoryProductsNotifier.new,
  name: 'inventoryProductsProvider',
);

final inventoryVariantNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(inventoryRepositoryProvider).fetchVariantNames();
});

class InventoryProductsData {
  const InventoryProductsData({
    required this.products,
    this.categoryId,
    this.search,
  });

  final List<InventoryProduct> products;
  final String? categoryId;
  final String? search;
}

class InventoryProductsNotifier extends AsyncNotifier<InventoryProductsData> {
  static final saveAction = Mutation<InventoryProduct>();
  static final toggleAvailabilityAction = Mutation<void>();
  static final importCsvAction = Mutation<ImportProductsCsvResult>();

  @override
  Future<InventoryProductsData> build() async {
    final products = await ref.watch(inventoryRepositoryProvider).fetchAllProductsAdmin();
    return InventoryProductsData(products: products);
  }

  Future<void> getResults({String? categoryId, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final products = await ref.read(inventoryRepositoryProvider).fetchAllProductsAdmin(
            categoryId: categoryId,
            search: search,
          );
      return InventoryProductsData(
        products: products,
        categoryId: categoryId,
        search: search,
      );
    });
  }

  Future<InventoryProduct> save(
    InventoryProduct draft,
    List<InventoryProductVariant> variants, {
    Uint8List? imageBytes,
  }) async {
    final repo = ref.read(inventoryRepositoryProvider);
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

    final existingVariants = draft.id.isEmpty
        ? const <InventoryProductVariant>[]
        : await repo.fetchProductVariants(productId);
    final existingIds = existingVariants.map((v) => v.id).toSet();
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
          isActive: variant.isActive,
        );
      }
    }

    for (final removedId in existingIds.difference(incomingIds)) {
      final removed = existingVariants.firstWhere((v) => v.id == removedId);
      await repo.updateVariant(
        id: removed.id,
        name: removed.name,
        price: removed.price,
        isDefault: false,
        isActive: false,
      );
    }

    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);

    return draft.copyWith(id: productId);
  }

  Future<ImportProductsCsvResult> importCsv({
    required Uint8List fileBytes,
    required String fileName,
    required String mode,
  }) async {
    final result = await ref.read(inventoryRepositoryProvider).importProductsCsv(
          fileBytes: fileBytes,
          fileName: fileName,
          mode: mode,
        );
    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);
    return result;
  }

  Future<void> toggleAvailability(InventoryProduct product) async {
    await ref.read(inventoryRepositoryProvider).updateProductAvailability(
          product.id,
          isAvailable: !product.isAvailable,
        );
    final current = state.value;
    await getResults(categoryId: current?.categoryId, search: current?.search);
  }
}
