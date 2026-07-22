import 'package:drift/drift.dart';
import 'refunds_table.dart';
import 'sale_items_table.dart';

class RefundItemsTable extends Table {
  @override
  String get tableName => 'refund_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get refundId => integer().references(RefundsTable, #id)();
  IntColumn get saleItemId => integer().references(SaleItemsTable, #id)();
  IntColumn get qty => integer()();
  RealColumn get amount => real()();
}
