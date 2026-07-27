import 'package:drift/drift.dart' hide isNull;
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
