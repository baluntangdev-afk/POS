import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Expected columns (header row required, matched by position — header text
/// itself is ignored so minor variations like "Modifler Group" still work):
/// Modifier Group, Modifier Name
///
/// Groups and options are purely global: no product association, price,
/// required flag, or max-selections column. New groups default to
/// single-select/optional (isRequired=false, maxSelections=1); new options
/// default to additionalPrice=0. Re-importing the same file is a no-op for
/// rows whose (group, option name) already exists. A row missing either cell
/// is silently skipped rather than reported as an error.
class ModifiersCsvImporter implements CsvImporter {
  final AppDatabase _db;
  const ModifiersCsvImporter(this._db);

  @override
  Future<ImportResult> importFile(File file) async {
    final rows = _parse(await file.readAsString());
    if (rows.isEmpty) return const ImportResult(successCount: 0, skippedCount: 0, errors: []);

    final dataRows = rows.skip(1).toList();

    final groupCache = <String, int>{};
    final optionNamesCache = <int, Set<String>>{};
    int success = 0;
    int skipped = 0;
    final errors = <CsvRowError>[];

    for (int i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2;
      try {
        final row = dataRows[i];
        final groupName = (row.isNotEmpty ? row[0] : '').toString().trim();
        final optionName = (row.length > 1 ? row[1] : '').toString().trim();

        if (groupName.isEmpty || optionName.isEmpty) {
          skipped++;
          continue;
        }

        if (!groupCache.containsKey(groupName)) {
          final groups = await _db.productsDao.getAllModifierGroups();
          final existing = groups.where((g) => g.name == groupName).firstOrNull;
          final gId = existing?.id ??
              await _db.productsDao.createModifierGroup(
                ModifierGroupsTableCompanion.insert(
                  name: groupName,
                  isRequired: const Value(false),
                  maxSelections: const Value(1),
                ),
              );
          groupCache[groupName] = gId;
        }
        final groupId = groupCache[groupName]!;

        if (!optionNamesCache.containsKey(groupId)) {
          final options = await _db.productsDao.getOptionsForGroup(groupId);
          optionNamesCache[groupId] = options.map((o) => o.name.trim().toLowerCase()).toSet();
        }
        final existingNames = optionNamesCache[groupId]!;
        if (existingNames.contains(optionName.toLowerCase())) {
          skipped++;
          continue;
        }

        await _db.productsDao.insertModifierOption(
          ModifierOptionsTableCompanion.insert(groupId: groupId, name: optionName),
        );
        existingNames.add(optionName.toLowerCase());
        success++;
      } catch (e) {
        errors.add(CsvRowError(rowNum, e.toString()));
      }
    }

    return ImportResult(successCount: success, skippedCount: skipped, errors: errors);
  }

  List<List<dynamic>> _parse(String content) =>
      const CsvToListConverter(eol: '\n').convert(content);
}
