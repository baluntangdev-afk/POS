import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/inventory/state/inventory_notifier.dart';

void main() {
  test('createProduct inserts and refreshes the inventory', () async {
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
          price: 100,
          imageUrl: null,
        );

    final state = await container.read(inventoryNotifierProvider.future);
    expect(state.products.any((p) => p.name == 'Latte'), isTrue);
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
          price: 100,
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).createProduct(
            groupId: groupId,
            name: 'latte',
            price: 120,
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
    await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Latte',
          price: 100,
          imageUrl: null,
        );
    var state = await container.read(inventoryNotifierProvider.future);
    final productId = state.products.firstWhere((p) => p.name == 'Latte').id;

    await container.read(inventoryNotifierProvider.notifier).updateProduct(
          id: productId,
          groupId: groupId,
          name: 'Iced Latte',
          price: 120,
          imageUrl: null,
        );

    state = await container.read(inventoryNotifierProvider.future);
    final updated = state.products.firstWhere((p) => p.id == productId);
    expect(updated.name, 'Iced Latte');
    expect(updated.price, 120);
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
          price: 100,
          imageUrl: null,
        );
    await container.read(inventoryNotifierProvider.notifier).createProduct(
          groupId: groupId,
          name: 'Mocha',
          price: 110,
          imageUrl: null,
        );
    final state = await container.read(inventoryNotifierProvider.future);
    final mochaId = state.products.firstWhere((p) => p.name == 'Mocha').id;

    expect(
      () => container.read(inventoryNotifierProvider.notifier).updateProduct(
            id: mochaId,
            groupId: groupId,
            name: 'latte',
            price: 110,
            imageUrl: null,
          ),
      throwsA(anything),
    );
  });

  test('deleteProduct removes it and refreshes', () async {
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
          price: 100,
          imageUrl: null,
        );
    var state = await container.read(inventoryNotifierProvider.future);
    final productId = state.products.firstWhere((p) => p.name == 'Latte').id;

    await container.read(inventoryNotifierProvider.notifier).deleteProduct(productId);

    state = await container.read(inventoryNotifierProvider.future);
    expect(state.products.any((p) => p.id == productId), isFalse);
  });

  test('createCategory, updateCategory and deleteCategory work end to end', () async {
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
    expect(group.name, 'Snacks');

    await container.read(inventoryNotifierProvider.notifier).updateCategory(
          id: group.id,
          name: 'Sweet Snacks',
          isActive: true,
        );
    state = await container.read(inventoryNotifierProvider.future);
    expect(state.groups.firstWhere((g) => g.id == group.id).name, 'Sweet Snacks');

    await container.read(inventoryNotifierProvider.notifier).deleteCategory(group.id);
    state = await container.read(inventoryNotifierProvider.future);
    expect(state.groups.any((g) => g.id == group.id), isFalse);
  });

  test('deleteCategory throws when the category still has products', () async {
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
          price: 100,
          imageUrl: null,
        );

    expect(
      () => container.read(inventoryNotifierProvider.notifier).deleteCategory(groupId),
      throwsA(anything),
    );
  });
}
