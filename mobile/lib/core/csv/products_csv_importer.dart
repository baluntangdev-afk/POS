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

        await _db.productsDao.upsertProduct(
          ProductsTableCompanion(
            groupId: Value(groupId),
            name: Value(productName),
            price: Value(price),
            isAvailable: Value(isAvailable),
            imageUrl: imageUrl.isEmpty ? const Value.absent() : Value(imageUrl),
            sortOrder: Value(sortOrder),
          ),
        );
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
