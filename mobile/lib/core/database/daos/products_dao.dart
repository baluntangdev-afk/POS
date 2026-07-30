import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_groups_table.dart';
import '../tables/products_table.dart';
import '../tables/product_variants_table.dart';
import '../tables/modifier_groups_table.dart';
import '../tables/modifier_options_table.dart';
import '../tables/product_modifier_groups_table.dart';
import '../tables/sale_items_table.dart';

part 'products_dao.g.dart';

class ProductWithPrice {
  final ProductsTableData product;
  final double price;
  const ProductWithPrice({required this.product, required this.price});
}

@DriftAccessor(tables: [
  ProductGroupsTable,
  ProductsTable,
  ProductVariantsTable,
  ModifierGroupsTable,
  ModifierOptionsTable,
  ProductModifierGroupsTable,
  SaleItemsTable,
])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  // ── Categories ────────────────────────────────────────────────────────

  Future<List<ProductGroupsTableData>> getAllActiveGroups() =>
      (select(productGroupsTable)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Returns every category, active or not — used by the Categories tab so
  /// inactive categories can still be edited/reactivated.
  Future<List<ProductGroupsTableData>> getAllGroups() =>
      (select(productGroupsTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<ProductGroupsTableData?> getGroupById(int id) =>
      (select(productGroupsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insert(companion);

  Future<int> upsertProductGroup(ProductGroupsTableCompanion companion) =>
      into(productGroupsTable).insertOnConflictUpdate(companion);

  Future<int> updateProductGroup(int id, {required String name, required bool isActive, int? sortOrder}) =>
      (update(productGroupsTable)..where((t) => t.id.equals(id))).write(
        ProductGroupsTableCompanion(
          name: Value(name),
          isActive: Value(isActive),
          sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        ),
      );

  /// Hard-deletes a category. Only safe to call once every product under it
  /// has been removed — `products.group_id` is a non-null reference.
  Future<void> deleteProductGroup(int id) =>
      (delete(productGroupsTable)..where((t) => t.id.equals(id))).go();

  // ── Products ──────────────────────────────────────────────────────────

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

  /// Pairs every product with its default variant's price (0 if it has none
  /// yet), in one query — used for the Products grid, which never needs the
  /// full variant list, just a display price.
  Future<List<ProductWithPrice>> getAllProductsWithPrice() async {
    final query = select(productsTable).join([
      leftOuterJoin(
        productVariantsTable,
        productVariantsTable.productId.equalsExp(productsTable.id) &
            productVariantsTable.isDefault.equals(true),
      ),
    ])
      ..orderBy([OrderingTerm.asc(productsTable.sortOrder)]);
    final rows = await query.get();
    return rows.map((r) {
      final product = r.readTable(productsTable);
      final variant = r.readTableOrNull(productVariantsTable);
      return ProductWithPrice(product: product, price: variant?.price ?? 0);
    }).toList();
  }

  Future<int> insertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insert(companion);

  Future<int> upsertProduct(ProductsTableCompanion companion) =>
      into(productsTable).insertOnConflictUpdate(companion);

  Future<int> toggleProductAvailability(int productId, {required bool isAvailable}) =>
      (update(productsTable)..where((t) => t.id.equals(productId)))
          .write(ProductsTableCompanion(isAvailable: Value(isAvailable)));

  /// True when `productId` appears in any sale — deleting it would corrupt
  /// transaction history, so callers must keep the row (deactivated) instead.
  Future<bool> productHasSaleHistory(int productId) async {
    final row = await (select(saleItemsTable)
          ..where((t) => t.productId.equals(productId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Hard-deletes a product. Only call after [productHasSaleHistory] is false
  /// and its variants / modifier-group links have already been removed.
  Future<void> deleteProduct(int id) => (delete(productsTable)..where((t) => t.id.equals(id))).go();

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

  // ── Variants ──────────────────────────────────────────────────────────

  Future<List<ProductVariantsTableData>> getVariantsForProduct(int productId) =>
      (select(productVariantsTable)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.isDefault),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  Future<int> insertVariant(ProductVariantsTableCompanion companion) =>
      into(productVariantsTable).insert(companion);

  Future<int> updateVariant(
    int id, {
    required String name,
    required double price,
    required bool isDefault,
    required bool isActive,
  }) =>
      (update(productVariantsTable)..where((t) => t.id.equals(id))).write(
        ProductVariantsTableCompanion(
          name: Value(name),
          price: Value(price),
          isDefault: Value(isDefault),
          isActive: Value(isActive),
        ),
      );

  /// Hard-deletes a variant. Nothing references product_variants by FK
  /// (sale_items stores the variant name as plain text), so this is always
  /// safe regardless of order history.
  Future<void> deleteVariant(int id) =>
      (delete(productVariantsTable)..where((t) => t.id.equals(id))).go();

  Future<void> clearDefaultVariant(int productId) =>
      (update(productVariantsTable)..where((t) => t.productId.equals(productId)))
          .write(const ProductVariantsTableCompanion(isDefault: Value(false)));

  Future<int> toggleVariantActive(int id, {required bool isActive}) =>
      (update(productVariantsTable)..where((t) => t.id.equals(id)))
          .write(ProductVariantsTableCompanion(isActive: Value(isActive)));

  // ── Modifier groups (global) ─────────────────────────────────────────

  Future<List<ModifierGroupsTableData>> getAllModifierGroups() =>
      (select(modifierGroupsTable)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<ModifierGroupsTableData?> getModifierGroupById(int id) =>
      (select(modifierGroupsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createModifierGroup(ModifierGroupsTableCompanion companion) =>
      into(modifierGroupsTable).insert(companion);

  Future<int> updateModifierGroup(
    int id, {
    required String name,
    required bool isRequired,
    required int maxSelections,
  }) =>
      (update(modifierGroupsTable)..where((t) => t.id.equals(id))).write(
        ModifierGroupsTableCompanion(
          name: Value(name),
          isRequired: Value(isRequired),
          maxSelections: Value(maxSelections),
        ),
      );

  Future<int> toggleModifierGroupActive(int id, {required bool isActive}) =>
      (update(modifierGroupsTable)..where((t) => t.id.equals(id)))
          .write(ModifierGroupsTableCompanion(isActive: Value(isActive)));

  Future<List<ModifierOptionsTableData>> getOptionsForGroup(int groupId) =>
      (select(modifierOptionsTable)..where((t) => t.groupId.equals(groupId))).get();

  Future<int> insertModifierOption(ModifierOptionsTableCompanion companion) =>
      into(modifierOptionsTable).insert(companion);

  Future<int> updateModifierOption(int id, {required String name, required double additionalPrice}) =>
      (update(modifierOptionsTable)..where((t) => t.id.equals(id))).write(
        ModifierOptionsTableCompanion(
          name: Value(name),
          additionalPrice: Value(additionalPrice),
        ),
      );

  Future<int> toggleModifierOptionActive(int id, {required bool isActive}) =>
      (update(modifierOptionsTable)..where((t) => t.id.equals(id)))
          .write(ModifierOptionsTableCompanion(isActive: Value(isActive)));

  // ── product_modifier_groups junction ─────────────────────────────────

  Future<List<int>> getAttachedModifierGroupIds(int productId) async {
    final rows = await (select(productModifierGroupsTable)
          ..where((t) => t.productId.equals(productId)))
        .get();
    return rows.map((r) => r.modifierGroupId).toList();
  }

  Future<List<ModifierGroupsTableData>> getModifierGroupsForProduct(int productId) async {
    final query = select(modifierGroupsTable).join([
      innerJoin(
        productModifierGroupsTable,
        productModifierGroupsTable.modifierGroupId.equalsExp(modifierGroupsTable.id),
      ),
    ])
      ..where(productModifierGroupsTable.productId.equals(productId));
    final rows = await query.get();
    return rows.map((r) => r.readTable(modifierGroupsTable)).toList();
  }

  Future<void> attachModifierGroupToProduct(int productId, int modifierGroupId) async {
    final existing = await (select(productModifierGroupsTable)
          ..where((t) =>
              t.productId.equals(productId) & t.modifierGroupId.equals(modifierGroupId)))
        .getSingleOrNull();
    if (existing != null) return;
    await into(productModifierGroupsTable).insert(
      ProductModifierGroupsTableCompanion.insert(
        productId: productId,
        modifierGroupId: modifierGroupId,
      ),
    );
  }

  Future<void> detachModifierGroupFromProduct(int productId, int modifierGroupId) =>
      (delete(productModifierGroupsTable)
            ..where((t) =>
                t.productId.equals(productId) & t.modifierGroupId.equals(modifierGroupId)))
          .go();

  Future<void> deleteModifierGroupLinksForProduct(int productId) =>
      (delete(productModifierGroupsTable)..where((t) => t.productId.equals(productId))).go();
}
