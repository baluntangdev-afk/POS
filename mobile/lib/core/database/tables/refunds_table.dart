import 'package:drift/drift.dart';
import 'sales_table.dart';

class RefundsTable extends Table {
  @override
  String get tableName => 'refunds';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  TextColumn get reason => text()();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get refundNumber => text().nullable()();
  TextColumn get method => text().withDefault(const Constant('Cash Refund'))();
}
