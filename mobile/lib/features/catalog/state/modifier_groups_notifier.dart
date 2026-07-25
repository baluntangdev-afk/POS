import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Pairs a modifier group row with its options — a per-product read model,
/// since mobile's modifier groups are 1:1-owned by a single product (unlike
/// kiosk's reusable-across-products model; see Phase 3 Design Decision #2).
class ModifierGroupWithOptions {
  final ModifierGroupsTableData group;
  final List<ModifierOptionsTableData> options;

  const ModifierGroupWithOptions({required this.group, required this.options});
}

/// Reads all modifier groups (with their options) for a single product.
///
/// A mutable family-scoped `AsyncNotifier` isn't cleanly available for
/// Riverpod 3.3.2 in this codebase (no precedent for it — the existing
/// family-scoped providers, `_historyReceiptProvider`/`_refundableItemsProvider`
/// in `features/transactions/`, are plain `FutureProvider.family` paired with
/// `ref.invalidate(...)` after mutations). This follows that same precedent
/// rather than fighting the framework.
final modifierGroupsProvider =
    FutureProvider.family<List<ModifierGroupWithOptions>, int>((ref, productId) async {
  final db = ref.watch(databaseProvider);
  final groups = await db.productsDao.getModifierGroupsForProduct(productId);
  final result = <ModifierGroupWithOptions>[];
  for (final group in groups) {
    final options = await db.productsDao.getOptionsForGroup(group.id);
    result.add(ModifierGroupWithOptions(group: group, options: options));
  }
  return result;
});

/// Mutation methods for a single product's modifier groups/options. Each
/// mutation invalidates [modifierGroupsProvider] for the same [productId] so
/// any watchers refresh automatically.
class ModifierGroupsActions {
  final Ref ref;
  final int productId;

  const ModifierGroupsActions(this.ref, this.productId);

  void _refresh() => ref.invalidate(modifierGroupsProvider(productId));

  Future<void> createGroup({
    required String name,
    required bool isRequired,
    required int maxSelections,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.insertModifierGroup(ModifierGroupsTableCompanion.insert(
      productId: productId,
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
    await db.productsDao.updateModifierGroup(
      groupId,
      name: name,
      isRequired: isRequired,
      maxSelections: maxSelections,
    );
    _refresh();
  }

  Future<void> deleteGroup(int groupId) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.deleteModifierGroup(groupId);
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
    await db.productsDao.updateModifierOption(
      optionId,
      name: name,
      additionalPrice: additionalPrice,
    );
    _refresh();
  }

  Future<void> deleteOption(int optionId) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.deleteModifierOption(optionId);
    _refresh();
  }
}

final modifierGroupsActionsProvider =
    Provider.family<ModifierGroupsActions, int>((ref, productId) {
  return ModifierGroupsActions(ref, productId);
});
