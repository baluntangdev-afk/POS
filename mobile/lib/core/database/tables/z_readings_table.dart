import 'package:drift/drift.dart';

class ZReadingsTable extends Table {
  @override
  String get tableName => 'z_readings';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get zCounter => integer()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  IntColumn get closedByUserId => integer()();
  TextColumn get closedByName => text()();
  IntColumn get authorizedByUserId => integer()();
  TextColumn get authorizedByName => text()();
  RealColumn get beginningBalance => real()();
  RealColumn get endingBalance => real()();
  RealColumn get totalSales => real()();
  RealColumn get vatableSales => real()();
  RealColumn get vatAmount => real()();
  RealColumn get vatExemptSales => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get completedCount => integer()();
  IntColumn get voidedCount => integer()();
  IntColumn get refundedCount => integer()();
  RealColumn get discountTotal => real()();
  RealColumn get cashCollected => real()();
  IntColumn get totalQtySold => integer()();
  TextColumn get paymentBreakdownJson => text()();
  TextColumn get salesByCashierJson => text()();
  TextColumn get discountsJson => text().withDefault(const Constant('[]'))();
  TextColumn get paymentLedgersJson => text().withDefault(const Constant('[]'))();
}
