import 'package:drift/drift.dart';

import 'order_events_table.dart';

class OrderItemsTable extends Table {
  @override
  String get tableName => 'order_items';

  IntColumn get id => integer().autoIncrement()();

  // Foreign key to order_events.id — cascade-deleting is handled manually in
  // the DAO transaction so we keep the constraint declaration only.
  IntColumn get eventId =>
      integer().references(OrderEventsTable, #id)();

  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();
}
