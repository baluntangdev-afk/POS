import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Pairs a global modifier group row with its options — used by the
/// Modifier Groups management tab.
class ModifierGroupWithOptions {
  final ModifierGroupsTableData group;
  final List<ModifierOptionsTableData> options;

  const ModifierGroupWithOptions({required this.group, required this.options});
}

/// All global modifier groups (active or not) with their options — the
/// management tab's read model.
final allModifierGroupsProvider = FutureProvider<List<ModifierGroupWithOptions>>((ref) async {
  final db = ref.watch(databaseProvider);
  final groups = await db.productsDao.getAllModifierGroups();
  final result = <ModifierGroupWithOptions>[];
  for (final group in groups) {
    final options = await db.productsDao.getOptionsForGroup(group.id);
    result.add(ModifierGroupWithOptions(group: group, options: options));
  }
  return result;
});

/// The modifier groups currently attached to one product — the per-product
/// attach/detach screen's read model.
final attachedModifierGroupsProvider =
    FutureProvider.family<List<ModifierGroupsTableData>, int>((ref, productId) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.getModifierGroupsForProduct(productId);
});

/// Mutations for the global groups/options themselves (create, edit,
/// soft-disable). Not scoped to any product.
class ModifierGroupsManagementActions {
  final Ref ref;
  const ModifierGroupsManagementActions(this.ref);

  void _refresh() => ref.invalidate(allModifierGroupsProvider);

  Future<void> createGroup({
    required String name,
    required bool isRequired,
    required int maxSelections,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.createModifierGroup(ModifierGroupsTableCompanion.insert(
      name: name,
      isRequired: Value(isRequired),
      maxSelections: Value(maxSelections),
    ));
    _refresh();
  }

  Future<void> updateGroup({
    required int groupId,
    required String name,
    required bool isRequired,
    required int maxSelections,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.updateModifierGroup(groupId, name: name, isRequired: isRequired, maxSelections: maxSelections);
    _refresh();
  }

  Future<void> toggleGroupActive(int groupId, {required bool isActive}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.toggleModifierGroupActive(groupId, isActive: isActive);
    _refresh();
  }

  Future<void> createOption({
    required int groupId,
    required String name,
    required double additionalPrice,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.insertModifierOption(ModifierOptionsTableCompanion.insert(
      groupId: groupId,
      name: name,
      additionalPrice: Value(additionalPrice),
    ));
    _refresh();
  }

  Future<void> updateOption({
    required int optionId,
    required String name,
    required double additionalPrice,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.updateModifierOption(optionId, name: name, additionalPrice: additionalPrice);
    _refresh();
  }

  Future<void> toggleOptionActive(int optionId, {required bool isActive}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.toggleModifierOptionActive(optionId, isActive: isActive);
    _refresh();
  }
}

final modifierGroupsManagementActionsProvider =
    Provider<ModifierGroupsManagementActions>((ref) => ModifierGroupsManagementActions(ref));

/// Attach/detach actions for one specific product's modifier-group set.
class ProductModifierGroupActions {
  final Ref ref;
  final int productId;
  const ProductModifierGroupActions(this.ref, this.productId);

  Future<void> attach(int modifierGroupId) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.attachModifierGroupToProduct(productId, modifierGroupId);
    ref.invalidate(attachedModifierGroupsProvider(productId));
  }

  Future<void> detach(int modifierGroupId) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.detachModifierGroupFromProduct(productId, modifierGroupId);
    ref.invalidate(attachedModifierGroupsProvider(productId));
  }
}

final productModifierGroupActionsProvider =
    Provider.family<ProductModifierGroupActions, int>(
        (ref, productId) => ProductModifierGroupActions(ref, productId));
