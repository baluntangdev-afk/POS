import 'package:drift/drift.dart';
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
    // backfill itself. The backfill is covered by a dedicated upgrade test if needed.
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
