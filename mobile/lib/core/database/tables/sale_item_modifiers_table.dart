import 'package:drift/drift.dart';
import 'sale_items_table.dart';

class SaleItemModifiersTable extends Table {
  @override
  String get tableName => 'sale_item_modifiers';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(SaleItemsTable, #id)();
  TextColumn get modifierName => text()();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();
}
