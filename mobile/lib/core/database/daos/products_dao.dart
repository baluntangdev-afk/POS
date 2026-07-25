import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_groups_table.dart';
import '../tables/products_table.dart';
import '../tables/modifier_groups_table.dart';
import '../tables/modifier_options_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [
  ProductGroupsTable,
  ProductsTable,
  ModifierGroupsTable,
  ModifierOptionsTable,
])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<ProductGroupsTableData>> getAllActiveGroups() =>
      (select(productGroupsTable)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Returns every category, active or not — used by the category
  /// management sheet so inactive categories can still be edited/reactivated.
  Future<List<ProductGroupsTableData>> getAllGroups() =>
      (select(productGroupsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ProductsTableData>> getProductsByGroup(int groupId) =>
      (select(productsTable)
            ..where((t) => t.groupId.equals(groupId))
            ..where((t) => t.isAvailable.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ProductsTableData>> getAllProducts() =>
      (select(productsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<ProductsTableData?> getProductById(int id) =>
      (select(productsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ModifierGroupsTableData>> getModifierGroupsForProduct(int productId) =>
      (select(modifierGroupsTable)
            ..where((t) => t.productId.equals(productId)))
          .get();

  Future<List<ModifierOptionsTableData>> getOptionsForGroup(int groupId) =>
      (select(modifierOptionsTable)
            ..where((t) => t.groupId.equals(groupId)))
          .get();

  Future<int> insertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insert(companion);

  Future<int> insertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insert(companion);

  Future<int> insertModifierGroup(ModifierGroupsTableCompanion companion) =>
      into(modifierGroupsTable).insert(companion);

  Future<int> insertModifierOption(ModifierOptionsTableCompanion companion) =>
      into(modifierOptionsTable).insert(companion);

  Future<int> upsertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insertOnConflictUpdate(companion);

  Future<int> upsertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insertOnConflictUpdate(companion);

  Future<int> toggleProductAvailability(int productId, {required bool isAvailable}) =>
      (update(productsTable)..where((t) => t.id.equals(productId)))
          .write(ProductsTableCompanion(isAvailable: Value(isAvailable)));

  Future<int> deleteModifierOption(int optionId) =>
      (delete(modifierOptionsTable)..where((t) => t.id.equals(optionId))).go();

  Future<int> deleteModifierGroup(int modifierGroupId) async {
    return transaction(() async {
      await (delete(modifierOptionsTable)..where((t) => t.groupId.equals(modifierGroupId))).go();
      return (delete(modifierGroupsTable)..where((t) => t.id.equals(modifierGroupId))).go();
    });
  }

  Future<int> deleteProduct(int productId) async {
    return transaction(() async {
      final groups = await (select(modifierGroupsTable)
            ..where((t) => t.productId.equals(productId)))
          .get();
      for (final group in groups) {
        await (delete(modifierOptionsTable)..where((t) => t.groupId.equals(group.id))).go();
      }
      await (delete(modifierGroupsTable)..where((t) => t.productId.equals(productId))).go();
      return (delete(productsTable)..where((t) => t.id.equals(productId))).go();
    });
  }

  Future<int> deleteProductGroup(int groupId) async {
    final productsInGroup =
        await (select(productsTable)..where((t) => t.groupId.equals(groupId))).get();
    if (productsInGroup.isNotEmpty) {
      throw StateError('Cannot delete a category that still has products');
    }
    return (delete(productGroupsTable)..where((t) => t.id.equals(groupId))).go();
  }

  Future<ProductGroupsTableData?> getGroupById(int id) =>
      (select(productGroupsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ModifierGroupsTableData?> getModifierGroupById(int id) =>
      (select(modifierGroupsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> isProductNameTaken(int groupId, String name, {int? excludeId}) async {
    final query = select(productsTable)
      ..where((t) => t.groupId.equals(groupId))
      ..where((t) => t.name.lower().equals(name.toLowerCase()));
    if (excludeId != null) {
      query.where((t) => t.id.equals(excludeId).not());
    }
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  Future<int> updateProductGroup(int id, {required String name, required bool isActive, int? sortOrder}) =>
      (update(productGroupsTable)..where((t) => t.id.equals(id))).write(
        ProductGroupsTableCompanion(
          name: Value(name),
          isActive: Value(isActive),
          sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        ),
      );

  Future<int> updateModifierGroup(int id, {required String name, required bool isRequired, required int maxSelections}) =>
      (update(modifierGroupsTable)..where((t) => t.id.equals(id))).write(
        ModifierGroupsTableCompanion(
          name: Value(name),
          isRequired: Value(isRequired),
          maxSelections: Value(maxSelections),
        ),
      );

  Future<int> updateModifierOption(int id, {required String name, required double additionalPrice}) =>
      (update(modifierOptionsTable)..where((t) => t.id.equals(id))).write(
        ModifierOptionsTableCompanion(
          name: Value(name),
          additionalPrice: Value(additionalPrice),
        ),
      );
}
