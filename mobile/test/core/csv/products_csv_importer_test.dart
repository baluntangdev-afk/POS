import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/csv/products_csv_importer.dart';

void main() {
  test('importFile creates a default variant per product using the row price', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final tempDir = await Directory.systemTemp.createTemp('csv_import_test');
    addTearDown(() => tempDir.delete(recursive: true));
    final file = File('${tempDir.path}${Platform.pathSeparator}products.csv');
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
