import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

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

  test('deleteProductGroup fails when the group still has products (application-level check; sqlite FK enforcement is off in this connection)', () async {
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
