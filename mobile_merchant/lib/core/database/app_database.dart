import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database. Registered with the DI graph by
/// [DatabaseModule].
///
/// Add tables to the `tables:` list below (one `class Xs extends Table` each),
/// bump [schemaVersion], and add an `onUpgrade` branch for every change.
/// Only `data/datasources` should talk to this class — never `domain/`.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for tests.
  @visibleForTesting
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // if (from < 2) { await m.addColumn(...); }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mobile_merchant.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
