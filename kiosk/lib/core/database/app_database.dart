import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'daos/order_events_dao.dart';
import 'tables/order_events_table.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [OrderEventsTable], daos: [OrderEventsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'kiosk_pos'));

  // Bumped while `OrderEventsTable` was still being shaped during initial
  // development (from a per-event log to one row per order). No shipped
  // installs depend on the old shape, so upgrading just recreates the
  // table rather than migrating data.
  //
  // v3: `OrderData` (stored as JSON in `payload`) gained required
  // `created_at`/`updated_at`/etc. fields — rows written before that change
  // fail to parse back via `OrderData.fromJson`. Table shape is unchanged,
  // but the cached payloads are stale, so wipe them the same way.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.deleteTable(orderEventsTable.actualTableName);
        await m.createTable(orderEventsTable);
      }
    },
  );
}
