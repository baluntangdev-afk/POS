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
import '../tables/product_groups_table.dart';
import '../../../features/transactions/entities/transaction_summary.dart';
import '../../../features/reports/entities/report_data.dart';
import '../../../features/ordering/entities/discount.dart';
import '../../../features/ordering/entities/receipt.dart';
import '../../../features/ordering/entities/receipt_item.dart';
import '../../../features/ordering/entities/refund.dart';
import '../../../features/ordering/entities/refund_item.dart';
import '../../../features/ordering/entities/sale.dart';
import '../../../features/ordering/entities/sale_payment.dart';

part 'sales_dao.g.dart';

class StatusCounts {
  final int completed;
  final int voided;
  final int refunded;
  const StatusCounts({required this.completed, required this.voided, required this.refunded});
}

class CashierSales {
  final String cashierName;
  final double total;
  final int transactionCount;
  const CashierSales({required this.cashierName, required this.total, required this.transactionCount});
}

class CashLedgerRow {
  final DateTime date;
  final double total;
  const CashLedgerRow({required this.date, required this.total});
}

class CashLedgerEntryRow {
  final DateTime time;
  final String? reference;
  final double amount;
  const CashLedgerEntryRow({required this.time, required this.reference, required this.amount});
}

class ProductGroupSales {
  final String groupName;
  final double total;
  const ProductGroupSales({required this.groupName, required this.total});
}

class TimeSeriesPoint {
  final String bucketLabel;
  final double total;
  const TimeSeriesPoint({required this.bucketLabel, required this.total});
}

@DriftAccessor(tables: [
  SalesTable,
  SaleItemsTable,
  SaleItemModifiersTable,
  PaymentsTable,
  RefundsTable,
  RefundItemsTable,
  UsersTable,
  ProductsTable,
  ProductGroupsTable,
])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  // TODO: replace with a per-terminal/store code once multi-terminal support lands.
  static const _terminalCode = '001';

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

  Future<int> insertPendingSale({required int cashierId, required Sale sale}) {
    return transaction(() async {
      final saleId = await insertSale(SalesTableCompanion.insert(
        cashierId: cashierId,
        total: sale.total,
        discount: Value(sale.totalDiscount),
        status: 'pending',
        type: sale.type,
        createdAt: sale.createdAt,
      ));

      for (final item in sale.items) {
        final discount = item.discount;
        final itemId = await insertSaleItem(SaleItemsTableCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          variantName: item.variantName,
          qty: item.quantity,
          unitPrice: item.unitPrice,
          discountType: Value(discount?.code),
          discountBeneficiaryId: Value(
            discount is SeniorPwdDiscount ? discount.beneficiaryId : null,
          ),
          discountBeneficiaryName: Value(
            discount is SeniorPwdDiscount ? discount.beneficiaryName : null,
          ),
          discountAmount: Value(discount != null ? item.discountAmount : null),
          vatExemptAmount: Value(
            discount != null && discount.isVatExempt ? item.lineSubtotal.vatAmount : null,
          ),
        ));
        for (final group in item.modifiers) {
          for (final opt in group.selected) {
            await insertSaleItemModifier(SaleItemModifiersTableCompanion.insert(
              itemId: itemId,
              modifierName: '${group.groupName}: ${opt.name}',
              additionalPrice: Value(opt.additionalPrice),
            ));
          }
        }
      }

      if (sale.payment != null) {
        await insertPayment(PaymentsTableCompanion.insert(
          saleId: saleId,
          method: sale.payment!.method,
          amount: sale.payment!.amountPaid,
          cashReceived: Value(sale.payment!.cashReceived),
          reference: Value(sale.payment!.reference),
          createdAt: sale.createdAt,
        ));
      }

      final soNumber = await _generateSoNumber(sale.createdAt);
      await (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(SalesTableCompanion(soNumber: Value(soNumber)));

      return saleId;
    });
  }

  /// Builds a SO-{terminalCode}-{year}-{sequence} number, where sequence is
  /// the count of sales already created in that year (yearly reset).
  /// Must be called after the sale row has been inserted, within the same
  /// transaction, so the count includes it.
  Future<String> _generateSoNumber(DateTime createdAt) async {
    final year = createdAt.year;
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year + 1);
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM sales WHERE created_at >= ? AND created_at < ?',
      variables: [
        Variable.withDateTime(yearStart),
        Variable.withDateTime(yearEnd),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    final sequence = result.read<int>('cnt');
    return 'SO-$_terminalCode-$year-${sequence.toString().padLeft(4, '0')}';
  }

  Future<void> completeSale(int saleId) =>
      (update(salesTable)..where((t) => t.id.equals(saleId)))
          .write(const SalesTableCompanion(status: Value('completed')));

  Future<int> insertRefundRecord({
    required int saleId,
    required String reason,
    required String method,
    required double total,
    required List<({int saleItemId, int qty, double amount})> items,
  }) {
    return transaction(() async {
      final refundId = await insertRefund(RefundsTableCompanion.insert(
        saleId: saleId,
        reason: reason,
        total: total,
        createdAt: DateTime.now(),
        method: Value(method),
      ));
      for (final item in items) {
        await insertRefundItem(RefundItemsTableCompanion.insert(
          refundId: refundId,
          saleItemId: item.saleItemId,
          qty: item.qty,
          amount: item.amount,
        ));
      }

      final refundNumber = 'RF-${refundId.toString().padLeft(6, '0')}';
      await (update(refundsTable)..where((t) => t.id.equals(refundId)))
          .write(RefundsTableCompanion(refundNumber: Value(refundNumber)));

      final remaining = await getRefundableItems(saleId);
      if (remaining.isEmpty) {
        await (update(salesTable)..where((t) => t.id.equals(saleId)))
            .write(const SalesTableCompanion(status: Value('refunded')));
      }

      return refundId;
    });
  }

  Future<Receipt?> getReceiptById(int saleId) async {
    final saleQ = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);
    saleQ.where(salesTable.id.equals(saleId));
    final saleRow = await saleQ.getSingleOrNull();
    if (saleRow == null) return null;

    final sale = saleRow.readTable(salesTable);
    final user = saleRow.readTableOrNull(usersTable);

    final itemQ = select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ]);
    itemQ.where(saleItemsTable.saleId.equals(saleId));
    final itemRows = await itemQ.get();

    final receiptItems = <ReceiptItem>[];
    var sequence = 1;
    for (final ir in itemRows) {
      final item = ir.readTable(saleItemsTable);
      final product = ir.readTableOrNull(productsTable);
      final grossAmount = item.qty * item.unitPrice;
      final itemDiscountAmount = item.discountAmount ?? 0;
      final itemVatExemptAmount = item.vatExemptAmount ?? 0;
      final itemTotal = itemVatExemptAmount > 0
          ? grossAmount.vatExclusiveAmount - itemDiscountAmount
          : grossAmount - itemDiscountAmount;
      final productName = product?.name ?? 'Unknown Product';
      final description = item.variantName.isEmpty
          ? productName
          : '$productName (${item.variantName})';
      receiptItems.add(ReceiptItem(
        id: item.id,
        sequence: sequence,
        description: description,
        quantity: item.qty,
        unitPrice: item.unitPrice,
        grossAmount: grossAmount,
        discountAmount: itemDiscountAmount,
        totalAmount: itemTotal,
        isMain: true,
        discountType: item.discountType,
        discountBeneficiaryId: item.discountBeneficiaryId,
        discountBeneficiaryName: item.discountBeneficiaryName,
        vatExemptAmount: item.vatExemptAmount ?? 0,
      ));

      final mods = await (select(saleItemModifiersTable)
            ..where((t) => t.itemId.equals(item.id)))
          .get();
      for (final mod in mods) {
        final modGross = mod.additionalPrice * item.qty;
        final modTotal =
            itemVatExemptAmount > 0 ? modGross.vatExclusiveAmount : modGross;
        receiptItems.add(ReceiptItem(
          id: -mod.id,
          sequence: sequence,
          description: mod.modifierName,
          quantity: item.qty,
          unitPrice: mod.additionalPrice,
          grossAmount: modGross,
          discountAmount: 0,
          totalAmount: modTotal,
          isMain: false,
          vatExemptAmount: itemVatExemptAmount > 0 ? modGross.vatAmount : 0,
        ));
      }
      sequence++;
    }

    final payments = await (select(paymentsTable)..where((t) => t.saleId.equals(saleId))).get();
    final paymentRow = payments.isEmpty ? null : payments.first;
    final payment = SalePayment(
      method: paymentRow?.method ?? 'cash',
      amountPaid: paymentRow?.amount ?? sale.total,
      cashReceived: paymentRow?.cashReceived ?? paymentRow?.amount ?? sale.total,
      reference: paymentRow?.reference,
    );

    final refundRows = await (select(refundsTable)..where((t) => t.saleId.equals(saleId))).get();
    final refunds = <Refund>[];
    for (final r in refundRows) {
      final riRows =
          await (select(refundItemsTable)..where((t) => t.refundId.equals(r.id))).get();
      final refundItems = <RefundItem>[];
      for (final ri in riRows) {
        final match = receiptItems.firstWhere(
          (rItem) => rItem.isMain && rItem.id == ri.saleItemId,
          orElse: () => ReceiptItem(
            id: ri.saleItemId,
            sequence: 0,
            description: 'Unknown Item',
            quantity: ri.qty,
            unitPrice: 0,
            grossAmount: 0,
            discountAmount: 0,
            totalAmount: 0,
            isMain: true,
          ),
        );
        refundItems.add(RefundItem(
          id: ri.id,
          receiptItemId: ri.saleItemId,
          sequence: match.sequence,
          description: match.description,
          quantity: ri.qty,
          refundAmount: ri.amount,
          isMain: true,
        ));
      }
      refunds.add(Refund(
        id: r.id,
        docNumber: r.refundNumber ?? 'RF-${r.id.toString().padLeft(6, '0')}',
        docDate: r.createdAt,
        receiptId: saleId,
        reason: r.reason,
        method: r.method,
        items: refundItems,
      ));
    }

    final voidCutoff = await attachedDatabase.cashierAccountingDao.getVoidLockCutoff(sale.cashierId);

    return Receipt(
      id: sale.id,
      cashierId: sale.cashierId,
      storeName: '',
      cashierName: user?.name ?? 'Unknown',
      docNumber: sale.soNumber ?? 'SO-${sale.id.toString().padLeft(6, '0')}',
      docDate: sale.createdAt,
      type: sale.type,
      payment: payment,
      items: receiptItems,
      refunds: refunds,
      isVoided: sale.status == 'voided',
      voidReason: sale.voidReason,
      voidLocked: sale.status != 'voided' && sale.createdAt.isBefore(voidCutoff),
    );
  }

  Future<void> recordRefund({
    required int saleId,
    required double total,
    required List<({int saleItemId, int qty})> items,
    String reason = 'Refund',
  }) async {
    await transaction(() async {
      final refundable = await getRefundableItems(saleId);
      final refundableQty = {
        for (final r in refundable) r.saleItemId: r.qty,
      };
      for (final item in items) {
        final available = refundableQty[item.saleItemId] ?? 0;
        if (item.qty > available) {
          throw ArgumentError(
            'Cannot refund qty ${item.qty} for sale item ${item.saleItemId}: '
            'only $available remaining',
          );
        }
      }

      final refundId = await insertRefund(
        RefundsTableCompanion.insert(
          saleId: saleId,
          reason: reason,
          total: total,
          createdAt: DateTime.now(),
        ),
      );
      for (final item in items) {
        final saleItem = await (select(saleItemsTable)
              ..where((t) => t.id.equals(item.saleItemId)))
            .getSingle();
        await insertRefundItem(
          RefundItemsTableCompanion.insert(
            refundId: refundId,
            saleItemId: item.saleItemId,
            qty: item.qty,
            amount: saleItem.unitPrice * item.qty,
          ),
        );
      }

      final remaining = await getRefundableItems(saleId);
      if (remaining.isEmpty) {
        await (update(salesTable)..where((t) => t.id.equals(saleId)))
            .write(const SalesTableCompanion(status: Value('refunded')));
      }
    });
  }

  Future<int> voidSale(int saleId, {String reason = 'Voided by cashier'}) =>
      (update(salesTable)..where((t) => t.id.equals(saleId))).write(
        SalesTableCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
          voidedAt: Value(DateTime.now()),
        ),
      );

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

  Future<StatusCounts> getStatusCountsForDateRange(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT status, COUNT(*) as cnt FROM sales WHERE created_at BETWEEN ? AND ? GROUP BY status',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {salesTable},
    ).get();
    var completed = 0, voided = 0, refunded = 0;
    for (final row in rows) {
      final status = row.read<String>('status');
      final cnt = row.read<int>('cnt');
      switch (status) {
        case 'completed':
          completed = cnt;
        case 'voided':
          voided = cnt;
        case 'refunded':
          refunded = cnt;
      }
    }
    return StatusCounts(completed: completed, voided: voided, refunded: refunded);
  }

  Future<double> getTotalSalesForDateRangeAndCashier(DateTime from, DateTime to, int cashierId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total), 0) as sum FROM sales '
      'WHERE created_at BETWEEN ? AND ? AND status = ? AND cashier_id = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<double>('sum');
  }

  /// The earliest transaction (any status) within [from, to] store-wide, or
  /// null if none exists — used to display the true start of a report period
  /// instead of the internal query lower bound (which may be a synthetic
  /// epoch/last-close boundary with no transaction actually at that time).
  Future<DateTime?> getEarliestTransactionDate(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT MIN(created_at) as min_date FROM sales WHERE created_at BETWEEN ? AND ?',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<DateTime?>('min_date');
  }

  /// Same as [getEarliestTransactionDate], scoped to a single cashier.
  Future<DateTime?> getEarliestTransactionDateForCashier(DateTime from, DateTime to, int cashierId) async {
    final result = await customSelect(
      'SELECT MIN(created_at) as min_date FROM sales WHERE created_at BETWEEN ? AND ? AND cashier_id = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<DateTime?>('min_date');
  }

  Future<int> getTransactionCountForDateRangeAndCashier(DateTime from, DateTime to, int cashierId) async {
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM sales WHERE created_at BETWEEN ? AND ? AND status = ? AND cashier_id = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return result.read<int>('cnt');
  }

  Future<StatusCounts> getStatusCountsForDateRangeAndCashier(DateTime from, DateTime to, int cashierId) async {
    final rows = await customSelect(
      'SELECT status, COUNT(*) as cnt FROM sales WHERE created_at BETWEEN ? AND ? AND cashier_id = ? GROUP BY status',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).get();
    var completed = 0, voided = 0, refunded = 0;
    for (final row in rows) {
      final status = row.read<String>('status');
      final cnt = row.read<int>('cnt');
      switch (status) {
        case 'completed':
          completed = cnt;
        case 'voided':
          voided = cnt;
        case 'refunded':
          refunded = cnt;
      }
    }
    return StatusCounts(completed: completed, voided: voided, refunded: refunded);
  }

  Future<List<Map<String, Object?>>> getPaymentBreakdownForCashier(DateTime from, DateTime to, int cashierId) async {
    final rows = await customSelect(
      'SELECT p.method, COALESCE(SUM(p.amount), 0) as total '
      'FROM payments p JOIN sales s ON s.id = p.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ? '
      'GROUP BY p.method',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).get();
    return rows.map((r) => <String, Object?>{
      'method': r.read<String>('method'),
      'total': r.read<double>('total'),
    }).toList();
  }

  Future<List<Map<String, Object?>>> getTopProductsForCashier(
    DateTime from,
    DateTime to,
    int cashierId, {
    int limit = 5,
  }) async {
    final rows = await customSelect(
      'SELECT p.name, SUM(si.qty) as qty, SUM(si.qty * si.unit_price) as amount '
      'FROM sale_items si '
      'JOIN products p ON p.id = si.product_id '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ? '
      'GROUP BY p.id, p.name ORDER BY amount DESC LIMIT ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
        Variable.withInt(limit),
      ],
    ).get();
    return rows.map((r) => <String, Object?>{
      'name': r.read<String>('name'),
      'qty': r.read<int>('qty'),
      'amount': r.read<double>('amount'),
    }).toList();
  }

  Future<List<CashierSales>> getSalesByCashier(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT u.name as cashier_name, COALESCE(SUM(s.total), 0) as total, COUNT(*) as cnt '
      'FROM sales s JOIN users u ON u.id = s.cashier_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY u.id, u.name',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, usersTable},
    ).get();
    return rows
        .map((r) => CashierSales(
              cashierName: r.read<String>('cashier_name'),
              total: r.read<double>('total'),
              transactionCount: r.read<int>('cnt'),
            ))
        .toList();
  }

  Future<List<ProductGroupSales>> getSalesByProductGroup(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT pg.name as group_name, COALESCE(SUM(si.qty * si.unit_price), 0) as total '
      'FROM sale_items si '
      'JOIN products p ON p.id = si.product_id '
      'JOIN product_groups pg ON pg.id = p.group_id '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY pg.id, pg.name',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, saleItemsTable, productsTable, productGroupsTable},
    ).get();
    return rows
        .map((r) => ProductGroupSales(
              groupName: r.read<String>('group_name'),
              total: r.read<double>('total'),
            ))
        .toList();
  }

  Future<List<TimeSeriesPoint>> getSalesTimeSeries(
    DateTime from,
    DateTime to, {
    required String granularity,
  }) async {
    final format = switch (granularity) {
      'hour' => '%Y-%m-%d %H',
      'month' => '%Y-%m',
      _ => '%Y-%m-%d',
    };
    // sqlite's 'localtime' modifier depends on OS timezone data that isn't
    // guaranteed to be available in the bundled sqlite3 build, so the local
    // offset is computed in Dart and applied as an explicit "+N minutes"
    // modifier instead (mirrors the wall-clock bucketing intent without
    // relying on 'localtime' support).
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final offsetModifier = '${offsetMinutes >= 0 ? '+' : ''}$offsetMinutes minutes';
    final rows = await customSelect(
      "SELECT strftime('$format', s.created_at, 'unixepoch', '$offsetModifier') as bucket, COALESCE(SUM(s.total), 0) as total "
      'FROM sales s '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      "GROUP BY strftime('$format', s.created_at, 'unixepoch', '$offsetModifier') ORDER BY bucket",
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable},
    ).get();
    return rows
        .map((r) => TimeSeriesPoint(
              bucketLabel: r.read<String>('bucket'),
              total: r.read<double>('total'),
            ))
        .toList();
  }

  Future<int> getTotalQtySoldForDateRangeAndCashier(DateTime from, DateTime to, int cashierId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(si.qty), 0) as qty '
      'FROM sale_items si '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, saleItemsTable},
    ).getSingle();
    return result.read<int>('qty');
  }

  Future<({double total, int count})> getCashSalesForDateRangeAndCashier(
      DateTime from, DateTime to, int cashierId) async {
    final result = await customSelect(
      'SELECT COUNT(DISTINCT s.id) as cnt, COALESCE(SUM(p.amount), 0) as total '
      'FROM sales s JOIN payments p ON p.sale_id = s.id AND p.method = ? '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ?',
      variables: [
        Variable.withString('cash'),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).getSingle();
    return (total: result.read<double>('total'), count: result.read<int>('cnt'));
  }

  Future<List<CashLedgerRow>> getCashLedgerForDateRangeAndCashier(
      DateTime from, DateTime to, int cashierId) async {
    final rows = await customSelect(
      "SELECT date(s.created_at, 'unixepoch') as day, COALESCE(SUM(s.total), 0) as total "
      'FROM sales s '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ? '
      "GROUP BY date(s.created_at, 'unixepoch') ORDER BY day",
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).get();
    return rows
        .map((r) => CashLedgerRow(
              date: DateTime.parse(r.read<String>('day')),
              total: r.read<double>('total'),
            ))
        .toList();
  }

  Future<double> getDiscountTotalForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(discount), 0) as sum FROM sales '
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

  Future<int> getTotalQtySoldForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(si.qty), 0) as qty '
      'FROM sale_items si '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, saleItemsTable},
    ).getSingle();
    return result.read<int>('qty');
  }

  Future<({double total, int count})> getCashSalesForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COUNT(DISTINCT s.id) as cnt, COALESCE(SUM(p.amount), 0) as total '
      'FROM sales s JOIN payments p ON p.sale_id = s.id AND p.method = ? '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ?',
      variables: [
        Variable.withString('cash'),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).getSingle();
    return (total: result.read<double>('total'), count: result.read<int>('cnt'));
  }

  Future<double> getRefundTotalForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(r.total), 0) as sum FROM refunds r '
      'JOIN sales s ON s.id = r.sale_id '
      'WHERE r.created_at BETWEEN ? AND ?',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {refundsTable, salesTable},
    ).getSingle();
    return result.read<double>('sum');
  }

  Future<List<TransactionSummary>> getTransactions({
    DateTime? date,
    String? search,
    int? cashierId,
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

    if (cashierId != null) q.where(salesTable.cashierId.equals(cashierId));

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
        soNumber: sale.soNumber,
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

  Future<int> getTransactionCount({
    DateTime? date,
    String? search,
    int? cashierId,
  }) async {
    final q = selectOnly(salesTable)..addColumns([salesTable.id.count()]);

    if (date != null) {
      final from = DateTime(date.year, date.month, date.day);
      final to = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      q.where(salesTable.createdAt.isBetweenValues(from, to));
    }

    if (cashierId != null) q.where(salesTable.cashierId.equals(cashierId));

    final searchId = int.tryParse((search ?? '').replaceAll('#', ''));
    if (searchId != null) q.where(salesTable.id.equals(searchId));

    final row = await q.getSingle();
    return row.read(salesTable.id.count()) ?? 0;
  }

  Future<List<({int saleItemId, int qty})>> getRefundableItems(int saleId) async {
    final itemRows =
        await (select(saleItemsTable)..where((t) => t.saleId.equals(saleId))).get();

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

    final result = <({int saleItemId, int qty})>[];
    for (final item in itemRows) {
      final alreadyRefunded = refundedQty[item.id] ?? 0;
      final available = item.qty - alreadyRefunded;
      if (available <= 0) continue;
      result.add((saleItemId: item.id, qty: available));
    }
    return result;
  }

  Future<List<NameAmount>> _getDiscountBreakdown(
    DateTime from,
    DateTime to, {
    int? cashierId,
  }) async {
    final rows = await customSelect(
      'SELECT si.discount_type as name, COALESCE(SUM(si.discount_amount), 0) as amount '
      'FROM sale_items si JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'AND si.discount_type IS NOT NULL'
      '${cashierId != null ? ' AND s.cashier_id = ?' : ''} '
      'GROUP BY si.discount_type',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        if (cashierId != null) Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, saleItemsTable},
    ).get();
    return rows
        .map((r) => NameAmount(name: r.read<String>('name'), amount: r.read<double>('amount')))
        .toList();
  }

  Future<List<NameAmount>> getDiscountBreakdownForCashier(DateTime from, DateTime to, int cashierId) =>
      _getDiscountBreakdown(from, to, cashierId: cashierId);

  Future<List<NameAmount>> getDiscountBreakdownForDateRange(DateTime from, DateTime to) =>
      _getDiscountBreakdown(from, to);

  Future<({double vatableSales, double vatAmount, double vatExemptSales})> _getVatBreakdown(
    DateTime from,
    DateTime to, {
    int? cashierId,
  }) async {
    final cashierFilter = cashierId != null ? ' AND s.cashier_id = ?' : '';
    final taxRow = await customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN si.vat_exempt_amount IS NULL OR si.vat_exempt_amount = 0 "
      'THEN (si.qty * si.unit_price - COALESCE(si.discount_amount, 0)) / 1.12 ELSE 0 END), 0) as vatable_sales, '
      "COALESCE(SUM(CASE WHEN si.vat_exempt_amount IS NULL OR si.vat_exempt_amount = 0 "
      'THEN (si.qty * si.unit_price - COALESCE(si.discount_amount, 0)) '
      '- (si.qty * si.unit_price - COALESCE(si.discount_amount, 0)) / 1.12 ELSE 0 END), 0) as vat_amount '
      'FROM sale_items si JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ?$cashierFilter',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        if (cashierId != null) Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, saleItemsTable},
    ).getSingle();

    final exemptRow = await customSelect(
      'SELECT COALESCE(SUM(s.total), 0) as vat_exempt_sales FROM sales s '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ?$cashierFilter '
      'AND s.id IN (SELECT DISTINCT sale_id FROM sale_items '
      'WHERE vat_exempt_amount IS NOT NULL AND vat_exempt_amount > 0)',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        if (cashierId != null) Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, saleItemsTable},
    ).getSingle();

    return (
      vatableSales: taxRow.read<double>('vatable_sales'),
      vatAmount: taxRow.read<double>('vat_amount'),
      vatExemptSales: exemptRow.read<double>('vat_exempt_sales'),
    );
  }

  Future<({double vatableSales, double vatAmount, double vatExemptSales})> getVatBreakdownForCashier(
    DateTime from,
    DateTime to,
    int cashierId,
  ) =>
      _getVatBreakdown(from, to, cashierId: cashierId);

  Future<({double vatableSales, double vatAmount, double vatExemptSales})> getVatBreakdownForDateRange(
    DateTime from,
    DateTime to,
  ) =>
      _getVatBreakdown(from, to);

  Future<({double average, double highest, double lowest})> getSaleStatsForCashier(
    DateTime from,
    DateTime to,
    int cashierId,
  ) async {
    final result = await customSelect(
      'SELECT COALESCE(AVG(total), 0) as avg_sale, COALESCE(MAX(total), 0) as max_sale, '
      'COALESCE(MIN(total), 0) as min_sale FROM sales '
      'WHERE created_at BETWEEN ? AND ? AND status = ? AND cashier_id = ?',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable},
    ).getSingle();
    return (
      average: result.read<double>('avg_sale'),
      highest: result.read<double>('max_sale'),
      lowest: result.read<double>('min_sale'),
    );
  }

  Future<List<PaymentLedger>> _getPaymentLedger(
    DateTime from,
    DateTime to, {
    int? cashierId,
  }) async {
    final cashierFilter = cashierId != null ? ' AND s.cashier_id = ?' : '';
    final rows = await customSelect(
      'SELECT p.method, p.created_at as time, p.reference as reference, p.amount as amount '
      'FROM payments p JOIN sales s ON s.id = p.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ?$cashierFilter '
      'ORDER BY p.method, p.created_at',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        if (cashierId != null) Variable.withInt(cashierId),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).get();

    final byMethod = <String, List<PaymentLedgerEntry>>{};
    for (final r in rows) {
      final method = r.read<String>('method');
      byMethod.putIfAbsent(method, () => []).add(PaymentLedgerEntry(
            time: r.read<DateTime>('time'),
            reference: r.read<String?>('reference'),
            amount: r.read<double>('amount'),
          ));
    }
    return byMethod.entries
        .map((e) => PaymentLedger(
              method: e.key,
              entries: e.value,
              total: e.value.fold(0.0, (s, entry) => s + entry.amount),
              count: e.value.length,
            ))
        .toList();
  }

  Future<List<PaymentLedger>> getPaymentLedgerForCashier(DateTime from, DateTime to, int cashierId) =>
      _getPaymentLedger(from, to, cashierId: cashierId);

  Future<List<PaymentLedger>> getPaymentLedgerForDateRange(DateTime from, DateTime to) =>
      _getPaymentLedger(from, to);

  Future<List<CashLedgerEntryRow>> getCashLedgerEntriesForCashier(
    DateTime from,
    DateTime to,
    int cashierId,
  ) async {
    final rows = await customSelect(
      'SELECT p.created_at as time, p.reference as reference, p.amount as amount '
      'FROM payments p JOIN sales s ON s.id = p.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? AND s.cashier_id = ? AND p.method = ? '
      'ORDER BY p.created_at',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
        Variable.withInt(cashierId),
        Variable.withString('cash'),
      ],
      readsFrom: {salesTable, paymentsTable},
    ).get();
    return rows
        .map((r) => CashLedgerEntryRow(
              time: r.read<DateTime>('time'),
              reference: r.read<String?>('reference'),
              amount: r.read<double>('amount'),
            ))
        .toList();
  }
}
