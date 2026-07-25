import 'package:drift/drift.dart';

class XReadingsTable extends Table {
  @override
  String get tableName => 'x_readings';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer()();
  TextColumn get cashierName => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  RealColumn get totalSales => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get voidedCount => integer()();
  IntColumn get refundedCount => integer()();
  TextColumn get paymentBreakdownJson => text()();
  TextColumn get topProductsJson => text()();
}
