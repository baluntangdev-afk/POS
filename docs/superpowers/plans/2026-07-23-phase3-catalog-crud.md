# Phase 3 — Catalog CRUD (Products, Categories, Modifier Groups) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let mobile create, edit, and delete products, categories (product groups), and modifier groups/options in the field, instead of being CSV-import/read-only. Existing CSV import continues to work unchanged (bulk seed); new CRUD forms handle one-off field edits.

**Architecture:** Mobile keeps its existing schema shape — no restructuring toward kiosk's richer model (kiosk's own modifier-group CRUD is entirely unimplemented `// TODO` stubs, so there's no working reference to port for that reshaping, and it would be speculative schema churn). Add missing `delete*`/`update*` DAO methods to `ProductsDao`. Add dialogs (`AlertDialog`-based forms, mirroring kiosk's `SaveProductDialog`/`SaveCategoryDialog` UX shape but adapted to mobile's actual columns) wired into `CatalogNotifier` (extended with create/update/delete methods) and `CatalogScreen` (add FAB + edit/delete affordances per card). A new `ModifierGroupsScreen` (per-product) is added since mobile currently has zero UI for modifier groups at all. Image picking reuses the already-present `file_picker` dependency (`FileType.image`) rather than adding `image_picker` — avoids a new dependency for one picker call. Picked images are copied into the app's documents directory (`path_provider`, already a transitive dependency) and the resulting local file path is stored in `imageUrl`; rendering checks whether the string starts with `http` (network, from CSV import) or is a local path (`Image.file`).

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), `go_router`, Drift (sqlite), `file_picker` (existing dep), `path_provider` (existing transitive dep).

---

## Design Decisions (made without a user round-trip — lower-stakes than Phase 2's audit-trail question, documented here for review)

1. **No schema expansion to match kiosk's fuller model.** Kiosk's `CatalogCategory` has `description`/`imageUrl`, its `CatalogModifierGroup` has `description`/`selectionType`/`minSelections`, its `CatalogModifier` has `isAvailable`/`sortOrder` — none of these exist on mobile's tables, and kiosk's own dialogs for modifier groups are unimplemented stubs, so there's no working UX to faithfully port for the richer fields. This plan builds CRUD for the columns mobile's schema **already has**. If richer fields are wanted later, that's a follow-up migration, not blocking basic CRUD now.
2. **Modifier groups stay 1:1 with a single product** (mobile's existing `modifier_groups_table.productId` foreign key), not reusable-across-products like kiosk. Restructuring to a shared-groups model would need a junction table and is out of scope — YAGNI without a concrete requirement driving it.
3. **Image picking:** reuse `file_picker`'s `FileType.image` (already a dependency, already used for CSV) instead of adding the `image_picker` package kiosk uses — one dependency, one pattern, avoids duplicating "pick a file" mechanisms in the app.
4. **Image storage:** copy the picked file into `(await getApplicationDocumentsDirectory()).path/product_images/<uuid>.<ext>` and store that path string in `imageUrl`. Rendering: `imageUrl!.startsWith('http') ? Image.network(imageUrl!) : Image.file(File(imageUrl!))` — this keeps existing CSV-imported network-URL products working unchanged while supporting newly-picked local images.

---

## Task 1: `ProductsDao` — missing delete/update methods + name-uniqueness/lookup helpers

**Files:**
- Modify: `mobile/lib/core/database/daos/products_dao.dart`
- Test: `mobile/test/core/database/daos/products_dao_crud_test.dart`

Current `ProductsDao` (confirmed via research) has insert/upsert for products and product-groups, insert-only for modifier groups/options, and zero delete methods anywhere. Add what's missing.

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/core/database/daos/products_dao_crud_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/modifier_groups_table.dart';
import 'package:mobile/core/database/tables/modifier_options_table.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('deleteProduct removes the product and its modifier groups/options', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));
    final modGroupId = await db.productsDao.insertModifierGroup(
        ModifierGroupsTableCompanion.insert(productId: productId, name: 'Size'));
    await db.productsDao.insertModifierOption(
        ModifierOptionsTableCompanion.insert(groupId: modGroupId, name: 'Large'));

    await db.productsDao.deleteProduct(productId);

    expect(await db.productsDao.getProductById(productId), isNull);
    expect(await db.productsDao.getModifierGroupsForProduct(productId), isEmpty);
  });

  test('deleteProductGroup fails when the group still has products (foreign key)', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));

    expect(
      () => db.productsDao.deleteProductGroup(groupId),
      throwsA(anything),
    );
  });

  test('deleteProductGroup succeeds when the group has no products', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Empty Group'));
    await db.productsDao.deleteProductGroup(groupId);
    expect(await db.productsDao.getGroupById(groupId), isNull);
  });

  test('deleteModifierGroup removes the group and its options', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));
    final modGroupId = await db.productsDao.insertModifierGroup(
        ModifierGroupsTableCompanion.insert(productId: productId, name: 'Size'));
    await db.productsDao.insertModifierOption(
        ModifierOptionsTableCompanion.insert(groupId: modGroupId, name: 'Large'));

    await db.productsDao.deleteModifierGroup(modGroupId);

    expect(await db.productsDao.getOptionsForGroup(modGroupId), isEmpty);
  });

  test('deleteModifierOption removes just that option', () async {
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));
    final productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));
    final modGroupId = await db.productsDao.insertModifierGroup(
        ModifierGroupsTableCompanion.insert(productId: productId, name: 'Size'));
    final optionId = await db.productsDao.insertModifierOption(
        ModifierOptionsTableCompanion.insert(groupId: modGroupId, name: 'Large'));

    await db.productsDao.deleteModifierOption(optionId);

    expect(await db.productsDao.getOptionsForGroup(modGroupId), isEmpty);
  });

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
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));

    expect(await db.productsDao.isProductNameTaken(groupId, 'latte'), isTrue);
    expect(await db.productsDao.isProductNameTaken(groupId, 'Latte', excludeId: null), isTrue);
    expect(await db.productsDao.isProductNameTaken(groupId, 'Mocha'), isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/core/database/daos/products_dao_crud_test.dart`
Expected: FAIL — none of the new methods exist.

- [ ] **Step 3: Add the new methods to `ProductsDao`**

Add after the existing `toggleProductAvailability` method:

```dart
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

  Future<int> deleteProductGroup(int groupId) =>
      (delete(productGroupsTable)..where((t) => t.id.equals(groupId))).go();

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
          if (sortOrder != null) sortOrder: Value(sortOrder),
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
```

**Note on `deleteProductGroup` and the foreign-key test:** `ProductsTable.groupId` has `.references(ProductGroupsTable, #id)()` (confirmed from research) — Drift/sqlite enforces this FK at the database level IF foreign keys are pragma-enabled on the connection. Check `mobile/lib/core/database/app_database.dart`'s `NativeDatabase`/connection setup for `PRAGMA foreign_keys = ON` (Drift's `NativeDatabase` enables FK enforcement by default via `NativeDatabase.createInBackground`/`.memory()` — confirm which constructor mobile actually uses and whether FK enforcement is genuinely active; if the test `deleteProductGroup fails when the group still has products` does NOT throw, FK enforcement is off and the plan's assumption is wrong — in that case, change `deleteProductGroup` to explicitly check `getProductsByGroup(groupId)` first and throw a clear `StateError('Cannot delete a category that still has products')` instead of relying on DB-level FK enforcement, and update the test to match. Verify this empirically, don't assume).

- [ ] **Step 4: Run tests to verify they pass (adjust `deleteProductGroup` per the FK note above if needed)**

Run: `cd mobile && flutter test test/core/database/daos/products_dao_crud_test.dart`
Expected: PASS (all 7 tests)

---

## Task 2: Image storage service (pick + copy to local storage)

**Files:**
- Create: `mobile/lib/core/services/image_storage_service.dart`
- Modify: `mobile/pubspec.yaml` (no new dependency — confirm `file_picker` and transitive `path_provider` are sufficient; do NOT add `image_picker`)
- Test: `mobile/test/core/services/image_storage_service_test.dart`

```dart
// mobile/lib/core/services/image_storage_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract final class ImageStorageService {
  static Future<String?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return null;
    return storeFile(File(path));
  }

  static Future<String> storeFile(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir.path, fileName);
    await source.copy(destPath);
    return destPath;
  }

  static bool isNetworkUrl(String imageUrl) =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
}
```

Check `mobile/pubspec.yaml` for a `path` package dependency (used for `p.join`/`p.extension`) — `path` is nearly always present transitively in Flutter projects (pulled in by `flutter_test`/many packages); confirm it's resolvable, and if genuinely absent from `pubspec.yaml`'s direct dependencies, add `path: ^1.9.0` (a tiny, extremely stable, dependency-free utility package — not a meaningful new dependency risk, unlike a picker/plugin package).

- [ ] **Step 1: Write the failing test**

```dart
// mobile/test/core/services/image_storage_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/image_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_storage_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('storeFile copies the source into product_images/ and returns the new path', () async {
    final source = File('${tempDir.path}/source.png')..writeAsStringSync('fake-image-bytes');

    final storedPath = await ImageStorageService.storeFile(source);

    expect(await File(storedPath).exists(), isTrue);
    expect(storedPath, contains('product_images'));
    expect(await File(storedPath).readAsString(), 'fake-image-bytes');
  });

  test('isNetworkUrl distinguishes http(s) URLs from local paths', () {
    expect(ImageStorageService.isNetworkUrl('https://example.com/a.png'), isTrue);
    expect(ImageStorageService.isNetworkUrl('http://example.com/a.png'), isTrue);
    expect(ImageStorageService.isNetworkUrl('/data/user/0/app/files/product_images/x.png'), isFalse);
  });
}
```

**Note for implementer:** verify `path_provider_platform_interface` and `plugin_platform_interface` are already transitive dev-resolvable (they almost certainly are, as `path_provider`'s own platform-interface package) — if `flutter pub get`/`dart analyze` can't resolve the import, add `path_provider_platform_interface: ^2.1.2` to `dev_dependencies` in `pubspec.yaml` (a test-only fake-platform dependency, not a runtime risk).

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/core/services/image_storage_service_test.dart`
Expected: FAIL — `image_storage_service.dart` doesn't exist.

- [ ] **Step 3: Implement `ImageStorageService`** (code above)

- [ ] **Step 4: Run test to verify it passes**

Run: `cd mobile && flutter test test/core/services/image_storage_service_test.dart`
Expected: PASS

---

## Task 3: `CatalogNotifier` — create/update/delete for products

**Files:**
- Modify: `mobile/lib/features/catalog/state/catalog_notifier.dart`
- Modify: `mobile/lib/features/catalog/entities/catalog_product.dart` (if `CatalogProduct` needs new fields reflected — check current shape first, likely just needs to stay in sync with `ProductsTableData`'s existing columns, no new fields needed per Design Decision #1)
- Test: `mobile/test/features/catalog/state/catalog_notifier_crud_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/features/catalog/state/catalog_notifier_crud_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/catalog/state/catalog_notifier.dart';

void main() {
  test('createProduct inserts and refreshes the catalog', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() { container.dispose(); db.close(); });

    await container.read(catalogProvider.future);
    await container.read(catalogProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          price: 100,
          imageUrl: null,
        );

    final state = await container.read(catalogProvider.future);
    expect(state.products.any((p) => p.name == 'Latte'), isTrue);
  });

  test('createProduct rejects a duplicate name within the same group', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() { container.dispose(); db.close(); });

    await container.read(catalogProvider.future);
    await container.read(catalogProvider.notifier).createProduct(
          groupId: groupId, name: 'Latte', price: 100, imageUrl: null,
        );

    expect(
      () => container.read(catalogProvider.notifier).createProduct(
            groupId: groupId, name: 'latte', price: 120, imageUrl: null,
          ),
      throwsA(anything),
    );
  });

  test('updateProduct changes fields and refreshes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() { container.dispose(); db.close(); });

    await container.read(catalogProvider.future);
    await container.read(catalogProvider.notifier).createProduct(
          groupId: groupId, name: 'Latte', price: 100, imageUrl: null,
        );
    var state = await container.read(catalogProvider.future);
    final productId = state.products.firstWhere((p) => p.name == 'Latte').id;

    await container.read(catalogProvider.notifier).updateProduct(
          id: productId, groupId: groupId, name: 'Iced Latte', price: 120, imageUrl: null,
        );

    state = await container.read(catalogProvider.future);
    final updated = state.products.firstWhere((p) => p.id == productId);
    expect(updated.name, 'Iced Latte');
    expect(updated.price, 120);
  });

  test('deleteProduct removes it and refreshes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = await db.productsDao.insertProductGroup(
        ProductGroupsTableCompanion.insert(name: 'Drinks'));

    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() { container.dispose(); db.close(); });

    await container.read(catalogProvider.future);
    await container.read(catalogProvider.notifier).createProduct(
          groupId: groupId, name: 'Latte', price: 100, imageUrl: null,
        );
    var state = await container.read(catalogProvider.future);
    final productId = state.products.firstWhere((p) => p.name == 'Latte').id;

    await container.read(catalogProvider.notifier).deleteProduct(productId);

    state = await container.read(catalogProvider.future);
    expect(state.products.any((p) => p.id == productId), isFalse);
  });

  test('createCategory and deleteCategory work end to end', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() { container.dispose(); db.close(); });

    await container.read(catalogProvider.future);
    await container.read(catalogProvider.notifier).createCategory(name: 'Snacks');

    var state = await container.read(catalogProvider.future);
    final group = state.groups.firstWhere((g) => g.name == 'Snacks');
    expect(group.name, 'Snacks');

    await container.read(catalogProvider.notifier).deleteCategory(group.id);
    state = await container.read(catalogProvider.future);
    expect(state.groups.any((g) => g.id == group.id), isFalse);
  });
}
```

**IMPORTANT — read `mobile/lib/features/catalog/state/catalog_notifier.dart` and `entities/catalog_product.dart` FIRST** before writing/adapting this test — the plan's field names above (`CatalogState.products`/`.groups`, `CatalogGroup.name`/`.id`) are based on the research report's summary, not a byte-for-byte read; confirm exact field/getter names on the real `CatalogState`/`CatalogGroup`/`CatalogProduct` classes and adjust the test to match rather than guessing wrong and chasing compile errors.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/catalog/state/catalog_notifier_crud_test.dart`
Expected: FAIL — new methods don't exist on `CatalogNotifier`.

- [ ] **Step 3: Add methods to `CatalogNotifier`**

```dart
  Future<void> createProduct({
    required int groupId,
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    await db.productsDao.insertProduct(ProductsTableCompanion.insert(
      groupId: groupId,
      name: name,
      price: price,
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  Future<void> updateProduct({
    required int id,
    required int groupId,
    required String name,
    required double price,
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
      price: Value(price),
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  Future<void> deleteProduct(int id) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.deleteProduct(id);
    await refresh();
  }

  Future<void> createCategory({required String name}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
    await refresh();
  }

  Future<void> updateCategory({required int id, required String name, required bool isActive}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.updateProductGroup(id, name: name, isActive: isActive);
    await refresh();
  }

  Future<void> deleteCategory(int id) async {
    final db = ref.read(databaseProvider);
    final productsInGroup = await db.productsDao.getProductsByGroup(id);
    if (productsInGroup.isNotEmpty) {
      throw StateError('Cannot delete a category that still has products in it');
    }
    await db.productsDao.deleteProductGroup(id);
    await refresh();
  }
```

Adapt exactly to the real `CatalogNotifier`'s existing `refresh()`/`build()`/state-update conventions (confirmed pattern: `AsyncValue.guard` around a `_load()`-equivalent) — read the file first, don't paste blind if the real method names differ from `refresh()`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/catalog/state/catalog_notifier_crud_test.dart`
Expected: PASS (all 5 tests)

---

## Task 4: Product create/edit dialog + wiring into `CatalogScreen`

**Files:**
- Create: `mobile/lib/features/catalog/view/product_form_dialog.dart`
- Modify: `mobile/lib/features/catalog/view/catalog_screen.dart`

`ProductFormDialog` (`ConsumerStatefulWidget`, takes an optional `ProductsTableData? existing` — null means "create", non-null means "edit"): form fields — name (`TextFormField`, required), category (`DropdownButtonFormField<int>` populated from `catalogProvider`'s groups), price (`TextFormField`, numeric, required, > 0), image (a row showing current image thumbnail if any + "Choose Image"/"Change Image"/"Remove" buttons calling `ImageStorageService.pickAndStore()`). On submit: calls `createProduct`/`updateProduct` on `catalogProvider.notifier`, catches the `StateError` thrown for duplicate names and shows it as a form validation error (not a crash/snackbar-only — surface it inline near the name field if straightforward, otherwise a snackbar is acceptable).

In `catalog_screen.dart`: add a `FloatingActionButton` (only when a specific category filter is active, or always visible with the dialog defaulting to the currently-selected category if any — implementer's choice, keep simple) opening `ProductFormDialog()` for create; add an edit icon button and a delete icon button (with confirm dialog, mirroring `RefundScreen`'s/`TransactionDetailScreen`'s existing confirm-dialog pattern from earlier phases) to each `_ProductCard`.

- [ ] **Step 1: Read `catalog_screen.dart` and `catalog_notifier.dart` in full to confirm exact current widget/state shapes before editing.**
- [ ] **Step 2: Build `ProductFormDialog`.**
- [ ] **Step 3: Wire FAB + edit/delete actions into `CatalogScreen`.**
- [ ] **Step 4: Manually verify `dart analyze` is clean; no automated UI test required for this dialog beyond the already-tested notifier layer (per established project pattern — Phase 1/2 also left pure-UI wiring to manual verification once the underlying notifier was tested).**

---

## Task 5: Category create/edit dialog + wiring

**Files:**
- Create: `mobile/lib/features/catalog/view/category_form_dialog.dart`
- Modify: `mobile/lib/features/catalog/view/catalog_screen.dart`

`CategoryFormDialog` (optional `ProductGroupsTableData? existing`): fields — name (required), active (`Switch`, default true, only shown/relevant when editing — a brand new category is always active). On submit: `createCategory`/`updateCategory`. Wire a "Manage Categories" entry point (e.g. a new icon button in `CatalogScreen`'s app bar, or a small bottom-sheet list of category chips each with edit/delete icons) — since the category filter chips already exist in `CatalogScreen`, the simplest integration is adding a small edit/delete affordance to each chip (e.g. long-press opens a menu, or a dedicated "Manage" screen/dialog listing all categories with edit/delete — implementer's choice, prefer the simpler one given this is a lower-traffic admin action).

- [ ] **Step 1: Read current category-chip rendering code in `catalog_screen.dart`.**
- [ ] **Step 2: Build `CategoryFormDialog`.**
- [ ] **Step 3: Wire create/edit/delete entry points.**
- [ ] **Step 4: `dart analyze` clean.**

---

## Task 6: Modifier groups screen (new — mobile currently has zero UI for this)

**Files:**
- Create: `mobile/lib/features/catalog/view/modifier_groups_screen.dart`
- Create: `mobile/lib/features/catalog/view/modifier_group_form_dialog.dart`
- Create: `mobile/lib/features/catalog/view/modifier_option_form_dialog.dart`
- Modify: `mobile/lib/core/navigation/router.dart` (add `/catalog/products/:id/modifiers` nested route)
- Modify: `mobile/lib/features/catalog/view/catalog_screen.dart` (add a "Modifiers" icon button per product card, navigating to the new route)

Since modifier groups are 1:1-owned by a single product (per Design Decision #2), this screen is scoped to one `productId`, listing that product's modifier groups (each expandable to show/edit/delete its options), with a FAB to add a new group. Fetch via `db.productsDao.getModifierGroupsForProduct(productId)` + `getOptionsForGroup(groupId)` per group — build a small dedicated notifier (`ModifierGroupsNotifier extends AsyncNotifier<List<ModifierGroupWithOptions>>`, family-scoped by `productId`, where `ModifierGroupWithOptions` is a tiny local record/class pairing a `ModifierGroupsTableData` with its `List<ModifierOptionsTableData>`) rather than bolting this onto the already-large `CatalogNotifier` — this is a genuinely separate concern (per-product modifier management, not catalog browsing).

`ModifierGroupFormDialog`: name (required), isRequired (`Switch`), maxSelections (numeric, required, ≥ 1). Calls new `productsDao.insertModifierGroup`/`updateModifierGroup`.
`ModifierOptionFormDialog`: name (required), additionalPrice (numeric, default 0, can be negative for a discount-modifier if that's a real use case — otherwise validate ≥ 0, implementer's judgment, default to ≥ 0 unless evidence suggests negative modifiers are needed). Calls `insertModifierOption`/`updateModifierOption`.
Delete actions on both groups and options use the confirm-dialog pattern already established elsewhere in the app.

- [ ] **Step 1: Write a failing test for the new `ModifierGroupsNotifier`** (`mobile/test/features/catalog/state/modifier_groups_notifier_test.dart` — seed a product + a modifier group + an option, assert the notifier returns them paired correctly; a second test calls a `createGroup`/`deleteGroup`/`createOption`/`deleteOption` method and asserts state updates).
- [ ] **Step 2: Confirm it fails, implement `ModifierGroupsNotifier`, confirm it passes.**
- [ ] **Step 3: Build `ModifierGroupsScreen`, `ModifierGroupFormDialog`, `ModifierOptionFormDialog`.**
- [ ] **Step 4: Wire router + catalog card action.**
- [ ] **Step 5: `dart analyze` clean across the whole `catalog` feature + router.**

---

## Task 7: Manual verification pass for Phase 3

- [ ] **Step 1: Run full mobile test suite** — `cd mobile && fvm flutter test` — all pass except the known pre-existing unrelated `widget_test.dart` failure.
- [ ] **Step 2: Run the app and walk the golden path:**
  1. Dashboard → Inventory (Catalog). Create a new category, create a new product in it (with and without a picked image), confirm both appear.
  2. Edit the product's name/price/image, confirm changes persist and render correctly (test both a CSV-imported network-image product and a newly-picked local-image product to confirm `Image.network`/`Image.file` branch correctly).
  3. Try deleting a category that still has products — confirm it's blocked with a clear message, not a crash.
  4. Delete the product, then delete the now-empty category — confirm both succeed.
  5. Open a product's Modifiers screen, add a modifier group with two options, edit one option's price, delete the other, then delete the whole group.
  6. Re-run CSV import for products — confirm it still works unchanged (no regression from the new CRUD methods sharing the same DAO).

If any step fails, use `superpowers:systematic-debugging` before patching.

---

## Self-Review Notes

- **Spec coverage:** Parent plan's Phase 3 bullet ("adds insert/update/delete methods to ProductsDao, then create/edit dialogs mirroring kiosk's, wired into catalog_screen.dart... decide whether CSV import and manual CRUD should coexist (yes) and whether product images need a picker (yes, decided: file_picker + local copy, not image_picker)") is fully covered by Tasks 1-6.
- **No blind trust in memory-only claims:** Task 1 explicitly requires verifying FK-enforcement behavior empirically rather than assuming it; Task 3 explicitly requires reading the real `CatalogNotifier`/entity files before adapting the plan's sketch test.
- **Known scope decision, not a gap:** modifier groups remain per-product (not shared across products like kiosk) — kiosk has no working CRUD reference for the shared model anyway, so this isn't a regression from parity, it's the only reasonable scope given the reference implementation is itself incomplete.
