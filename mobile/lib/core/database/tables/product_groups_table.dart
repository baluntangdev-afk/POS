import 'package:drift/drift.dart';

class ProductGroupsTable extends Table {
  @override
  String get tableName => 'product_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
