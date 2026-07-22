import 'package:drift/drift.dart';
import 'products_table.dart';

class ModifierGroupsTable extends Table {
  @override
  String get tableName => 'modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
}
