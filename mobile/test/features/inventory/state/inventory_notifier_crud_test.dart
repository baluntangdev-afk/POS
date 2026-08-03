import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
