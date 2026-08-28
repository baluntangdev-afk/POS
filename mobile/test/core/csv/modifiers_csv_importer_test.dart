import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/csv/modifiers_csv_importer.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('modifiers_csv_import_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<File> writeCsv(String content) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}modifiers.csv');
    await file.writeAsString(content);
    return file;
  }

  test('creates a new group and option with single-select/optional/free defaults', () async {
    final file = await writeCsv(
      'Modifier Group,Modifier Name\n'
      'Flavor,Sour Cream\n',
    );

    final result = await ModifiersCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);

    final groups = await db.productsDao.getAllModifierGroups();
    expect(groups, hasLength(1));
    final group = groups.single;
    expect(group.name, 'Flavor');
    expect(group.isRequired, isFalse);
    expect(group.maxSelections, 1);

    final options = await db.productsDao.getOptionsForGroup(group.id);
    expect(options, hasLength(1));
    expect(options.single.name, 'Sour Cream');
    expect(options.single.additionalPrice, 0);
  });

  test('rows sharing a group name accumulate options under one group', () async {
    final file = await writeCsv(
      'Modifier Group,Modifier Name\n'
      'Flavor,Sour Cream\n'
      'Flavor,Barbeque\n',
    );

    final result = await ModifiersCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 2);

    final groups = await db.productsDao.getAllModifierGroups();
    expect(groups, hasLength(1));

    final options = await db.productsDao.getOptionsForGroup(groups.single.id);
    expect(options.map((o) => o.name), containsAll(['Sour Cream', 'Barbeque']));
  });

  test('re-importing skips options that already exist in the group instead of duplicating',
      () async {
    final file = await writeCsv(
      'Modifier Group,Modifier Name\n'
      'Flavor,Sour Cream\n',
    );
    await ModifiersCsvImporter(db).importFile(file);

    final again = await writeCsv(
      'Modifier Group,Modifier Name\n'
      'Flavor,Sour Cream\n'
      'Flavor,Barbeque\n',
    );
    final result = await ModifiersCsvImporter(db).importFile(again);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1); // Barbeque only
    expect(result.skippedCount, 1); // Sour Cream already existed

    final groups = await db.productsDao.getAllModifierGroups();
    expect(groups, hasLength(1));
    final options = await db.productsDao.getOptionsForGroup(groups.single.id);
    expect(options, hasLength(2));
  });

  test('skips a row with an empty Modifier Name without aborting the file or reporting an error',
      () async {
    final file = await writeCsv(
      'Modifier Group,Modifier Name\n'
      'Flavor,\n'
      'Flavor,Barbeque\n',
    );

    final result = await ModifiersCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);
    expect(result.skippedCount, 1);
  });

  test('skips a row with an empty Modifier Group without aborting the file or reporting an error',
      () async {
    final file = await writeCsv(
      'Modifier Group,Modifier Name\n'
      ',Sour Cream\n'
      'Flavor,Barbeque\n',
    );

    final result = await ModifiersCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);
    expect(result.skippedCount, 1);
  });

  test('tolerates header text variations since columns are matched by position', () async {
    final file = await writeCsv(
      'Modifler Group,Modifier Name\n'
      'Flavor,Sour Cream\n',
    );

    final result = await ModifiersCsvImporter(db).importFile(file);

    expect(result.errors, isEmpty);
    expect(result.successCount, 1);
  });
}
