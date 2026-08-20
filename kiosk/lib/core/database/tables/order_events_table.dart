import 'package:drift/drift.dart';

/// One row per order, holding its latest known event — later events
/// (`updated`/`cancelled`) overwrite the row created by `order.created`.
/// This is what the pending-orders badge counts, not a per-event log.
class OrderEventsTable extends Table {
  @override
  String get tableName => 'order_events';

  TextColumn get orderId => text()();
  TextColumn get kioskId => text()();
  TextColumn get eventType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {orderId};
}
