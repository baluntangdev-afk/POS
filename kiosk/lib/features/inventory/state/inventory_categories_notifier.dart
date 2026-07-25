import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/inventory_repository.dart';
import '../data/models/category.dart';

final inventoryCategoriesProvider =
    AsyncNotifierProvider<InventoryCategoriesNotifier, List<InventoryCategory>>(
  InventoryCategoriesNotifier.new,
  name: 'inventoryCategoriesProvider',
);

class InventoryCategoriesNotifier extends AsyncNotifier<List<InventoryCategory>> {
  static final saveAction = Mutation<InventoryCategory>();
  static final toggleActiveAction = Mutation<InventoryCategory>();

  @override
  Future<List<InventoryCategory>> build() {
    return ref.watch(inventoryRepositoryProvider).fetchAllCategoriesAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).fetchAllCategoriesAdmin(),
    );
  }

  Future<InventoryCategory> save(InventoryCategory category) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final InventoryCategory result;

    if (category.id.isEmpty) {
      result = await repo.createCategory(
        category.name,
        category.description,
        category.isActive,
      );
    } else {
      result = await repo.updateCategory(
        category.id,
        category.name,
        category.description,
        category.isActive,
      );
    }

    await refresh();
    return result;
  }

  Future<InventoryCategory> toggleActive(InventoryCategory category) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final result = await repo.updateCategory(
      category.id,
      category.name,
      category.description,
      !category.isActive,
    );
    await refresh();
    return result;
  }
}
