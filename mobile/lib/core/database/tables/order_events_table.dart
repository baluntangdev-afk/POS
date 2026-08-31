import 'package:drift/drift.dart';

/// One row per incoming order, holding its latest known event — later
/// events (`updated`/`cancelled`) overwrite the row `created` made. Not a
/// per-event log, and not the local `sales` ledger this device rings up
/// itself — this is the live feed of orders placed through an external
/// channel (kiosk / storefront) and pushed to this store.
class OrderEventsTable extends Table {
  @override
  String get tableName => 'order_events';

  TextColumn get orderId => text()();
  TextColumn get storeId => text()();
  TextColumn get eventType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // Incremented each time _syncHistory runs; rows with a stale generation that
  // weren't touched by the current sync are swept after the upsert loop.
  IntColumn get syncGeneration => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {orderId};
}
