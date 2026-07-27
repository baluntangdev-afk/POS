import 'package:drift/drift.dart';
import 'product_groups_table.dart';

class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ProductGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
