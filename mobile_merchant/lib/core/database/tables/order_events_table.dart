import 'package:drift/drift.dart';

class OrderEventsTable extends Table {
  @override
  String get tableName => 'order_events';

  // Remote numeric ID — used as both PK and pagination cursor (no AUTOINCREMENT).
  IntColumn get id => integer()();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get eventId => text()();
  TextColumn get eventType => text()();
  TextColumn get receivedAt => text()();
  TextColumn get createdAt => text()();

  // Embedded OrderData fields -------------------------------------------------
  TextColumn get merchantId => text()();
  TextColumn get orderId => text()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerEmail => text().nullable()();
  TextColumn get orderStatus => text()();
  RealColumn get orderTotal => real()();
  TextColumn get currency => text()();
  TextColumn get orderCreatedAt => text()();
  TextColumn get orderUpdatedAt => text()();
}
