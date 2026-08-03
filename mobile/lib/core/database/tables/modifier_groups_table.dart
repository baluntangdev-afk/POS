import 'package:drift/drift.dart';

class ModifierGroupsTable extends Table {
  @override
  String get tableName => 'modifier_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
