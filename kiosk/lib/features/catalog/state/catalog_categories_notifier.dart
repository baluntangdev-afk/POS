import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/category.dart';

final catalogCategoriesProvider =
    AsyncNotifierProvider<CatalogCategoriesNotifier, List<CatalogCategory>>(
  CatalogCategoriesNotifier.new,
  name: 'catalogCategoriesProvider',
);

class CatalogCategoriesNotifier extends AsyncNotifier<List<CatalogCategory>> {
  static final saveAction = Mutation<CatalogCategory>();
  static final deleteAction = Mutation<bool>();

  @override
  Future<List<CatalogCategory>> build() {
    return ref.watch(catalogRepositoryProvider).fetchAllCategoriesAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).fetchAllCategoriesAdmin(),
    );
  }

  Future<CatalogCategory> save(CatalogCategory category) async {
    final repo = ref.read(catalogRepositoryProvider);
    final CatalogCategory result;

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

  Future<bool> delete(String id) async {
    await ref.read(catalogRepositoryProvider).deleteCategory(id);
    await refresh();
    return true;
  }
}
