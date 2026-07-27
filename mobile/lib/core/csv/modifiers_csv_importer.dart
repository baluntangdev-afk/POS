import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Expected columns (header row required):
/// product_name, group_name, is_required, max_selections, option_name, additional_price
class ModifiersCsvImporter implements CsvImporter {
  final AppDatabase _db;
  const ModifiersCsvImporter(this._db);

  @override
  Future<ImportResult> importFile(File file) async {
    final rows = _parse(await file.readAsString());
    if (rows.isEmpty) return const ImportResult(successCount: 0, skippedCount: 0, errors: []);

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.skip(1).toList();

    final productCache = <String, int?>{};
    final groupCache = <String, int>{};
    int success = 0;
    final errors = <CsvRowError>[];

    for (int i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2;
      try {
        final row = _mapRow(headers, dataRows[i]);
        final productName = (row['product_name'] ?? '').toString().trim();
        final groupName = (row['group_name'] ?? '').toString().trim();
        final optionName = (row['option_name'] ?? '').toString().trim();

        if (productName.isEmpty || groupName.isEmpty || optionName.isEmpty) {
          errors.add(CsvRowError(rowNum, 'product_name, group_name, option_name are required'));
          continue;
        }

        if (!productCache.containsKey(productName)) {
          final products = await _db.productsDao.getAllProducts();
          productCache[productName] = products.where((p) => p.name == productName).firstOrNull?.id;
        }
        final productId = productCache[productName];
        if (productId == null) {
          errors.add(CsvRowError(rowNum, 'Product not found: $productName — import products first'));
          continue;
        }

        // Modifier groups are global (shared across products), keyed by name alone.
        if (!groupCache.containsKey(groupName)) {
          final groups = await _db.productsDao.getAllModifierGroups();
          final existing = groups.where((g) => g.name == groupName).firstOrNull;
          final gId = existing?.id ?? await _db.productsDao.createModifierGroup(
            ModifierGroupsTableCompanion(
              name: Value(groupName),
              isRequired: Value((row['is_required'] ?? 'false').toString().toLowerCase() == 'true'),
              maxSelections: Value(int.tryParse((row['max_selections'] ?? '1').toString()) ?? 1),
            ),
          );
          groupCache[groupName] = gId;
        }
        final modGroupId = groupCache[groupName]!;
        await _db.productsDao.attachModifierGroupToProduct(productId, modGroupId);

        final additionalPrice = double.tryParse((row['additional_price'] ?? '0').toString()) ?? 0.0;
        await _db.productsDao.insertModifierOption(
          ModifierOptionsTableCompanion(
            groupId: Value(modGroupId),
            name: Value(optionName),
            additionalPrice: Value(additionalPrice),
          ),
        );
        success++;
      } catch (e) {
        errors.add(CsvRowError(rowNum, e.toString()));
      }
    }

    return ImportResult(successCount: success, skippedCount: 0, errors: errors);
  }

  List<List<dynamic>> _parse(String content) =>
      const CsvToListConverter(eol: '\n').convert(content);

  Map<String, dynamic> _mapRow(List<String> headers, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i] : null;
    }
    return map;
  }
}
