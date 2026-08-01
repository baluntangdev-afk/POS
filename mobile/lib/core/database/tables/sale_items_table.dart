import 'package:drift/drift.dart';
import 'sales_table.dart';
import 'products_table.dart';

class SaleItemsTable extends Table {
  @override
  String get tableName => 'sale_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(SalesTable, #id)();
  IntColumn get productId => integer().references(ProductsTable, #id)();
  TextColumn get variantName => text()();
  IntColumn get qty => integer()();
  RealColumn get unitPrice => real()();
  TextColumn get discountType => text().nullable()();
  TextColumn get discountBeneficiaryId => text().nullable()();
  TextColumn get discountBeneficiaryName => text().nullable()();
  RealColumn get discountAmount => real().nullable()();
  RealColumn get vatExemptAmount => real().nullable()();
}
