import 'package:drift/drift.dart';
import 'products_table.dart';

class ProductVariantsTable extends Table {
  @override
  String get tableName => 'product_variants';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
