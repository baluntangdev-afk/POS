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
  TextColumn get discountsJson => text().withDefault(const Constant('[]'))();
  RealColumn get totalDiscounts => real().withDefault(const Constant(0.0))();
  RealColumn get vatableSales => real().withDefault(const Constant(0.0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0.0))();
  RealColumn get vatExemptSales => real().withDefault(const Constant(0.0))();
  RealColumn get averageSale => real().withDefault(const Constant(0.0))();
  RealColumn get highestSale => real().withDefault(const Constant(0.0))();
  RealColumn get lowestSale => real().withDefault(const Constant(0.0))();
  RealColumn get cashCollected => real().withDefault(const Constant(0.0))();
  TextColumn get paymentLedgersJson => text().withDefault(const Constant('[]'))();
}
