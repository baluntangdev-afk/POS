import 'package:drift/drift.dart';

import 'cartivo_products_table.dart';

class CartivoProductVariantsTable extends Table {
  @override
  String get tableName => 'cartivo_product_variants';

  IntColumn get variantId => integer()();
  IntColumn get productId =>
      integer().references(CartivoProductsTable, #productId)();
  TextColumn get sku => text()();
  TextColumn get variantName => text()();
  RealColumn get price => real()();
  IntColumn get availableQuantity => integer()();
  BoolColumn get isAvailable => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {variantId};
}
