import 'package:drift/drift.dart';
import 'sales_table.dart';

class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
