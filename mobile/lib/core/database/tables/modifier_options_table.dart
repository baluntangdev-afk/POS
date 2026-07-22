import 'package:drift/drift.dart';
import 'modifier_groups_table.dart';

class ModifierOptionsTable extends Table {
  @override
  String get tableName => 'modifier_options';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ModifierGroupsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();
}
