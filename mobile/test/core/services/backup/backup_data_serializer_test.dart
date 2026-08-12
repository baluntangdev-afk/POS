import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/services/backup/backup_data_serializer.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('dumpAllTables includes every table, populated and empty', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final dump = await BackupDataSerializer.dumpAllTables(db);

    expect(dump.keys, containsAll(kBackupTableOrder));
    expect(dump['product_groups'], hasLength(1));
    expect(dump['product_groups']!.first['name'], 'Drinks');
    expect(dump['products'], hasLength(1));
    expect(dump['products']!.first['name'], 'Latte');
    // A table with no rows still appears, as an empty list.
    expect(dump['sales'], isEmpty);
  });

  test('restoreAllTables replaces existing data with the dumped data', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final dumped = await BackupDataSerializer.dumpAllTables(db);

    await db.customStatement('DELETE FROM products');
    await db.customStatement('DELETE FROM product_groups');

    await BackupDataSerializer.restoreAllTables(db, dumped);

    final groups = await db.customSelect('SELECT * FROM product_groups').get();
    expect(groups, hasLength(1));
    expect(groups.first.data['name'], 'Drinks');
    final products = await db.customSelect('SELECT * FROM products').get();
    expect(products, hasLength(1));
    expect(products.first.data['name'], 'Latte');
  });

  test('restoreAllTables rolls back entirely if any insert fails, leaving prior data intact', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final badData = await BackupDataSerializer.dumpAllTables(db);
    // products.name is NOT NULL — this must fail the insert and roll back
    // the whole transaction, including the deletes that ran before it.
    badData['products']![0]['name'] = null;

    await expectLater(
      BackupDataSerializer.restoreAllTables(db, badData),
      throwsA(anything),
    );

    final groups = await db.customSelect('SELECT * FROM product_groups').get();
    expect(groups, hasLength(1));
    expect(groups.first.data['name'], 'Drinks');
    final products = await db.customSelect('SELECT * FROM products').get();
    expect(products, hasLength(1));
    expect(products.first.data['name'], 'Latte');
  });

  test('hashData is stable for the same dump and changes when data changes', () async {
    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));

    final dump = await BackupDataSerializer.dumpAllTables(db);
    final hashA = BackupDataSerializer.hashData(dump);
    final hashB = BackupDataSerializer.hashData(await BackupDataSerializer.dumpAllTables(db));
    expect(hashA, hashB);

    await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Mocha'));
    final hashAfterChange =
        BackupDataSerializer.hashData(await BackupDataSerializer.dumpAllTables(db));
    expect(hashAfterChange, isNot(hashA));
  });
}
