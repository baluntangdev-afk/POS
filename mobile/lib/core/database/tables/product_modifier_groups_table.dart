import 'package:drift/drift.dart';
import 'products_table.dart';
import 'modifier_groups_table.dart';

class ProductModifierGroupsTable extends Table {
  @override
  String get tableName => 'product_modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  IntColumn get modifierGroupId => integer().references(ModifierGroupsTable, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {productId, modifierGroupId},
      ];
}
