import 'package:drift/drift.dart';

class DailyReportsTable extends Table {
  @override
  String get tableName => 'daily_reports';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer()();
  TextColumn get cashierName => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  RealColumn get grossSales => real()();
  RealColumn get vatableSales => real()();
  RealColumn get vatAmount => real()();
  RealColumn get vatExemptSales => real()();
  RealColumn get netOfTax => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get totalQtySold => integer()();
  RealColumn get cashSalesTotal => real()();
  IntColumn get cashSalesCount => integer()();
  TextColumn get salesByProductJson => text()();
  TextColumn get cashLedgerJson => text()();
}
