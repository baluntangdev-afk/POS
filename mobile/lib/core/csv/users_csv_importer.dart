import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Expected columns (header row required):
/// name, role, pin
/// role: admin | cashier
/// pin: 6-digit string
class UsersCsvImporter implements CsvImporter {
  final AppDatabase _db;
  const UsersCsvImporter(this._db);

  @override
  Future<ImportResult> importFile(File file) async {
    final rows = _parse(await file.readAsString());
    if (rows.isEmpty) return const ImportResult(successCount: 0, skippedCount: 0, errors: []);

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.skip(1).toList();

    int success = 0, skipped = 0;
    final errors = <CsvRowError>[];

    final existingUsers = await _db.usersDao.getAllActiveUsers();
    final existingNames = existingUsers.map((u) => u.name.toLowerCase()).toSet();

    for (int i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2;
      try {
        final row = _mapRow(headers, dataRows[i]);
        final name = (row['name'] ?? '').toString().trim();
        final role = (row['role'] ?? 'cashier').toString().trim().toLowerCase();
        final pin = (row['pin'] ?? '').toString().trim();

        if (name.isEmpty) {
          errors.add(CsvRowError(rowNum, 'name is required'));
          continue;
        }

        if (role != 'admin' && role != 'cashier') {
          errors.add(CsvRowError(rowNum, 'role must be admin or cashier, got: $role'));
          continue;
        }

        if (pin.length != 6 || int.tryParse(pin) == null) {
          errors.add(CsvRowError(rowNum, 'pin must be 6 digits, got: $pin'));
          continue;
        }

        if (existingNames.contains(name.toLowerCase())) {
          skipped++;
          continue;
        }

        final pinHash = BCrypt.hashpw(pin, BCrypt.gensalt());
        await _db.usersDao.insertUser(
          UsersTableCompanion(
            name: Value(name),
            role: Value(role),
            pinHash: Value(pinHash),
            isActive: const Value(true),
          ),
        );
        existingNames.add(name.toLowerCase());
        success++;
      } catch (e) {
        errors.add(CsvRowError(rowNum, e.toString()));
      }
    }

    return ImportResult(successCount: success, skippedCount: skipped, errors: errors);
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
