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
}
