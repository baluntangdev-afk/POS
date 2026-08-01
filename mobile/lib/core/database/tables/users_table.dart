import 'package:drift/drift.dart';

class UsersTable extends Table {
  @override
  String get tableName => 'users';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get role => text()();
  TextColumn get pinHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get employeeId => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isPinChanged => boolean().withDefault(const Constant(true))();
}
