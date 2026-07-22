import 'package:drift/drift.dart';
import 'users_table.dart';

class SalesTable extends Table {
  @override
  String get tableName => 'sales';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(UsersTable, #id)();
  RealColumn get total => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();
}
