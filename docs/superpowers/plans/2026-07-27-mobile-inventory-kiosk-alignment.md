# Mobile Inventory — Kiosk Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring mobile's (`mobile/`) offline inventory management to full data-model and UX parity with kiosk's: products gain multiple named variants (replacing the flat `price`), modifier groups become global/reusable via a junction table, all hard deletes are replaced with soft `isActive` toggles, the Inventory screen becomes a 3-tab shell (Products / Categories / Modifier Groups), and admin/supervisor-only actions are role-gated.

**Architecture:** Mobile stays fully offline (drift/SQLite, no backend). Existing feature-first layout (`lib/features/inventory/{entities,state,view}`) is kept. Schema changes land as drift schema v6 with a data-preserving migration (create new tables, backfill from old columns, then rebuild `products`/`modifier_groups` to drop the retired columns). DAO, notifiers, and screens are updated to match. Reference: `docs/superpowers/specs/2026-07-26-mobile-inventory-kiosk-alignment-design.md` (already on disk — this plan implements it exactly).

**Tech Stack:** Flutter, `hooks_riverpod`, `drift` 2.24 (SQLite), `flutter_hooks`, `go_router`, `flutter_test` + `drift/native.dart` `NativeDatabase.memory()` for tests.

---

## Task 1: Schema — variants table, junction table, isActive columns, migration v6

**Files:**
- Create: `mobile/lib/core/database/tables/product_variants_table.dart`
- Create: `mobile/lib/core/database/tables/product_modifier_groups_table.dart`
- Modify: `mobile/lib/core/database/tables/products_table.dart`
- Modify: `mobile/lib/core/database/tables/modifier_groups_table.dart`
- Modify: `mobile/lib/core/database/tables/modifier_options_table.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Test: `mobile/test/core/database/schema_migration_v6_test.dart`

- [ ] **Step 1: Write the failing migration test**

```dart
// mobile/test/core/database/schema_migration_v6_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  test('schemaVersion is at least 6 and variants/junction tables exist with backfilled data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(6));

    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    // products.price no longer exists as a Dart column — this line intentionally
    // does not reference it. A fresh onCreate DB has no products.price to backfill
    // from, so this test only asserts the *shape* (tables/columns exist), not the
    // backfill itself. The backfill is covered by Step 3's dedicated upgrade test.
    await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
      productId: productId,
      name: 'Regular',
      price: 99.0,
      isDefault: const Value(true),
    ));

    final variants = await db.productsDao.getVariantsForProduct(productId);
    expect(variants, hasLength(1));
    expect(variants.single.price, 99.0);
    expect(variants.single.isDefault, isTrue);
    expect(variants.single.isActive, isTrue);

    final modGroupId = await db.productsDao.createModifierGroup(
        ModifierGroupsTableCompanion.insert(name: 'Size'));
    await db.productsDao.attachModifierGroupToProduct(productId, modGroupId);
    final attached = await db.productsDao.getModifierGroupsForProduct(productId);
    expect(attached, hasLength(1));
    expect(attached.single.isActive, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && fvm flutter test test/core/database/schema_migration_v6_test.dart`
Expected: FAIL — `ProductVariantsTableCompanion`, `insertVariant`, `getVariantsForProduct`, `createModifierGroup`, `attachModifierGroupToProduct`, `getModifierGroupsForProduct` (new signature) don't exist yet.

- [ ] **Step 3: Create `product_variants_table.dart`**

```dart
// mobile/lib/core/database/tables/product_variants_table.dart
import 'package:drift/drift.dart';
import 'products_table.dart';

class ProductVariantsTable extends Table {
  @override
  String get tableName => 'product_variants';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 4: Create `product_modifier_groups_table.dart`**

```dart
// mobile/lib/core/database/tables/product_modifier_groups_table.dart
import 'package:drift/drift.dart';
import 'products_table.dart';
import 'modifier_groups_table.dart';

class ProductModifierGroupsTable extends Table {
  @override
  String get tableName => 'product_modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  IntColumn get modifierGroupId => integer().references(ModifierGroupsTable, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {productId, modifierGroupId},
      ];
}
```

- [ ] **Step 5: Update `products_table.dart` — drop `price`**

```dart
// mobile/lib/core/database/tables/products_table.dart
import 'package:drift/drift.dart';
import 'product_groups_table.dart';

class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ProductGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 6: Update `modifier_groups_table.dart` — drop `productId`, add `isActive`**

```dart
// mobile/lib/core/database/tables/modifier_groups_table.dart
import 'package:drift/drift.dart';

class ModifierGroupsTable extends Table {
  @override
  String get tableName => 'modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 7: Update `modifier_options_table.dart` — add `isActive`**

```dart
// mobile/lib/core/database/tables/modifier_options_table.dart
import 'package:drift/drift.dart';
import 'modifier_groups_table.dart';

class ModifierOptionsTable extends Table {
  @override
  String get tableName => 'modifier_options';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ModifierGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 8: Update `app_database.dart` — register new tables, bump to schema v6, add migration**

```dart
// mobile/lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/users_table.dart';
import 'tables/product_groups_table.dart';
import 'tables/products_table.dart';
import 'tables/product_variants_table.dart';
import 'tables/modifier_groups_table.dart';
import 'tables/modifier_options_table.dart';
import 'tables/product_modifier_groups_table.dart';
import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sale_item_modifiers_table.dart';
import 'tables/payments_table.dart';
import 'tables/refunds_table.dart';
import 'tables/refund_items_table.dart';
import 'tables/store_info_table.dart';
import 'tables/x_readings_table.dart';
import 'tables/daily_reports_table.dart';
import 'tables/z_readings_table.dart';
import 'tables/payment_methods_table.dart';
import 'daos/users_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/store_info_dao.dart';
import 'daos/cashier_accounting_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersTable,
    ProductGroupsTable,
    ProductsTable,
    ProductVariantsTable,
    ModifierGroupsTable,
    ModifierOptionsTable,
    ProductModifierGroupsTable,
    SalesTable,
    SaleItemsTable,
    SaleItemModifiersTable,
    PaymentsTable,
    RefundsTable,
    RefundItemsTable,
    StoreInfoTable,
    XReadingsTable,
    DailyReportsTable,
    ZReadingsTable,
    PaymentMethodsTable,
  ],
  daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao, CashierAccountingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'mobile_pos'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await storeInfoDao.ensureStoreInfoExists();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(xReadingsTable);
            await m.createTable(dailyReportsTable);
            await m.createTable(zReadingsTable);
          }
          if (from < 3) {
            await m.addColumn(storeInfoTable, storeInfoTable.tin);
            await m.createTable(paymentMethodsTable);
          }
          if (from < 4) {
            await m.addColumn(storeInfoTable, storeInfoTable.terminalName);
          }
          if (from < 5) {
            await m.addColumn(usersTable, usersTable.employeeId);
            await m.addColumn(usersTable, usersTable.phone);
            await m.addColumn(usersTable, usersTable.avatarUrl);
            await m.addColumn(usersTable, usersTable.isPinChanged);
          }
          if (from < 6) {
            await m.createTable(productVariantsTable);
            await m.createTable(productModifierGroupsTable);
            await m.addColumn(modifierGroupsTable, modifierGroupsTable.isActive);
            await m.addColumn(modifierOptionsTable, modifierOptionsTable.isActive);

            // Backfill one default variant per existing product, reading the
            // about-to-be-dropped `products.price` column directly via raw SQL —
            // the generated ProductsTable Dart class no longer exposes it.
            final existingProducts =
                await customSelect('SELECT id, price FROM products').get();
            for (final row in existingProducts) {
              await into(productVariantsTable).insert(ProductVariantsTableCompanion.insert(
                productId: row.read<int>('id'),
                name: 'Regular',
                price: row.read<double>('price'),
                isDefault: const Value(true),
                isActive: const Value(true),
              ));
            }

            // Backfill: link every existing modifier_groups row (which still has
            // a product_id column on disk at this point) to its original product
            // via the new junction table, and activate the group.
            final existingGroups =
                await customSelect('SELECT id, product_id FROM modifier_groups').get();
            for (final row in existingGroups) {
              await into(productModifierGroupsTable).insert(ProductModifierGroupsTableCompanion.insert(
                productId: row.read<int>('product_id'),
                modifierGroupId: row.read<int>('id'),
              ));
            }
            await customStatement('UPDATE modifier_groups SET is_active = 1');

            // Drop products.price. SQLite bundled with sqlite3_flutter_libs may not
            // support `ALTER TABLE ... DROP COLUMN`, so rebuild the table: create a
            // shadow table with the new (column-dropped) shape, copy data, swap it in.
            await customStatement('''
              CREATE TABLE products_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                group_id INTEGER NOT NULL REFERENCES product_groups (id),
                name TEXT NOT NULL,
                is_available INTEGER NOT NULL DEFAULT 1,
                image_url TEXT,
                sort_order INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await customStatement('''
              INSERT INTO products_new (id, group_id, name, is_available, image_url, sort_order)
              SELECT id, group_id, name, is_available, image_url, sort_order FROM products
            ''');
            await customStatement('DROP TABLE products');
            await customStatement('ALTER TABLE products_new RENAME TO products');

            // Drop modifier_groups.product_id the same way.
            await customStatement('''
              CREATE TABLE modifier_groups_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                is_required INTEGER NOT NULL DEFAULT 0,
                max_selections INTEGER NOT NULL DEFAULT 1,
                is_active INTEGER NOT NULL DEFAULT 1
              )
            ''');
            await customStatement('''
              INSERT INTO modifier_groups_new (id, name, is_required, max_selections, is_active)
              SELECT id, name, is_required, max_selections, is_active FROM modifier_groups
            ''');
            await customStatement('DROP TABLE modifier_groups');
            await customStatement('ALTER TABLE modifier_groups_new RENAME TO modifier_groups');
          }
        },
      );
}
```

- [ ] **Step 9: Regenerate drift code**

Run: `cd mobile && fvm dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds, regenerating `app_database.g.dart`. (This will show errors referencing `products_dao.dart` still using the old `price`/`productId` fields — that's expected here, Task 2 fixes the DAO. Re-run `build_runner` again at the end of Task 2.)

- [ ] **Step 10: Commit**

```bash
cd mobile
git add lib/core/database/tables/product_variants_table.dart lib/core/database/tables/product_modifier_groups_table.dart lib/core/database/tables/products_table.dart lib/core/database/tables/modifier_groups_table.dart lib/core/database/tables/modifier_options_table.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart test/core/database/schema_migration_v6_test.dart
git commit -m "feat: add product variants and global modifier group schema (v6)"
```

(Test run/verification for this task happens at the end of Task 2, once the DAO compiles again.)

---

## Task 2: `ProductsDao` — remove hard deletes, add variant + global modifier-group + junction methods

**Files:**
- Modify: `mobile/lib/core/database/daos/products_dao.dart`
- Modify: `mobile/test/core/database/daos/products_dao_crud_test.dart` (rewrite — delete-oriented tests no longer apply)

- [ ] **Step 1: Replace `products_dao_crud_test.dart` with toggle/variant/junction-oriented tests**

```dart
// mobile/test/core/database/daos/products_dao_crud_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('getGroupById returns the group row or null', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final row = await db.productsDao.getGroupById(groupId);
    expect(row!.name, 'Drinks');
    expect(await db.productsDao.getGroupById(9999), isNull);
  });

  test('isProductNameTaken detects duplicate names within the same group, case-insensitive', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    expect(await db.productsDao.isProductNameTaken(groupId, 'latte'), isTrue);
    expect(await db.productsDao.isProductNameTaken(groupId, 'Latte', excludeId: null), isTrue);
    expect(await db.productsDao.isProductNameTaken(groupId, 'Mocha'), isFalse);
  });

  test('updateProductGroup can toggle isActive without needing an empty-products guard', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    await db.productsDao.updateProductGroup(groupId, name: 'Drinks', isActive: false);

    final row = await db.productsDao.getGroupById(groupId);
    expect(row!.isActive, isFalse);
  });

  test('variant CRUD: insert, getVariantsForProduct, updateVariant, toggleVariantActive', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final variantId = await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
      productId: productId,
      name: 'Regular',
      price: 100,
      isDefault: const Value(true),
    ));

    var variants = await db.productsDao.getVariantsForProduct(productId);
    expect(variants, hasLength(1));
    expect(variants.single.price, 100);

    await db.productsDao.updateVariant(variantId, name: 'Regular', price: 110, isDefault: true, isActive: true);
    variants = await db.productsDao.getVariantsForProduct(productId);
    expect(variants.single.price, 110);

    await db.productsDao.toggleVariantActive(variantId, isActive: false);
    variants = await db.productsDao.getVariantsForProduct(productId);
    expect(variants.single.isActive, isFalse);
  });

  test('clearDefaultVariant unsets isDefault on every variant of a product', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));
    final v1 = await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
      productId: productId, name: 'Small', price: 90, isDefault: const Value(true),
    ));
    await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
      productId: productId, name: 'Large', price: 120,
    ));

    await db.productsDao.clearDefaultVariant(productId);
    await db.productsDao.updateVariant(v1, name: 'Small', price: 90, isDefault: false, isActive: true);

    final variants = await db.productsDao.getVariantsForProduct(productId);
    expect(variants.every((v) => v.isDefault == false), isTrue);
  });

  test('global modifier groups: create, update, toggleModifierGroupActive, options', () async {
    final groupId = await db.productsDao.createModifierGroup(
        ModifierGroupsTableCompanion.insert(name: 'Size'));

    var groups = await db.productsDao.getAllModifierGroups();
    expect(groups, hasLength(1));
    expect(groups.single.isActive, isTrue);

    await db.productsDao.updateModifierGroup(groupId, name: 'Sizes', isRequired: true, maxSelections: 1);
    groups = await db.productsDao.getAllModifierGroups();
    expect(groups.single.name, 'Sizes');

    await db.productsDao.toggleModifierGroupActive(groupId, isActive: false);
    groups = await db.productsDao.getAllModifierGroups();
    expect(groups.single.isActive, isFalse);

    final optionId = await db.productsDao.insertModifierOption(
        ModifierOptionsTableCompanion.insert(groupId: groupId, name: 'Large'));
    await db.productsDao.toggleModifierOptionActive(optionId, isActive: false);
    final options = await db.productsDao.getOptionsForGroup(groupId);
    expect(options.single.isActive, isFalse);
  });

  test('junction table: attach/detach modifier groups to a product, idempotent attach', () async {
    final prodGroupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: prodGroupId, name: 'Latte'));
    final modGroupId = await db.productsDao.createModifierGroup(
        ModifierGroupsTableCompanion.insert(name: 'Size'));

    await db.productsDao.attachModifierGroupToProduct(productId, modGroupId);
    await db.productsDao.attachModifierGroupToProduct(productId, modGroupId); // idempotent

    var attached = await db.productsDao.getModifierGroupsForProduct(productId);
    expect(attached, hasLength(1));

    var attachedIds = await db.productsDao.getAttachedModifierGroupIds(productId);
    expect(attachedIds, [modGroupId]);

    await db.productsDao.detachModifierGroupFromProduct(productId, modGroupId);
    attached = await db.productsDao.getModifierGroupsForProduct(productId);
    expect(attached, isEmpty);
  });

  test('getAllProductsWithPrice returns each product paired with its default variant price', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));
    await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
      productId: productId, name: 'Regular', price: 88, isDefault: const Value(true),
    ));

    final results = await db.productsDao.getAllProductsWithPrice();
    expect(results, hasLength(1));
    expect(results.single.product.name, 'Latte');
    expect(results.single.price, 88);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && fvm flutter test test/core/database/daos/products_dao_crud_test.dart`
Expected: FAIL — none of the new DAO methods exist yet.

- [ ] **Step 3: Rewrite `products_dao.dart`**

```dart
// mobile/lib/core/database/daos/products_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_groups_table.dart';
import '../tables/products_table.dart';
import '../tables/product_variants_table.dart';
import '../tables/modifier_groups_table.dart';
import '../tables/modifier_options_table.dart';
import '../tables/product_modifier_groups_table.dart';

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
}
```

- [ ] **Step 4: Regenerate drift code and run tests**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/core/database/daos/products_dao_crud_test.dart test/core/database/schema_migration_v6_test.dart
```

Expected: both files PASS. (`inventory_notifier_crud_test.dart`, `modifier_groups_notifier_test.dart`, `inventory_screen.dart`, `product_form_dialog.dart`, and the other modifier-group view files will fail to compile at this point — that's expected, they're fixed in Tasks 4–10. Do not treat that as a regression in this task.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/daos/products_dao.dart lib/core/database/daos/products_dao.g.dart test/core/database/daos/products_dao_crud_test.dart
git commit -m "feat: rewrite ProductsDao for variants, global modifier groups, and soft-delete"
```

---

## Task 3: CSV importer — write a default variant instead of a flat price

**Files:**
- Modify: `mobile/lib/core/csv/products_csv_importer.dart`
- Test: `mobile/test/core/csv/products_csv_importer_test.dart` (create if it doesn't already exist under this exact path — check first with `Test-Path` before assuming; if a differently-named existing test already covers this importer, extend that file instead of creating a duplicate)

- [ ] **Step 1: Check for an existing importer test**

Run: `cd mobile && Get-ChildItem -Recurse -Filter "*csv*" test/` (PowerShell) or `find test -iname "*csv*"` (bash)
If a file already tests `ProductsCsvImporter`, extend it instead of creating a new one — adapt the test below into that file's structure. If none exists, create it as shown in Step 2.

- [ ] **Step 2: Write the failing test**

```dart
// mobile/test/core/csv/products_csv_importer_test.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/csv/products_csv_importer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  test('importFile creates a default variant per product using the row price', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final tempDir = await Directory.systemTemp.createTemp('csv_import_test');
    addTearDown(() => tempDir.delete(recursive: true));
    final file = File(p.join(tempDir.path, 'products.csv'));
    await file.writeAsString(
      'group_name,product_name,price,is_available,image_url,sort_order\n'
      'Drinks,Latte,120,true,,1\n',
    );

    final importer = ProductsCsvImporter(db);
    final result = await importer.importFile(file);

    expect(result.successCount, 1);
    expect(result.errors, isEmpty);

    final products = await db.productsDao.getAllProducts();
    expect(products, hasLength(1));
    final variants = await db.productsDao.getVariantsForProduct(products.single.id);
    expect(variants, hasLength(1));
    expect(variants.single.name, 'Regular');
    expect(variants.single.price, 120);
    expect(variants.single.isDefault, isTrue);
    expect(variants.single.isActive, isTrue);
  });
}
```

(Drop the unused `PathProviderPlatform` import if `Directory.systemTemp` alone is sufficient in this project's test setup — check an existing test that writes temp files, e.g. `report_export_service_test.dart`, and mirror its exact temp-file pattern instead of guessing at unavailable packages.)

- [ ] **Step 3: Run test to verify it fails**

Run: `cd mobile && fvm flutter test test/core/csv/products_csv_importer_test.dart`
Expected: FAIL — `upsertProduct` no longer accepts a `price` field (removed in Task 1/2), so this fails to compile/build against the current importer code.

- [ ] **Step 4: Update `products_csv_importer.dart`**

```dart
// mobile/lib/core/csv/products_csv_importer.dart
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Expected columns (header row required):
/// group_name, product_name, price, is_available, image_url, sort_order
class ProductsCsvImporter implements CsvImporter {
  final AppDatabase _db;
  const ProductsCsvImporter(this._db);

  @override
  Future<ImportResult> importFile(File file) async {
    final rows = _parse(await file.readAsString());
    if (rows.isEmpty) return const ImportResult(successCount: 0, skippedCount: 0, errors: []);

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.skip(1).toList();

    final groupCache = <String, int>{};
    int success = 0, skipped = 0;
    final errors = <CsvRowError>[];

    for (int i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2;
      try {
        final row = _mapRow(headers, dataRows[i]);
        final groupName = (row['group_name'] ?? '').toString().trim();
        final productName = (row['product_name'] ?? '').toString().trim();
        final priceStr = (row['price'] ?? '0').toString().trim();

        if (groupName.isEmpty || productName.isEmpty) {
          errors.add(CsvRowError(rowNum, 'group_name and product_name are required'));
          continue;
        }

        final price = double.tryParse(priceStr);
        if (price == null) {
          errors.add(CsvRowError(rowNum, 'Invalid price: $priceStr'));
          continue;
        }

        final groupId = groupCache[groupName] ?? await _ensureGroup(groupName);
        groupCache[groupName] = groupId;

        final isAvailable = (row['is_available'] ?? 'true').toString().toLowerCase() != 'false';
        final imageUrl = (row['image_url'] ?? '').toString().trim();
        final sortOrder = int.tryParse((row['sort_order'] ?? '0').toString()) ?? 0;

        final productId = await _db.productsDao.upsertProduct(
          ProductsTableCompanion(
            groupId: Value(groupId),
            name: Value(productName),
            isAvailable: Value(isAvailable),
            imageUrl: imageUrl.isEmpty ? const Value.absent() : Value(imageUrl),
            sortOrder: Value(sortOrder),
          ),
        );

        await _db.productsDao.clearDefaultVariant(productId);
        final existingVariants = await _db.productsDao.getVariantsForProduct(productId);
        if (existingVariants.isEmpty) {
          await _db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
            productId: productId,
            name: 'Regular',
            price: price,
            isDefault: const Value(true),
          ));
        } else {
          await _db.productsDao.updateVariant(
            existingVariants.first.id,
            name: existingVariants.first.name,
            price: price,
            isDefault: true,
            isActive: true,
          );
        }
        success++;
      } catch (e) {
        errors.add(CsvRowError(rowNum, e.toString()));
      }
    }

    return ImportResult(successCount: success, skippedCount: skipped, errors: errors);
  }

  Future<int> _ensureGroup(String name) async {
    final groups = await _db.productsDao.getAllActiveGroups();
    final existing = groups.where((g) => g.name == name).firstOrNull;
    if (existing != null) return existing.id;
    return _db.productsDao.insertProductGroup(
      ProductGroupsTableCompanion(name: Value(name)),
    );
  }

  List<List<dynamic>> _parse(String content) {
    return const CsvToListConverter(eol: '\n').convert(content);
  }

  Map<String, dynamic> _mapRow(List<String> headers, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i] : null;
    }
    return map;
  }
}
```

Note: `upsertProduct` on a brand-new row with `ProductsTableCompanion` (no explicit `id`) inserts and returns the new row's id via `insertOnConflictUpdate`, same as it did before — behavior here is unchanged from the pre-existing importer for that part.

- [ ] **Step 5: Run test to verify it passes**

Run: `cd mobile && fvm flutter test test/core/csv/products_csv_importer_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/csv/products_csv_importer.dart test/core/csv/products_csv_importer_test.dart
git commit -m "feat: CSV importer creates a default variant instead of a flat price"
```

---

## Task 4: Inventory entities + `InventoryNotifier` — variants, no hard deletes

**Files:**
- Modify: `mobile/lib/features/inventory/entities/inventory_product.dart`
- Modify: `mobile/lib/features/inventory/state/inventory_notifier.dart`
- Modify: `mobile/test/features/inventory/state/inventory_notifier_crud_test.dart`

- [ ] **Step 1: Rewrite the entity file**

```dart
// mobile/lib/features/inventory/entities/inventory_product.dart
class InventoryGroup {
  final int id;
  final String name;
  final int productCount;
  const InventoryGroup({required this.id, required this.name, required this.productCount});
}

class InventoryProduct {
  final int id;
  final int groupId;
  final String name;
  final double price;
  final bool isAvailable;
  final String? imageUrl;
  final int sortOrder;
  final InventoryGroup? group;

  const InventoryProduct({
    required this.id,
    required this.groupId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    required this.sortOrder,
    this.group,
  });

  InventoryProduct copyWith({bool? isAvailable}) => InventoryProduct(
        id: id,
        groupId: groupId,
        name: name,
        price: price,
        isAvailable: isAvailable ?? this.isAvailable,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        group: group,
      );
}

/// One editable row in the product form's variants editor. [id] is null for
/// a not-yet-persisted row.
class VariantInput {
  final int? id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isActive;

  const VariantInput({
    this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    required this.isActive,
  });
}
```

- [ ] **Step 2: Rewrite the failing/updated notifier test**

```dart
// mobile/test/features/inventory/state/inventory_notifier_crud_test.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/inventory/entities/inventory_product.dart';
import 'package:mobile/features/inventory/state/inventory_notifier.dart';

void main() {
  test('createProduct inserts, then saveVariants attaches a default variant and refreshes price', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    final productId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );
    await container.read(inventoryNotifierProvider.notifier).saveVariants(productId, [
      const VariantInput(name: 'Regular', price: 100, isDefault: true, isActive: true),
    ]);

    final state = await container.read(inventoryNotifierProvider.future);
    final product = state.products.firstWhere((p) => p.id == productId);
    expect(product.name, 'Latte');
    expect(product.price, 100);
  });

  test('createProduct rejects a duplicate name within the same group', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).createProduct(
            groupId: groupId,
            name: 'latte',
            imageUrl: null,
          ),
      throwsA(anything),
    );
  });

  test('updateProduct changes fields and refreshes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    final productId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );

    await container.read(inventoryNotifierProvider.notifier).updateProduct(
          id: productId,
          groupId: groupId,
          name: 'Iced Latte',
          imageUrl: null,
        );

    final state = await container.read(inventoryNotifierProvider.future);
    final updated = state.products.firstWhere((p) => p.id == productId);
    expect(updated.name, 'Iced Latte');
  });

  test('updateProduct rejects renaming to a name already taken by another product', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );
    final mochaId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Mocha',
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).updateProduct(
            id: mochaId,
            groupId: groupId,
            name: 'latte',
            imageUrl: null,
          ),
      throwsA(anything),
    );
  });

  test('toggleAvailability flips isAvailable and refreshes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    final productId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );
    var state = await container.read(inventoryNotifierProvider.future);
    final product = state.products.firstWhere((p) => p.id == productId);

    await container.read(inventoryNotifierProvider.notifier).toggleAvailability(product);
    state = await container.read(inventoryNotifierProvider.future);
    expect(state.products.firstWhere((p) => p.id == productId).isAvailable, isFalse);
  });

  test('createCategory and updateCategory (toggle isActive) work end to end; no delete method exists', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    await container.read(inventoryNotifierProvider.notifier).createCategory(name: 'Snacks');

    var state = await container.read(inventoryNotifierProvider.future);
    final group = state.groups.firstWhere((g) => g.name == 'Snacks');

    await container.read(inventoryNotifierProvider.notifier).updateCategory(
          id: group.id,
          name: 'Sweet Snacks',
          isActive: false,
        );
    state = await container.read(inventoryNotifierProvider.future);
    // Deactivated categories drop out of the active-groups list used for `state.groups`.
    expect(state.groups.any((g) => g.id == group.id), isFalse);
  });

  test('saveVariants enforces at least one active variant', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    final productId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).saveVariants(productId, [
        const VariantInput(name: 'Regular', price: 100, isDefault: true, isActive: false),
      ]),
      throwsA(anything),
    );
  });

  test('saveVariants enforces unique case-insensitive names among active variants', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(inventoryNotifierProvider.future);
    final productId = await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).saveVariants(productId, [
        const VariantInput(name: 'Regular', price: 100, isDefault: true, isActive: true),
        const VariantInput(name: 'regular', price: 110, isDefault: false, isActive: true),
      ]),
      throwsA(anything),
    );
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd mobile && fvm flutter test test/features/inventory/state/inventory_notifier_crud_test.dart`
Expected: FAIL — `createProduct` still returns `void`/requires `price`, `saveVariants` doesn't exist, `deleteProduct`/`deleteCategory` still exist instead of being removed, `updateCategory`'s effect on `state.groups` isn't what the test expects yet.

- [ ] **Step 4: Rewrite `inventory_notifier.dart`**

```dart
// mobile/lib/features/inventory/state/inventory_notifier.dart
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/inventory_product.dart';

class InventoryState {
  final List<InventoryGroup> groups;
  final List<InventoryProduct> products;
  final int? selectedGroupId;
  final String? search;

  const InventoryState({
    this.groups = const [],
    this.products = const [],
    this.selectedGroupId,
    this.search,
  });

  List<InventoryProduct> get filtered {
    var list = products;
    if (selectedGroupId != null) {
      list = list.where((p) => p.groupId == selectedGroupId).toList();
    }
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  InventoryState copyWith({
    List<InventoryGroup>? groups,
    List<InventoryProduct>? products,
    int? Function()? selectedGroupId,
    String? Function()? search,
  }) =>
      InventoryState(
        groups: groups ?? this.groups,
        products: products ?? this.products,
        selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        search: search != null ? search() : this.search,
      );
}

class InventoryNotifier extends AsyncNotifier<InventoryState> {
  @override
  Future<InventoryState> build() => _load();

  Future<InventoryState> _load() async {
    final db = ref.watch(databaseProvider);
    final groupRows = await db.productsDao.getAllActiveGroups();
    final productRows = await db.productsDao.getAllProductsWithPrice();

    final groupCounts = <int, int>{};
    for (final p in productRows) {
      groupCounts[p.product.groupId] = (groupCounts[p.product.groupId] ?? 0) + 1;
    }

    final groups = groupRows
        .map((g) => InventoryGroup(id: g.id, name: g.name, productCount: groupCounts[g.id] ?? 0))
        .toList();

    final groupById = {for (final g in groups) g.id: g};

    final products = productRows
        .map((p) => InventoryProduct(
              id: p.product.id,
              groupId: p.product.groupId,
              name: p.product.name,
              price: p.price,
              isAvailable: p.product.isAvailable,
              imageUrl: p.product.imageUrl,
              sortOrder: p.product.sortOrder,
              group: groupById[p.product.groupId],
            ))
        .toList();

    return InventoryState(groups: groups, products: products);
  }

  void selectGroup(int? groupId) {
    state = state.whenData((s) => s.copyWith(selectedGroupId: () => groupId));
  }

  void setSearch(String? query) {
    state = state.whenData((s) => s.copyWith(search: () => query?.isEmpty == true ? null : query));
  }

  Future<void> toggleAvailability(InventoryProduct product) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.toggleProductAvailability(product.id, isAvailable: !product.isAvailable);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Creates the product row only (no variants) and returns its new id — the
  /// caller (`ProductFormDialog`) follows up with [saveVariants] once the user
  /// has entered at least one variant.
  Future<int> createProduct({
    required int groupId,
    required String name,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    final id = await db.productsDao.insertProduct(ProductsTableCompanion.insert(
      groupId: groupId,
      name: name,
      imageUrl: Value(imageUrl),
    ));
    await refresh();
    return id;
  }

  Future<void> updateProduct({
    required int id,
    required int groupId,
    required String name,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name, excludeId: id)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    await db.productsDao.upsertProduct(ProductsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  /// Validates and persists a product's full variant list (kiosk's business
  /// rules: at least one active variant, unique case-insensitive names among
  /// active variants, price >= 0.01, exactly one active default).
  Future<void> saveVariants(int productId, List<VariantInput> variants) async {
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) {
      throw StateError('At least one active variant is required');
    }
    final names = active.map((v) => v.name.trim().toLowerCase()).toList();
    if (names.toSet().length != names.length) {
      throw StateError('Variant names must be unique');
    }
    if (active.any((v) => v.price < 0.01)) {
      throw StateError('Each active variant needs a price of at least 0.01');
    }
    final defaultCount = active.where((v) => v.isDefault).length;
    if (defaultCount != 1) {
      throw StateError('Exactly one active variant must be marked default');
    }

    final db = ref.read(databaseProvider);
    await db.productsDao.clearDefaultVariant(productId);
    for (final v in variants) {
      if (v.id == null) {
        await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
          productId: productId,
          name: v.name.trim(),
          price: v.price,
          isDefault: Value(v.isDefault),
          isActive: Value(v.isActive),
        ));
      } else {
        await db.productsDao.updateVariant(
          v.id!,
          name: v.name.trim(),
          price: v.price,
          isDefault: v.isDefault,
          isActive: v.isActive,
        );
      }
    }
    await refresh();
  }

  Future<void> createCategory({required String name}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
    await refresh();
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required bool isActive,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.updateProductGroup(id, name: name, isActive: isActive);
    await refresh();
  }
}

final inventoryNotifierProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

/// Loads a single product's variants — used by [ProductFormDialog] to seed
/// its editable rows in edit mode.
final productVariantsProvider =
    FutureProvider.family<List<ProductVariantsTableData>, int>((ref, productId) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.getVariantsForProduct(productId);
});
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd mobile && fvm flutter test test/features/inventory/state/inventory_notifier_crud_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/entities/inventory_product.dart lib/features/inventory/state/inventory_notifier.dart test/features/inventory/state/inventory_notifier_crud_test.dart
git commit -m "feat: InventoryNotifier supports variants and drops hard-delete methods"
```

---

## Task 5: `ProductFormDialog` — variants editor, remove flat price field

**Files:**
- Modify: `mobile/lib/features/inventory/view/product_form_dialog.dart`

- [ ] **Step 1: Rewrite the dialog**

```dart
// mobile/lib/features/inventory/view/product_form_dialog.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';

class _VariantRow {
  int? id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  bool isDefault;
  bool isActive;

  _VariantRow({
    this.id,
    required String name,
    required String price,
    required this.isDefault,
    required this.isActive,
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price);

  factory _VariantRow.blank({bool isDefault = false}) =>
      _VariantRow(name: '', price: '', isDefault: isDefault, isActive: true);

  factory _VariantRow.fromData(dynamic row) => _VariantRow(
        id: row.id as int,
        name: row.name as String,
        price: _formatPrice(row.price as double),
        isDefault: row.isDefault as bool,
        isActive: row.isActive as bool,
      );

  static String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Create/edit dialog for an inventory product, including its variants.
///
/// [existing] is `null` for create-mode; passing a [InventoryProduct] switches
/// to edit-mode, seeding the variants editor from [productVariantsProvider].
class ProductFormDialog extends ConsumerStatefulWidget {
  final InventoryProduct? existing;
  final int? groupId;

  const ProductFormDialog({super.key, this.existing, this.groupId});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedGroupId;
  String? _imageUrl;
  String? _nameError;
  String? _variantsError;
  bool _isSaving = false;
  bool _variantsLoaded = false;
  List<_VariantRow> _variants = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    final candidateGroupId = existing?.groupId ?? widget.groupId;
    final loadedGroups = ref.read(inventoryNotifierProvider).value?.groups ?? const [];
    _selectedGroupId =
        (candidateGroupId != null && loadedGroups.any((g) => g.id == candidateGroupId))
            ? candidateGroupId
            : null;
    _imageUrl = existing?.imageUrl;

    if (_isEditing) {
      _loadVariants();
    } else {
      _variants = [_VariantRow.blank(isDefault: true)];
      _variantsLoaded = true;
    }
  }

  Future<void> _loadVariants() async {
    final rows = await ref.read(productVariantsProvider(widget.existing!.id).future);
    if (!mounted) return;
    setState(() {
      _variants = rows.isEmpty
          ? [_VariantRow.blank(isDefault: true)]
          : rows.map((r) => _VariantRow.fromData(r)).toList();
      _variantsLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageStorageService.pickAndStore();
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _imageUrl = picked);
  }

  void _removeImage() => setState(() => _imageUrl = null);

  void _addVariant() {
    setState(() => _variants.add(_VariantRow.blank()));
  }

  void _removeVariant(int index) {
    final v = _variants[index];
    if (v.id == null) {
      setState(() {
        v.dispose();
        _variants.removeAt(index);
      });
    } else {
      setState(() => v.isActive = false);
    }
    _reassignDefaultIfNeeded();
  }

  void _setActive(int index, bool value) {
    setState(() => _variants[index].isActive = value);
    _reassignDefaultIfNeeded();
  }

  void _setDefault(int index) {
    setState(() {
      for (var i = 0; i < _variants.length; i++) {
        _variants[i].isDefault = i == index;
      }
    });
  }

  void _reassignDefaultIfNeeded() {
    final active = _variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return;
    final hasActiveDefault = active.any((v) => v.isDefault);
    if (!hasActiveDefault) {
      setState(() {
        for (final v in _variants) {
          v.isDefault = false;
        }
        active.first.isDefault = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = null;
      _variantsError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGroupId == null) return;

    final active = _variants.where((v) => v.isActive).toList();
    if (active.isEmpty) {
      setState(() => _variantsError = 'At least one active variant is required');
      return;
    }
    final names = active.map((v) => v.nameCtrl.text.trim().toLowerCase()).toList();
    if (names.any((n) => n.isEmpty)) {
      setState(() => _variantsError = 'Every active variant needs a name');
      return;
    }
    if (names.toSet().length != names.length) {
      setState(() => _variantsError = 'Variant names must be unique');
      return;
    }
    for (final v in active) {
      final price = double.tryParse(v.priceCtrl.text.trim());
      if (price == null || price < 0.01) {
        setState(() => _variantsError = 'Each active variant needs a price of at least 0.01');
        return;
      }
    }
    if (!active.any((v) => v.isDefault)) {
      setState(() => _variantsError = 'Exactly one active variant must be marked default');
      return;
    }

    final name = _nameController.text.trim();
    final groupId = _selectedGroupId!;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(inventoryNotifierProvider.notifier);
      final int productId;
      if (_isEditing) {
        productId = widget.existing!.id;
        await notifier.updateProduct(
          id: productId,
          groupId: groupId,
          name: name,
          imageUrl: _imageUrl,
        );
      } else {
        productId = await notifier.createProduct(
          groupId: groupId,
          name: name,
          imageUrl: _imageUrl,
        );
      }

      await notifier.saveVariants(
        productId,
        _variants
            .map((v) => VariantInput(
                  id: v.id,
                  name: v.nameCtrl.text.trim(),
                  price: double.tryParse(v.priceCtrl.text.trim()) ?? 0,
                  isDefault: v.isDefault,
                  isActive: v.isActive,
                ))
            .toList(),
      );

      if (mounted) Navigator.pop(context);
    } on StateError catch (e) {
      setState(() => _nameError = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryNotifierProvider).value;
    final groups = inventoryState?.groups ?? const [];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: groups
                      .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
                const Gap(AppSpacing.lg),
                Text('Image', style: AppTextStyles.labelLg.copyWith(color: AppColors.textSecondary)),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    _ImageThumbnail(imageUrl: _imageUrl),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(_imageUrl == null ? 'Choose Image' : 'Change Image'),
                          ),
                          if (_imageUrl != null)
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                              label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Variants', style: AppTextStyles.labelLg.copyWith(color: AppColors.textSecondary)),
                    TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Variant'),
                    ),
                  ],
                ),
                if (_variantsError != null) ...[
                  const Gap(4),
                  Text(_variantsError!, style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                ],
                const Gap(AppSpacing.sm),
                if (!_variantsLoaded)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (var i = 0; i < _variants.length; i++) _VariantRowWidget(
                    key: ValueKey(_variants[i]),
                    row: _variants[i],
                    onRemove: () => _removeVariant(i),
                    onToggleActive: (v) => _setActive(i, v),
                    onSetDefault: () => _setDefault(i),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _VariantRowWidget extends StatelessWidget {
  final _VariantRow row;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onSetDefault;

  const _VariantRowWidget({
    super.key,
    required this.row,
    required this.onRemove,
    required this.onToggleActive,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = row.id == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.nameCtrl,
              decoration: const InputDecoration(labelText: 'Variant name', isDense: true),
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.priceCtrl,
              decoration: const InputDecoration(labelText: 'Price', prefixText: 'PHP ', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            ),
          ),
          const Gap(AppSpacing.sm),
          IconButton(
            tooltip: row.isDefault ? 'Default variant' : 'Make default',
            icon: Icon(
              row.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
              color: row.isDefault ? AppColors.secondary : AppColors.textDisabled,
            ),
            onPressed: row.isActive ? onSetDefault : null,
          ),
          if (isNew)
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: onRemove,
            )
          else
            Switch(
              value: row.isActive,
              onChanged: onToggleActive,
            ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _ImageThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 64,
        height: 64,
        color: AppColors.surfaceVariant,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Icon(Icons.image_outlined, color: AppColors.textDisabled);
    }
    if (ImageStorageService.isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, e, st) => Icon(Icons.broken_image_outlined, color: AppColors.textDisabled),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (context, e, st) => Icon(Icons.broken_image_outlined, color: AppColors.textDisabled),
    );
  }
}
```

Note on `_VariantRow.fromData`: it's typed `dynamic` to accept `ProductVariantsTableData` without an explicit import cycle concern; if the analyzer flags this, change the parameter type to `ProductVariantsTableData` directly and add `import '../../../core/database/app_database.dart';` — prefer the typed version; the `dynamic` signature above is only a fallback if a circular-import issue appears (unlikely, since `inventory_notifier.dart` already imports `app_database.dart` and this file already transitively depends on it through `inventory_notifier.dart`). Use the typed version:

```dart
factory _VariantRow.fromData(ProductVariantsTableData row) => _VariantRow(
      id: row.id,
      name: row.name,
      price: _formatPrice(row.price),
      isDefault: row.isDefault,
      isActive: row.isActive,
    );
```
(and change `import '../state/inventory_notifier.dart';` to also bring in `ProductVariantsTableData` — it's re-exported transitively since `inventory_notifier.dart` imports `app_database.dart`, so no separate import line is needed.)

- [ ] **Step 2: Analyze**

Run: `cd mobile && fvm dart analyze lib/features/inventory/view/product_form_dialog.dart`
Expected: no errors (warnings about unrelated files are fine).

- [ ] **Step 3: Manual check (deferred to Task 12's full walk-through)** — this dialog can't be meaningfully unit-tested without a widget test harness this project doesn't otherwise use for dialogs; rely on Task 12's manual pass to exercise create/edit/variant validation end-to-end.

- [ ] **Step 4: Commit**

```bash
git add lib/features/inventory/view/product_form_dialog.dart
git commit -m "feat: ProductFormDialog gains a variants editor, drops flat price field"
```

---

## Task 6: `modifier_groups_notifier.dart` — global groups + per-product attach/detach

**Files:**
- Modify: `mobile/lib/features/inventory/state/modifier_groups_notifier.dart`
- Modify: `mobile/test/features/inventory/state/modifier_groups_notifier_test.dart`

- [ ] **Step 1: Rewrite the test**

```dart
// mobile/test/features/inventory/state/modifier_groups_notifier_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/inventory/state/modifier_groups_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int productId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    productId = await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('allModifierGroupsProvider lists global groups with their options', () async {
    final actions = container.read(modifierGroupsManagementActionsProvider);
    await actions.createGroup(name: 'Size', isRequired: true, maxSelections: 1);

    final groups = await container.read(allModifierGroupsProvider.future);
    expect(groups, hasLength(1));
    expect(groups.single.group.name, 'Size');
    expect(groups.single.options, isEmpty);

    await actions.createOption(groupId: groups.single.group.id, name: 'Large', additionalPrice: 20);
    final refreshed = await container.read(allModifierGroupsProvider.future);
    expect(refreshed.single.options, hasLength(1));
  });

  test('toggleGroupActive / toggleOptionActive soft-disable instead of deleting', () async {
    final actions = container.read(modifierGroupsManagementActionsProvider);
    await actions.createGroup(name: 'Size', isRequired: false, maxSelections: 1);
    var groups = await container.read(allModifierGroupsProvider.future);
    final groupId = groups.single.group.id;

    await actions.createOption(groupId: groupId, name: 'Large', additionalPrice: 20);
    groups = await container.read(allModifierGroupsProvider.future);
    final optionId = groups.single.options.single.id;

    await actions.toggleGroupActive(groupId, isActive: false);
    await actions.toggleOptionActive(optionId, isActive: false);

    groups = await container.read(allModifierGroupsProvider.future);
    expect(groups.single.group.isActive, isFalse);
    expect(groups.single.options.single.isActive, isFalse);
  });

  test('attachedModifierGroupsProvider and attach/detach for a specific product', () async {
    final managementActions = container.read(modifierGroupsManagementActionsProvider);
    await managementActions.createGroup(name: 'Size', isRequired: false, maxSelections: 1);
    final groups = await container.read(allModifierGroupsProvider.future);
    final groupId = groups.single.group.id;

    var attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, isEmpty);

    final productActions = container.read(productModifierGroupActionsProvider(productId));
    await productActions.attach(groupId);
    attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, hasLength(1));
    expect(attached.single.id, groupId);

    await productActions.detach(groupId);
    attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && fvm flutter test test/features/inventory/state/modifier_groups_notifier_test.dart`
Expected: FAIL — none of `allModifierGroupsProvider`, `modifierGroupsManagementActionsProvider`, `attachedModifierGroupsProvider`, `productModifierGroupActionsProvider` exist yet.

- [ ] **Step 3: Rewrite `modifier_groups_notifier.dart`**

```dart
// mobile/lib/features/inventory/state/modifier_groups_notifier.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd mobile && fvm flutter test test/features/inventory/state/modifier_groups_notifier_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/state/modifier_groups_notifier.dart test/features/inventory/state/modifier_groups_notifier_test.dart
git commit -m "feat: modifier groups become global with per-product attach/detach state"
```

---

## Task 7: `ModifierGroupFormDialog` / `ModifierOptionFormDialog` — drop per-product scoping

**Files:**
- Modify: `mobile/lib/features/inventory/view/modifier_group_form_dialog.dart`
- Modify: `mobile/lib/features/inventory/view/modifier_option_form_dialog.dart`

- [ ] **Step 1: Rewrite `modifier_group_form_dialog.dart`** — remove `productId`, call the new management actions provider, add an "Active" toggle in edit mode

```dart
// mobile/lib/features/inventory/view/modifier_group_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../state/modifier_groups_notifier.dart';

/// Create/edit dialog for a global modifier group.
///
/// [existing] is `null` for create-mode; passing a [ModifierGroupsTableData]
/// switches to edit-mode.
class ModifierGroupFormDialog extends ConsumerStatefulWidget {
  final ModifierGroupsTableData? existing;

  const ModifierGroupFormDialog({super.key, this.existing});

  @override
  ConsumerState<ModifierGroupFormDialog> createState() => _ModifierGroupFormDialogState();
}

class _ModifierGroupFormDialogState extends ConsumerState<ModifierGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _maxSelectionsController;
  late bool _isRequired;
  String? _errorText;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _maxSelectionsController =
        TextEditingController(text: existing != null ? existing.maxSelections.toString() : '1');
    _isRequired = existing?.isRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxSelectionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final maxSelections = int.parse(_maxSelectionsController.text.trim());

    setState(() => _isSaving = true);
    try {
      final actions = ref.read(modifierGroupsManagementActionsProvider);
      if (_isEditing) {
        await actions.updateGroup(
          groupId: widget.existing!.id,
          name: name,
          isRequired: _isRequired,
          maxSelections: maxSelections,
        );
      } else {
        await actions.createGroup(name: name, isRequired: _isRequired, maxSelections: maxSelections);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Modifier Group' : 'Add Modifier Group'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', errorText: _errorText),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: _maxSelectionsController,
                decoration: const InputDecoration(labelText: 'Max Selections'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Max selections is required';
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const Gap(AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Required'),
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Rewrite `modifier_option_form_dialog.dart`** — remove `productId`

```dart
// mobile/lib/features/inventory/view/modifier_option_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../state/modifier_groups_notifier.dart';

/// Create/edit dialog for a single option belonging to a global modifier group.
///
/// [existing] is `null` for create-mode; passing a [ModifierOptionsTableData]
/// switches to edit-mode.
class ModifierOptionFormDialog extends ConsumerStatefulWidget {
  final int groupId;
  final ModifierOptionsTableData? existing;

  const ModifierOptionFormDialog({super.key, required this.groupId, this.existing});

  @override
  ConsumerState<ModifierOptionFormDialog> createState() => _ModifierOptionFormDialogState();
}

class _ModifierOptionFormDialogState extends ConsumerState<ModifierOptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  String? _errorText;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController =
        TextEditingController(text: existing != null ? _formatPrice(existing.additionalPrice) : '0');
  }

  String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final additionalPrice = double.parse(_priceController.text.trim());

    setState(() => _isSaving = true);
    try {
      final actions = ref.read(modifierGroupsManagementActionsProvider);
      if (_isEditing) {
        await actions.updateOption(optionId: widget.existing!.id, name: name, additionalPrice: additionalPrice);
      } else {
        await actions.createOption(groupId: widget.groupId, name: name, additionalPrice: additionalPrice);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Option' : 'Add Option'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', errorText: _errorText),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Additional Price', prefixText: 'PHP '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Additional price is required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) return 'Enter a valid price (0 or more)';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/inventory/view/modifier_group_form_dialog.dart lib/features/inventory/view/modifier_option_form_dialog.dart
git commit -m "feat: modifier group/option dialogs operate on the global shape"
```

---

## Task 8: `ModifierGroupsManagementScreen` (new — global CRUD surface)

**Files:**
- Create: `mobile/lib/features/inventory/view/modifier_groups_management_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// mobile/lib/features/inventory/view/modifier_groups_management_screen.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/modifier_groups_notifier.dart';
import 'modifier_group_form_dialog.dart';
import 'modifier_option_form_dialog.dart';

/// Global modifier-group management: list every group (active or not) with
/// its options, create/edit groups and options, and soft-disable either via
/// an Active toggle. Add/Edit/toggle actions are hidden for non-admins.
class ModifierGroupsManagementScreen extends ConsumerWidget {
  const ModifierGroupsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allModifierGroupsProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(allModifierGroupsProvider),
      ),
      data: (groups) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: groups.isEmpty
              ? EmptyStateWidget(
                  title: 'No modifier groups yet',
                  subtitle: 'Add a group so it can be attached to any product.',
                  icon: Icons.tune_rounded,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const Gap(AppSpacing.md),
                  itemBuilder: (context, i) => _GroupCard(entry: groups[i], isAdmin: isAdmin),
                ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ModifierGroupFormDialog(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Group'),
                )
              : null,
        );
      },
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final ModifierGroupWithOptions entry;
  final bool isAdmin;
  const _GroupCard({required this.entry, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = entry.group;
    return Opacity(
      opacity: group.isActive ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(group.name, style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${group.isRequired ? 'Required' : 'Optional'} · Max ${group.maxSelections}${group.isActive ? '' : ' · Inactive'}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          trailing: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: 'Edit group',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => ModifierGroupFormDialog(existing: group),
                      ),
                    ),
                    Switch(
                      value: group.isActive,
                      onChanged: (v) => ref
                          .read(modifierGroupsManagementActionsProvider)
                          .toggleGroupActive(group.id, isActive: v),
                    ),
                  ],
                )
              : null,
          children: [
            if (entry.options.isEmpty)
              const Padding(padding: EdgeInsets.only(bottom: AppSpacing.md), child: Text('No options yet'))
            else
              for (final option in entry.options)
                Opacity(
                  opacity: option.isActive ? 1.0 : 0.55,
                  child: ListTile(
                    title: Text(option.name),
                    subtitle: Text('+ PHP ${option.additionalPrice.toStringAsFixed(2)}${option.isActive ? '' : ' · Inactive'}'),
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                tooltip: 'Edit option',
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => ModifierOptionFormDialog(groupId: group.id, existing: option),
                                ),
                              ),
                              Switch(
                                value: option.isActive,
                                onChanged: (v) => ref
                                    .read(modifierGroupsManagementActionsProvider)
                                    .toggleOptionActive(option.id, isActive: v),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => ModifierOptionFormDialog(groupId: group.id),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Option'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd mobile && fvm dart analyze lib/features/inventory/view/modifier_groups_management_screen.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/inventory/view/modifier_groups_management_screen.dart
git commit -m "feat: add global Modifier Groups management screen"
```

---

## Task 9: `ModifierGroupsScreen` (per-product) — rework to attach/detach checklist

**Files:**
- Modify: `mobile/lib/features/inventory/view/modifier_groups_screen.dart`

- [ ] **Step 1: Rewrite the screen**

```dart
// mobile/lib/features/inventory/view/modifier_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/modifier_groups_notifier.dart';

/// Per-product modifier-group attachment: a checklist of every *active*
/// global group, with a switch to attach/detach it to/from this product.
/// Creating a brand-new group is not done here — it deep-links to the
/// global Modifier Groups management tab instead.
class ModifierGroupsScreen extends ConsumerWidget {
  final int productId;
  const ModifierGroupsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupsAsync = ref.watch(allModifierGroupsProvider);
    final attachedAsync = ref.watch(attachedModifierGroupsProvider(productId));
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier Groups'),
        actions: [
          if (isAdmin)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushToModifierGroupsTab();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('New Group', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: allGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (allGroups) {
          final activeGroups = allGroups.where((g) => g.group.isActive).toList();
          if (activeGroups.isEmpty) {
            return EmptyStateWidget(
              title: 'No modifier groups yet',
              subtitle: 'Create one from the Modifier Groups tab, then attach it here.',
              icon: Icons.tune_rounded,
            );
          }
          return attachedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
            data: (attached) {
              final attachedIds = attached.map((g) => g.id).toSet();
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: activeGroups.length,
                separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
                itemBuilder: (context, i) {
                  final entry = activeGroups[i];
                  final isAttached = attachedIds.contains(entry.group.id);
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.group.name, style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                '${entry.group.isRequired ? 'Required' : 'Optional'} · Max ${entry.group.maxSelections} · ${entry.options.length} option(s)',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAttached,
                          onChanged: isAdmin
                              ? (v) {
                                  final actions = ref.read(productModifierGroupActionsProvider(productId));
                                  if (v) {
                                    actions.attach(entry.group.id);
                                  } else {
                                    actions.detach(entry.group.id);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

Note: `context.pushToModifierGroupsTab()` is a placeholder call — Task 10 gives `InventoryScreen` a `TabController`-driven 3-tab shell but tab selection isn't addressable via a route/extension by default. Replace this call with the simpler, always-correct approach: pop back to `/inventory` and let the user tap the "Modifier Groups" tab themselves (the FAB in this screen already deep-links back). Change the `onPressed` above to:

```dart
onPressed: () => Navigator.of(context).pop(),
```

and change the button label to `'Back to Inventory'` — this avoids inventing a nonexistent cross-tab navigation API. If, once Task 10 exists, a `go_router` extra/query-param approach for pre-selecting a tab is wanted, that is a follow-up not required by the spec (the spec only requires that a path back to group-management exists, not deep-linking to a specific tab index).

- [ ] **Step 2: Apply that correction directly** (do this in the same edit, not as a follow-up) — the final action button block should read:

```dart
actions: [
  if (isAdmin)
    TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      label: const Text('Manage Groups', style: TextStyle(color: Colors.white)),
    ),
],
```

- [ ] **Step 3: Analyze**

Run: `cd mobile && fvm dart analyze lib/features/inventory/view/modifier_groups_screen.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/inventory/view/modifier_groups_screen.dart
git commit -m "feat: per-product modifier groups screen becomes an attach/detach checklist"
```

---

## Task 10: `InventoryScreen` — 3-tab shell (Products / Categories / Modifier Groups), remove hard deletes, role gating

**Files:**
- Create: `mobile/lib/features/inventory/view/categories_tab.dart`
- Modify: `mobile/lib/features/inventory/view/inventory_screen.dart`

- [ ] **Step 1: Create `categories_tab.dart`** (extracted from the old `_ManageCategoriesSheet`, now a persistent tab instead of a bottom sheet, with delete replaced by the existing `isActive` toggle and role gating)

```dart
// mobile/lib/features/inventory/view/categories_tab.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/inventory_notifier.dart';
import 'category_form_dialog.dart';

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  late Future<List<ProductGroupsTableData>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    final db = ref.read(databaseProvider);
    _groupsFuture = db.productsDao.getAllGroups();
  }

  Future<void> _refresh() async {
    setState(_loadGroups);
    await _groupsFuture;
    await ref.read(inventoryNotifierProvider.notifier).refresh();
  }

  Future<void> _openAddDialog() async {
    await showDialog<void>(context: context, builder: (_) => const CategoryFormDialog());
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openEditDialog(ProductGroupsTableData group) async {
    await showDialog<void>(context: context, builder: (_) => CategoryFormDialog(existing: group));
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<ProductGroupsTableData>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return EmptyStateWidget(
              title: 'No categories yet',
              subtitle: isAdmin ? 'Tap the + button to add one.' : 'Ask an admin to add one.',
              icon: Icons.category_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
            itemBuilder: (_, i) {
              final g = groups[i];
              return Opacity(
                opacity: g.isActive ? 1.0 : 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: ListTile(
                    title: Text(g.name, style: AppTextStyles.labelLg),
                    subtitle: g.isActive ? null : const Text('Inactive'),
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _openEditDialog(g),
                              ),
                              Switch(
                                value: g.isActive,
                                onChanged: (v) async {
                                  await ref.read(inventoryNotifierProvider.notifier).updateCategory(
                                        id: g.id,
                                        name: g.name,
                                        isActive: v,
                                      );
                                  if (!mounted) return;
                                  await _refresh();
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Category'),
            )
          : null,
    );
  }
}
```

- [ ] **Step 2: Rewrite `inventory_screen.dart`** — 3-tab shell, remove `_ManageCategoriesSheet` and all delete confirm dialogs, add role gating

```dart
// mobile/lib/features/inventory/view/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';
import 'categories_tab.dart';
import 'modifier_groups_management_screen.dart';
import 'product_form_dialog.dart';

class InventoryScreen extends HookConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(inventoryNotifierProvider));
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 3);
    final currentTab = useState(0);
    useEffect(() {
      void listener() => currentTab.value = tabController.index;
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
            Tab(text: 'Modifier Groups'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(inventoryNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          _ProductsTab(),
          CategoriesTab(),
          ModifierGroupsManagementScreen(),
        ],
      ),
      floatingActionButton: currentTab.value == 0 && isAdmin
          ? _ProductsTabFab()
          : null,
    );
  }
}

class _ProductsTabFab extends ConsumerWidget {
  const _ProductsTabFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryNotifierProvider);
    return state.maybeWhen(
      data: (s) => FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => ProductFormDialog(
            groupId: s.selectedGroupId ?? (s.groups.isNotEmpty ? s.groups.first.id : null),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ProductsTab extends HookConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.read(inventoryNotifierProvider.notifier).refresh(),
      ),
      data: (s) => _InventoryBody(state: s),
    );
  }
}

class _InventoryBody extends HookConsumerWidget {
  final InventoryState state;
  const _InventoryBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    if (state.products.isEmpty && state.groups.isEmpty) {
      return EmptyStateWidget(
        title: 'No products yet',
        subtitle: 'Import a products CSV in Settings to get started.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final filtered = state.filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              style: AppTextStyles.bodyLg,
              onChanged: (v) => ref.read(inventoryNotifierProvider.notifier).setSearch(v),
            ),
          ),
        ),
        if (state.groups.isNotEmpty) ...[
          const Gap(AppSpacing.sm),
          _CategoryChips(
            groups: state.groups,
            selectedGroupId: state.selectedGroupId,
            onSelect: (id) => ref.read(inventoryNotifierProvider.notifier).selectGroup(id),
          ),
        ],
        const Gap(AppSpacing.md),
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateWidget(title: 'No products found', subtitle: 'Try a different search or category', icon: Icons.search_off_rounded)
              : _ProductsGrid(products: filtered),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<InventoryGroup> groups;
  final int? selectedGroupId;
  final ValueChanged<int?> onSelect;

  const _CategoryChips({required this.groups, required this.selectedGroupId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length + 1,
        separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(label: 'All', isSelected: selectedGroupId == null, onTap: () => onSelect(null));
          }
          final g = groups[i - 1];
          return _Chip(label: '${g.name} (${g.productCount})', isSelected: selectedGroupId == g.id, onTap: () => onSelect(g.id));
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 1.5),
          boxShadow: isSelected ? [] : [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 4)],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<InventoryProduct> products;
  const _ProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => RepaintBoundary(child: _ProductCard(product: products[i])),
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final InventoryProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(imageUrl: product.imageUrl, groupName: product.group?.name),
                    if (product.group != null)
                      Positioned(left: 8, bottom: 8, child: _Badge(product.group!.name, AppColors.shadow.withValues(alpha: 0.55))),
                    if (!product.isAvailable)
                      Positioned(right: 8, top: 8, child: _Badge('Disabled', AppColors.error)),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text('PHP ${product.price.toStringAsFixed(2)}', style: AppTextStyles.priceMd.copyWith(color: AppColors.primary)),
                      const Spacer(),
                      Row(
                        children: [
                          if (isAdmin)
                            Expanded(
                              child: FilledButton(
                                onPressed: () => ref.read(inventoryNotifierProvider.notifier).toggleAvailability(product),
                                style: FilledButton.styleFrom(
                                  backgroundColor: product.isAvailable
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.success.withValues(alpha: 0.12),
                                  foregroundColor: product.isAvailable ? AppColors.error : AppColors.success,
                                  minimumSize: const Size(0, 36),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(product.isAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 14),
                                    const Gap(4),
                                    Text(product.isAvailable ? 'Disable' : 'Enable', style: AppTextStyles.labelMd),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          if (isAdmin) ...[
                            const Gap(4),
                            _CardIconButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.primary,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ProductFormDialog(existing: product, groupId: product.groupId),
                              ),
                            ),
                          ],
                          const Gap(4),
                          _CardIconButton(
                            icon: Icons.tune_rounded,
                            color: AppColors.secondary,
                            onPressed: () => context.push('/inventory/products/${product.id}/modifiers'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CardIconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? groupName;
  const _ProductImage({this.imageUrl, this.groupName});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (context, e, st) => _Placeholder(groupName: groupName));
    }
    return _Placeholder(groupName: groupName);
  }
}

class _Placeholder extends StatelessWidget {
  final String? groupName;
  const _Placeholder({this.groupName});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(child: Icon(Icons.fastfood_rounded, size: 36, color: AppColors.primary.withValues(alpha: 0.4))),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}
```

Note: `useTabController` comes from `flutter_hooks` (already a dependency, used elsewhere via `HookConsumerWidget`/`flutter_hooks` import) — no new package needed.

- [ ] **Step 3: Analyze**

Run: `cd mobile && fvm dart analyze lib/features/inventory/`
Expected: no errors across the whole feature directory now that Tasks 1–10 are complete.

- [ ] **Step 4: Commit**

```bash
git add lib/features/inventory/view/categories_tab.dart lib/features/inventory/view/inventory_screen.dart
git commit -m "feat: InventoryScreen becomes a 3-tab shell with role-gated actions, no hard deletes"
```

---

## Task 11: `CategoryFormDialog` — confirm it still fits (no changes expected, verify)

**Files:**
- Verify only: `mobile/lib/features/inventory/view/category_form_dialog.dart`

- [ ] **Step 1: Re-read the file and confirm it still compiles against the new `InventoryNotifier`**

`CategoryFormDialog` calls `inventoryNotifierProvider.notifier.createCategory`/`updateCategory`, both of which are unchanged in Task 4's rewrite. No code change is expected here — this step exists to make sure that assumption holds.

Run: `cd mobile && fvm dart analyze lib/features/inventory/view/category_form_dialog.dart`
Expected: no errors. If errors appear, they mean an assumption above was wrong — stop and use `superpowers:systematic-debugging` rather than patching blind.

- [ ] **Step 2: No commit needed** (verification-only task; skip if Step 1 shows no issues).

---

## Task 12: Full test suite + manual verification pass

**Files:** none (verification only)

- [ ] **Step 1: Regenerate drift code once more (safety net) and run the full test suite**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart analyze
fvm flutter test
```

Expected: `flutter analyze` reports no errors (pre-existing unrelated warnings are fine — do not fix those as part of this task). All tests pass, including every file touched in Tasks 1–6.

- [ ] **Step 2: Manual walkthrough on Windows**

Run: `cd mobile && fvm flutter run -d windows`

As an **admin** user:
1. Open Dashboard → Inventory. Confirm three tabs: Products, Categories, Modifier Groups.
2. On Categories: add a category, edit its name, toggle it inactive — confirm it dims but is never removed from the list, and re-enabling it works.
3. On Products: add a product with two variants (mark one default) — confirm it saves and the grid shows the default variant's price.
4. Edit that product: disable the non-default variant via its switch, disable the default variant too, and confirm the app blocks saving with "At least one active variant is required" until you re-enable one.
5. Edit the product again, disable the current default variant only — confirm another active variant is automatically promoted to default.
6. Confirm there is no delete button anywhere for products or categories — only Disable/Enable and Edit.
7. On Modifier Groups: create a group with two options, toggle one option inactive — confirm no delete button exists here either, only toggles.
8. From a product card, tap the tune icon → confirm the per-product screen shows a checklist of active global groups with attach/detach switches, and attaching one here is reflected when you revisit the Modifier Groups tab (same underlying group, still global).
9. Import a CSV from Settings → confirm imported products land with a "Regular" default variant at the CSV's price.

As a **cashier** (non-admin/non-supervisor) user:
1. Open Inventory — confirm the screen still opens (navigation itself is ungated).
2. Confirm no Add/Edit/Disable/toggle-active/attach-detach controls are visible anywhere across all three tabs and the per-product modifiers screen — read-only browsing only.

If any step fails, use `superpowers:systematic-debugging` before patching — do not guess-fix.

- [ ] **Step 3: Report back** — no commit in this step (verification only). If everything passes, the feature is complete; use `superpowers:finishing-a-development-branch` or `superpowers:requesting-code-review` per the user's preference for next steps (this plan does not commit any wrap-up itself).

---

## Self-Review Notes

- **Spec coverage:** Every decision (1–8) and schema/DAO/screen/state/business-rule/CSV section in the design spec maps to a task: schema+migration (Task 1), DAO (Task 2), CSV importer (Task 3), notifier + variant validation rules (Task 4), product form variants editor (Task 5), global modifier-group state (Task 6), group/option dialogs (Task 7), management tab (Task 8), per-product attach/detach (Task 9), 3-tab shell + role gating + no-hard-delete UI (Task 10), verification (Task 12).
- **Placeholder scan:** No "TBD"/"handle appropriately" left in any step; the one spot that could have become a placeholder (cross-tab deep-link from the per-product Modifier Groups screen) was resolved explicitly to a `Navigator.pop` rather than an invented API, with the reasoning stated inline.
- **Type consistency:** `VariantInput`, `InventoryProduct.price` (now variant-derived), `ProductWithPrice`, `ModifierGroupWithOptions`, `allModifierGroupsProvider`/`attachedModifierGroupsProvider`/`modifierGroupsManagementActionsProvider`/`productModifierGroupActionsProvider` names and shapes are used identically across every task that references them (DAO → notifier → screens).
- **Out of scope respected:** no backend/sync layer touched, no stock/quantity tracking added, kiosk itself untouched — matching the spec's explicit exclusions.
