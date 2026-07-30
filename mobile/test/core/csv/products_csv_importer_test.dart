import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/sale_items_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';
import 'package:mobile/core/csv/products_csv_importer.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('csv_import_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<File> writeCsv(String content) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}products.csv');
    await file.writeAsString(content);
    return file;
  }

  test('single-price product (no Variant Name) gets a default Regular variant', () async {
    final file = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,Cold beverages,Latte,Iced or hot,120,,,\n',
    );

    final importer = ProductsCsvImporter(db);
    final result = await importer.importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);

    final products = await db.productsDao.getAllProducts();
    expect(products, hasLength(1));
    expect(products.single.name, 'Latte');

    final variants = await db.productsDao.getVariantsForProduct(products.single.id);
    expect(variants, hasLength(1));
    expect(variants.single.name, 'Regular');
    expect(variants.single.price, 120);
    expect(variants.single.isDefault, isTrue);
    expect(variants.single.isActive, isTrue);
  });

  test('rows sharing Category + Product Name accumulate into one product with many variants',
      () async {
    final file = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,,Latte,,120,Small,110,\n'
      'Drinks,,Latte,,120,Large,150,\n',
    );

    final result = await ProductsCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);

    final products = await db.productsDao.getAllProducts();
    expect(products, hasLength(1));

    final variants = await db.productsDao.getVariantsForProduct(products.single.id);
    expect(variants, hasLength(2));
    expect(variants.firstWhere((v) => v.name == 'Small').isDefault, isTrue);
    expect(variants.firstWhere((v) => v.name == 'Large').isDefault, isFalse);
  });

  test('accepts the optional Product Image URL column (8 columns)', () async {
    final file = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,,Latte,,120,,,https://example.com/latte.png\n',
    );

    final result = await ProductsCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    final products = await db.productsDao.getAllProducts();
    expect(products.single.imageUrl, 'https://example.com/latte.png');
  });

  test('re-importing updates the existing product and variant instead of duplicating', () async {
    final file = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,,Latte,,120,,,\n',
    );
    await ProductsCsvImporter(db).importFile(file);

    final updated = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,,Latte,,150,,,\n',
    );
    final result = await ProductsCsvImporter(db).importFile(updated);

    expect(result.errors, isEmpty);
    final products = await db.productsDao.getAllProducts();
    expect(products, hasLength(1));
    final variants = await db.productsDao.getVariantsForProduct(products.single.id);
    expect(variants, hasLength(1));
    expect(variants.single.price, 150);
  });

  test('rejects a file whose header does not match the expected format', () async {
    final file = await writeCsv(
      'group_name,product_name,price,is_available,image_url,sort_order\n'
      'Drinks,Latte,120,true,,1\n',
    );

    final result = await ProductsCsvImporter(db).importFile(file);

    expect(result.successCount, 0);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.message, contains('does not match'));
  });

  test('reports a row-level error for a missing Product Name without aborting the file',
      () async {
    final file = await writeCsv(
      '$kProductsCsvHeader\n'
      'Drinks,,,,120,,,\n'
      'Drinks,,Latte,,120,,,\n',
    );

    final result = await ProductsCsvImporter(db).importFile(file);

    expect(result.successCount, 1);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.message, contains('Product Name'));
  });

  group('importCsv summary + modes', () {
    test('upsert mode reports separate inserted/updated counts', () async {
      final first = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,,,\n',
      );
      final firstSummary =
          await ProductsCsvImporter(db).importCsv(first, mode: ProductsCsvImportMode.upsert);
      expect(firstSummary.categoriesInserted, 1);
      expect(firstSummary.productsInserted, 1);
      expect(firstSummary.variantsInserted, 1);

      final second = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,150,,,\n'
        'Drinks,,Mocha,,140,,,\n',
      );
      final secondSummary =
          await ProductsCsvImporter(db).importCsv(second, mode: ProductsCsvImportMode.upsert);
      expect(secondSummary.categoriesUpdated, 1);
      expect(secondSummary.categoriesInserted, 0);
      expect(secondSummary.productsInserted, 1); // Mocha
      expect(secondSummary.productsUpdated, 1); // Latte
      expect(secondSummary.variantsUpdated, 1);
      expect(secondSummary.variantsInserted, 1);
    });

    test('replace mode deletes categories/products/variants missing from the file, not just disables them',
        () async {
      final first = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,Small,110,\n'
        'Drinks,,Latte,,120,Large,150,\n'
        'Snacks,,Fries,,90,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(first, mode: ProductsCsvImportMode.upsert);

      final second = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,Small,110,\n',
      );
      final summary =
          await ProductsCsvImporter(db).importCsv(second, mode: ProductsCsvImportMode.replace);

      expect(summary.categoriesRemoved, 1); // Snacks
      expect(summary.productsRemoved, 1); // Fries
      expect(summary.productsKeptForHistory, 0);
      expect(summary.variantsRemoved, 2); // Latte's Large + Fries's Regular

      final groups = await db.productsDao.getAllGroups();
      expect(groups.where((g) => g.name == 'Snacks'), isEmpty);
      expect(groups.firstWhere((g) => g.name == 'Drinks').isActive, isTrue);

      final products = await db.productsDao.getAllProducts();
      expect(products.where((p) => p.name == 'Fries'), isEmpty);
      final latte = products.firstWhere((p) => p.name == 'Latte');
      expect(latte.isAvailable, isTrue);

      final latteVariants = await db.productsDao.getVariantsForProduct(latte.id);
      expect(latteVariants, hasLength(1));
      expect(latteVariants.single.name, 'Small');
    });

    test('replace mode keeps (but disables) a product with past sale history instead of deleting it',
        () async {
      final withFries = await writeCsv(
        '$kProductsCsvHeader\n'
        'Snacks,,Fries,,90,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(withFries, mode: ProductsCsvImportMode.upsert);

      final fries = (await db.productsDao.getAllProducts()).firstWhere((p) => p.name == 'Fries');
      final cashierId = await db.into(db.usersTable).insert(
            UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
          );
      final saleId = await db.salesDao.insertSale(
        SalesTableCompanion.insert(
          cashierId: cashierId,
          total: 90,
          status: 'completed',
          type: 'dine_in',
          createdAt: DateTime.now(),
        ),
      );
      await db.salesDao.insertSaleItem(
        SaleItemsTableCompanion.insert(
          saleId: saleId,
          productId: fries.id,
          variantName: 'Regular',
          qty: 1,
          unitPrice: 90,
        ),
      );

      final withoutFries = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,,,\n',
      );
      final summary =
          await ProductsCsvImporter(db).importCsv(withoutFries, mode: ProductsCsvImportMode.replace);

      expect(summary.productsRemoved, 0);
      expect(summary.productsKeptForHistory, 1);
      expect(summary.categoriesRemoved, 0); // Snacks kept — Fries still references it

      final products = await db.productsDao.getAllProducts();
      final keptFries = products.firstWhere((p) => p.name == 'Fries');
      expect(keptFries.isAvailable, isFalse);

      final groups = await db.productsDao.getAllGroups();
      expect(groups.firstWhere((g) => g.name == 'Snacks').isActive, isFalse);
    });

    test('replace mode still hard-deletes a product\'s variants even when the product itself '
        'is kept for sale history', () async {
      final withFries = await writeCsv(
        '$kProductsCsvHeader\n'
        'Snacks,,Fries,,90,Small,80,\n'
        'Snacks,,Fries,,90,Large,110,\n',
      );
      await ProductsCsvImporter(db).importCsv(withFries, mode: ProductsCsvImportMode.upsert);

      final fries = (await db.productsDao.getAllProducts()).firstWhere((p) => p.name == 'Fries');
      final cashierId = await db.into(db.usersTable).insert(
            UsersTableCompanion.insert(name: 'Cashier', role: 'cashier', pinHash: 'hash'),
          );
      final saleId = await db.salesDao.insertSale(
        SalesTableCompanion.insert(
          cashierId: cashierId,
          total: 80,
          status: 'completed',
          type: 'dine_in',
          createdAt: DateTime.now(),
        ),
      );
      await db.salesDao.insertSaleItem(
        SaleItemsTableCompanion.insert(
          saleId: saleId,
          productId: fries.id,
          variantName: 'Small',
          qty: 1,
          unitPrice: 80,
        ),
      );

      final withoutFries = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(withoutFries, mode: ProductsCsvImportMode.replace);

      final variants = await db.productsDao.getVariantsForProduct(fries.id);
      expect(variants, isEmpty);
    });

    test('re-importing after a hard delete creates a fresh row rather than reviving the old one',
        () async {
      final withSnacks = await writeCsv(
        '$kProductsCsvHeader\n'
        'Snacks,,Fries,,90,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(withSnacks, mode: ProductsCsvImportMode.upsert);
      final originalFries =
          (await db.productsDao.getAllProducts()).firstWhere((p) => p.name == 'Fries');

      final withoutSnacks = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(withoutSnacks, mode: ProductsCsvImportMode.replace);

      final backAgain = await writeCsv(
        '$kProductsCsvHeader\n'
        'Drinks,,Latte,,120,,,\n'
        'Snacks,,Fries,,90,,,\n',
      );
      await ProductsCsvImporter(db).importCsv(backAgain, mode: ProductsCsvImportMode.upsert);

      final groups = await db.productsDao.getAllGroups();
      expect(groups.firstWhere((g) => g.name == 'Snacks').isActive, isTrue);

      final newFries = (await db.productsDao.getAllProducts()).firstWhere((p) => p.name == 'Fries');
      expect(newFries.id, isNot(originalFries.id));
    });
  });
}
