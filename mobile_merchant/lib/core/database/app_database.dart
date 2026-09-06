import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/merchant_dao.dart';
import 'daos/order_events_dao.dart';
import 'tables/merchant_table.dart';
import 'tables/order_events_table.dart';
import 'tables/order_items_table.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database. Registered with the DI graph by
/// [DatabaseModule].
///
/// Add tables to the `tables:` list below (one `class Xs extends Table` each),
/// bump [schemaVersion], and add an `onUpgrade` branch for every change.
/// Only `data/datasources` should talk to this class — never `domain/`.
@DriftDatabase(tables: [MerchantTable, OrderEventsTable, OrderItemsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for tests.
  @visibleForTesting
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(merchantTable);
          }
          if (from < 3) {
            await m.createTable(orderEventsTable);
            await m.createTable(orderItemsTable);
          }
        },
      );

  MerchantDao get merchantDao => MerchantDao(this);
  OrderEventsDao get orderEventsDao => OrderEventsDao(this);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mobile_merchant.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
