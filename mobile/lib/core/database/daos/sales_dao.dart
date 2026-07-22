import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';
import '../tables/sale_items_table.dart';
import '../tables/sale_item_modifiers_table.dart';
import '../tables/payments_table.dart';
import '../tables/refunds_table.dart';
import '../tables/refund_items_table.dart';
import '../tables/users_table.dart';
import '../tables/products_table.dart';
import '../../features/transactions/entities/transaction_summary.dart';
import '../../features/transactions/entities/history_receipt_data.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [
  SalesTable,
  SaleItemsTable,
  SaleItemModifiersTable,
  PaymentsTable,
  RefundsTable,
  RefundItemsTable,
  UsersTable,
  ProductsTable,
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

  Future<List<TransactionSummary>> getTransactions({
    DateTime? date,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final q = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);

    if (date != null) {
      final from = DateTime(date.year, date.month, date.day);
      final to = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      q.where(salesTable.createdAt.isBetweenValues(from, to));
    }

    final searchId = int.tryParse((search ?? '').replaceAll('#', ''));
    if (searchId != null) q.where(salesTable.id.equals(searchId));

    q.orderBy([OrderingTerm.desc(salesTable.createdAt)]);
    q.limit(limit, offset: offset);

    final rows = await q.get();
    final saleIds = rows.map((r) => r.readTable(salesTable).id).toList();
    final refundedByIds = await _refundedAmountsBySaleIds(saleIds);

    return rows.map((row) {
      final sale = row.readTable(salesTable);
      final user = row.readTableOrNull(usersTable);
      return TransactionSummary(
        id: sale.id,
        cashierName: user?.name ?? 'Unknown',
        createdAt: sale.createdAt,
        total: sale.total,
        discount: sale.discount,
        status: sale.status,
        type: sale.type,
        refundedAmount: refundedByIds[sale.id] ?? 0,
      );
    }).toList();
  }

  Future<Map<int, double>> _refundedAmountsBySaleIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final refunds = await (select(refundsTable)
          ..where((t) => t.saleId.isIn(ids)))
        .get();
    final map = <int, double>{};
    for (final r in refunds) {
      map[r.saleId] = (map[r.saleId] ?? 0) + r.total;
    }
    return map;
  }

  Future<int> getTransactionCount({DateTime? date, String? search}) async {
    final q = selectOnly(salesTable)..addColumns([salesTable.id.count()]);

    if (date != null) {
      final from = DateTime(date.year, date.month, date.day);
      final to = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      q.where(salesTable.createdAt.isBetweenValues(from, to));
    }

    final searchId = int.tryParse((search ?? '').replaceAll('#', ''));
    if (searchId != null) q.where(salesTable.id.equals(searchId));

    final row = await q.getSingle();
    return row.read(salesTable.id.count()) ?? 0;
  }

  Future<HistoryReceiptData?> getHistoryReceipt(int saleId) async {
    // Sale + cashier name
    final saleQ = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);
    saleQ.where(salesTable.id.equals(saleId));
    final saleRow = await saleQ.getSingleOrNull();
    if (saleRow == null) return null;

    final sale = saleRow.readTable(salesTable);
    final user = saleRow.readTableOrNull(usersTable);

    // Items + product names
    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    final items = <HistoryReceiptItem>[];
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final mods = await (select(saleItemModifiersTable)
            ..where((t) => t.itemId.equals(item.id)))
          .get();
      items.add(HistoryReceiptItem(
        saleItemId: item.id,
        productName: product?.name ?? 'Unknown Product',
        qty: item.qty,
        unitPrice: item.unitPrice,
        modifiers: mods.map((m) => m.modifierName).toList(),
      ));
    }

    // Payment
    final payments = await (select(paymentsTable)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
    final payment = payments.isEmpty ? null : payments.first;

    final subtotal = items.fold(0.0, (s, i) => s + i.lineTotal);
    final total = sale.total - sale.discount;
    final amountPaid = payment?.amount ?? 0;
    final change = payment?.method == 'cash'
        ? (amountPaid - total).clamp(0.0, double.infinity)
        : 0.0;

    return HistoryReceiptData(
      saleId: sale.id,
      createdAt: sale.createdAt,
      saleType: sale.type,
      cashierName: user?.name ?? 'Unknown',
      items: items,
      subtotal: subtotal,
      discount: sale.discount,
      total: total,
      paymentMethod: payment?.method ?? 'cash',
      amountPaid: amountPaid,
      change: change,
      reference: payment?.reference,
    );
  }

  Future<List<HistoryReceiptItem>> getRefundableItems(int saleId) async {
    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    // Get already-refunded qty per sale item
    final refunds = await (select(refundsTable)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
    final refundedQty = <int, int>{};
    for (final r in refunds) {
      final ris = await (select(refundItemsTable)
            ..where((t) => t.refundId.equals(r.id)))
          .get();
      for (final ri in ris) {
        refundedQty[ri.saleItemId] = (refundedQty[ri.saleItemId] ?? 0) + ri.qty;
      }
    }

    final result = <HistoryReceiptItem>[];
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final alreadyRefunded = refundedQty[item.id] ?? 0;
      final available = item.qty - alreadyRefunded;
      if (available <= 0) continue;
      result.add(HistoryReceiptItem(
        saleItemId: item.id,
        productName: product?.name ?? 'Unknown Product',
        qty: available,
        unitPrice: item.unitPrice,
        modifiers: const [],
      ));
    }
    return result;
  }
}
