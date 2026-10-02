import 'package:drift/drift.dart';

enum CartivoSyncStatus { idle, syncing, failed }

class CartivoSyncStateTable extends Table {
  @override
  String get tableName => 'cartivo_sync_state';

  TextColumn get merchantId => text()();
  DateTimeColumn get watermark => dateTime().nullable()();
  DateTimeColumn get lastFullSyncAt => dateTime().nullable()();
  TextColumn get status => textEnum<CartivoSyncStatus>()
      .withDefault(Constant(CartivoSyncStatus.idle.name))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {merchantId};
}
