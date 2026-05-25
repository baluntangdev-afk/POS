import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/models/modifier_group.dart';

final catalogModifierGroupsProvider =
    AsyncNotifierProvider<CatalogModifierGroupsNotifier, List<CatalogModifierGroup>>(
  CatalogModifierGroupsNotifier.new,
  name: 'catalogModifierGroupsProvider',
);

class CatalogModifierGroupsNotifier
    extends AsyncNotifier<List<CatalogModifierGroup>> {
  @override
  Future<List<CatalogModifierGroup>> build() {
    return ref.watch(catalogRepositoryProvider).fetchModifierGroups();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).fetchModifierGroups(),
    );
  }
}
