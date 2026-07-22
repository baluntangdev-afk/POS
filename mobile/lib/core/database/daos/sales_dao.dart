import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';
import '../tables/sale_items_table.dart';
import '../tables/sale_item_modifiers_table.dart';
import '../tables/payments_table.dart';
import '../tables/refunds_table.dart';
import '../tables/refund_items_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  SalesTable,
  SaleItemsTable,
  SaleItemModifiersTable,
  PaymentsTable,
  RefundsTable,
  RefundItemsTable,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Future<int> insertSale(SalesTableCompanion companion) =>
      into(salesTable).insert(companion);

  Future<int> insertSaleItem(SaleItemsTableCompanion companion) =>
      into(saleItemsTable).insert(companion);

  Future<int> insertSaleItemModifier(SaleItemModifiersTableCompanion companion) =>
      into(saleItemModifiersTable).insert(companion);

  Future<int> insertPayment(PaymentsTableCompanion companion) =>
      into(paymentsTable).insert(companion);

  Future<int> insertRefund(RefundsTableCompanion companion) =>
      into(refundsTable).insert(companion);

  Future<int> insertRefundItem(RefundItemsTableCompanion companion) =>
      into(refundItemsTable).insert(companion);

  Future<int> voidSale(int saleId) =>
      (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(const SalesTableCompanion(status: Value('voided')));

  Future<List<SalesTableData>> getSalesByDateRange(DateTime from, DateTime to) =>
      (select(salesTable)
            ..where((t) => t.createdAt.isBetweenValues(from, to))
            ..where((t) => t.status.equals('completed'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<SalesTableData?> getSaleById(int id) =>
      (select(salesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SaleItemsTableData>> getItemsForSale(int saleId) =>
      (select(saleItemsTable)..where((t) => t.saleId.equals(saleId))).get();

  Future<List<PaymentsTableData>> getPaymentsForSale(int saleId) =>
      (select(paymentsTable)..where((t) => t.saleId.equals(saleId))).get();

  Future<List<SalesTableData>> getRecentSales({int limit = 50}) =>
      (select(salesTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<double> getTotalSalesForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total), 0) as sum FROM sales '
      'WHERE created_at BETWEEN ? AND ? AND status = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<double>('sum');
  }

  Future<int> getTransactionCountForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM sales WHERE created_at BETWEEN ? AND ? AND status = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<int>('cnt');
  }

  Future<List<Map<String, Object?>>> getPaymentBreakdown(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT p.method, COALESCE(SUM(p.amount), 0) as total '
      'FROM payments p JOIN sales s ON s.id = p.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY p.method',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).get();
    return rows.map((r) => <String, Object?>{
      'method': r.read<String>('method'),
      'total': r.read<double>('total'),
    }).toList();
  }

  Future<List<Map<String, Object?>>> getTopProducts(DateTime from, DateTime to, {int limit = 5}) async {
    final rows = await customSelect(
      'SELECT p.name, SUM(si.qty) as qty, SUM(si.qty * si.unit_price) as amount '
      'FROM sale_items si '
      'JOIN products p ON p.id = si.product_id '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY p.id, p.name ORDER BY amount DESC LIMIT ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(limit),
      ],
    ).get();
    return rows.map((r) => <String, Object?>{
      'name': r.read<String>('name'),
      'qty': r.read<int>('qty'),
      'amount': r.read<double>('amount'),
    }).toList();
  }
}
