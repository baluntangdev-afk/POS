import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/inventory_repository.dart';
import '../data/models/modifier_group.dart';

final inventoryModifierGroupsProvider =
    AsyncNotifierProvider<InventoryModifierGroupsNotifier, List<InventoryModifierGroup>>(
  InventoryModifierGroupsNotifier.new,
  name: 'inventoryModifierGroupsProvider',
);

class InventoryModifierGroupsNotifier
    extends AsyncNotifier<List<InventoryModifierGroup>> {
  @override
  Future<List<InventoryModifierGroup>> build() {
    return ref.watch(inventoryRepositoryProvider).fetchModifierGroups();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryRepositoryProvider).fetchModifierGroups(),
    );
  }
}
