import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Expected columns (header row required):
/// key, value
///
/// Recognized keys: store_name, address, tax_rate, currency, receipt_footer
class StoreInfoCsvImporter implements CsvImporter {
  final AppDatabase _db;
  const StoreInfoCsvImporter(this._db);

  @override
  Future<ImportResult> importFile(File file) async {
    final rows = const CsvToListConverter(eol: '\n').convert(await file.readAsString());
    if (rows.isEmpty) return const ImportResult(successCount: 0, skippedCount: 0, errors: []);

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.skip(1).toList();

    final keyIdx = headers.indexOf('key');
    final valIdx = headers.indexOf('value');

    if (keyIdx == -1 || valIdx == -1) {
      return const ImportResult(
        successCount: 0,
        skippedCount: 0,
        errors: [CsvRowError(1, 'Missing "key" or "value" column headers')],
      );
    }

    final kvMap = <String, String>{};
    final errors = <CsvRowError>[];

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.length <= valIdx) {
        errors.add(CsvRowError(i + 2, 'Row too short'));
        continue;
      }
      final key = row[keyIdx].toString().trim().toLowerCase();
      final value = row[valIdx].toString().trim();
      if (key.isEmpty) continue;
      kvMap[key] = value;
    }

    final companion = StoreInfoTableCompanion(
      storeName: kvMap.containsKey('store_name') ? Value(kvMap['store_name']!) : const Value.absent(),
      address: kvMap.containsKey('address') ? Value(kvMap['address']!) : const Value.absent(),
      taxRate: kvMap.containsKey('tax_rate')
          ? Value(double.tryParse(kvMap['tax_rate']!) ?? 0.0)
          : const Value.absent(),
      currency: kvMap.containsKey('currency') ? Value(kvMap['currency']!) : const Value.absent(),
      receiptFooter: kvMap.containsKey('receipt_footer')
          ? Value(kvMap['receipt_footer']!)
          : const Value.absent(),
    );

    await _db.storeInfoDao.upsertStoreInfo(companion);

    return ImportResult(successCount: kvMap.length, skippedCount: 0, errors: errors);
  }
}
