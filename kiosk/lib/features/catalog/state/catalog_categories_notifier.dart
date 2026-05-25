import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/category.dart';

final catalogCategoriesProvider =
    AsyncNotifierProvider<CatalogCategoriesNotifier, List<CatalogCategory>>(
  CatalogCategoriesNotifier.new,
  name: 'catalogCategoriesProvider',
);

class CatalogCategoriesNotifier extends AsyncNotifier<List<CatalogCategory>> {
  @override
  Future<List<CatalogCategory>> build() {
    return ref.watch(catalogRepositoryProvider).fetchCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).fetchCategories(),
    );
  }
}
