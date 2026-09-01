import 'package:intl/intl.dart';

import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/reports/entities/report_data.dart';
import 'transaction_export_row.dart';
import 'sale_item_export_row.dart';

abstract final class ReportCsvBuilder {
  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _timeFmt = DateFormat('HH:mm');
  static final _moneyFmt = NumberFormat('0.00');

  static String buildXReading(XReadingData d, List<TransactionExportRow> txns, List<SaleItemExportRow> items) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'X-Reading',
      'Store Name': '',
      'Cashier': d.cashierName,
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.totalSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.transactionCount - d.voidedCount - d.refundedCount}',
      'Voided': '${d.voidedCount}',
      'Refunded': '${d.refundedCount}',
      'Total Discounts': _moneyFmt.format(d.totalDiscounts),
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashCollected),
    });
    buf.writeln();
    _writePaymentBreakdown(buf, d.paymentBreakdown);
    buf.writeln();
    _writeTransactions(buf, txns);
    buf.writeln();
    _writeItemsSold(buf, txns, items);
    return buf.toString();
  }

  static String buildZReading(ZReadingData d, List<TransactionExportRow> txns, List<SaleItemExportRow> items) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'Z-Reading',
      'Store Name': '',
      'Cashier': 'store',
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.totalSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.completedCount}',
      'Voided': '${d.voidedCount}',
      'Refunded': '${d.refundedCount}',
      'Total Discounts': _moneyFmt.format(d.discountTotal),
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashCollected),
    });
    // Z-Reading cashier breakdown appended to Section 1
    buf.writeln();
    buf.writeln('Cashier Breakdown');
    buf.writeln('Cashier Name,Sales Total,Transaction Count');
    for (final c in d.salesByCashier) {
      buf.writeln('${_esc(c.cashierName)},${_moneyFmt.format(c.total)},${c.transactionCount}');
    }
    buf.writeln();
    _writePaymentBreakdown(buf, d.paymentBreakdown);
    buf.writeln();
    _writeTransactions(buf, txns);
    buf.writeln();
    _writeItemsSold(buf, txns, items);
    return buf.toString();
  }

  static String buildDailyReport(DailyReportData d, List<TransactionExportRow> txns, List<SaleItemExportRow> items) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'Daily Report',
      'Store Name': '',
      'Cashier': d.cashierName,
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.grossSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.transactionCount}',
      'Voided': '0',
      'Refunded': '0',
      'Total Discounts': '0.00',
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashSalesTotal),
    });
    buf.writeln();
    buf.writeln('Payment Method,Amount,Count');
    buf.writeln();
    _writeTransactions(buf, txns);
    buf.writeln();
    _writeItemsSold(buf, txns, items);
    return buf.toString();
  }

  static String buildTransactions({
    required DateTime from,
    required DateTime to,
    required DateTime generatedAt,
    required List<TransactionExportRow> txns,
    required List<SaleItemExportRow> items,
  }) {
    final buf = StringBuffer();

    int countWhere(String status) =>
        txns.where((t) => t.status == status).length;
    double sum(double Function(TransactionExportRow) f) =>
        txns.fold(0.0, (acc, t) => acc + f(t));

    _writeHeader(buf, {
      'Report Type': 'All Transactions',
      'Period Start': _fmtDateTime(from),
      'Period End': _fmtDateTime(to),
      'Generated At': _fmtDateTime(generatedAt),
      'Total Transactions': '${txns.length}',
      'Completed': '${countWhere('completed')}',
      'Voided': '${countWhere('voided')}',
      'Refunded': '${countWhere('refunded')}',
      'Gross Total': _moneyFmt.format(sum((t) => t.total)),
      'Total Discounts': _moneyFmt.format(sum((t) => t.discount)),
      'Total Refunded': _moneyFmt.format(sum((t) => t.refundedAmount)),
      'Net Total': _moneyFmt.format(sum((t) => t.netTotal)),
    });
    buf.writeln();
    _writeTransactions(buf, txns);
    buf.writeln();
    _writeItemsSold(buf, txns, items);
    return buf.toString();
  }

  static void _writeHeader(StringBuffer buf, Map<String, String> fields) {
    buf.writeln('Field,Value');
    for (final entry in fields.entries) {
      buf.writeln('${_esc(entry.key)},${_esc(entry.value)}');
    }
  }

  static void _writePaymentBreakdown(StringBuffer buf, List<PaymentBreakdown> breakdown) {
    buf.writeln('Payment Method,Amount,Count');
    for (final p in breakdown) {
      buf.writeln('${_esc(p.displayName)},${_moneyFmt.format(p.total)},');
    }
  }

  static void _writeItemsSold(
    StringBuffer buf,
    List<TransactionExportRow> txns,
    List<SaleItemExportRow> items,
  ) {
    final txnById = {for (final t in txns) t.id: t};
    buf.writeln('Items Sold');
    buf.writeln('Invoice No,Product,Variant,Qty,Unit Price,Discount,Line Total');
    for (final item in items) {
      final invoiceNo = txnById[item.saleId]?.invoiceNumber ?? '';
      buf.writeln([
        _esc(invoiceNo),
        _esc(item.productName),
        _esc(item.variantName),
        item.qty,
        _moneyFmt.format(item.unitPrice),
        _moneyFmt.format(item.discountAmount),
        _moneyFmt.format(item.lineTotal),
      ].join(','));
    }
  }

  static void _writeTransactions(StringBuffer buf, List<TransactionExportRow> txns) {
    buf.writeln(
        'Invoice No,Date,Time,Cashier,Type,Status,Payment Method,Gross Total,Discount,Refunded,Net Total,Void Reason');
    final sorted = [...txns]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final t in sorted) {
      final local = t.createdAt.toLocal();
      final methods = t.paymentMethods.map(_methodDisplay).join(', ');
      buf.writeln([
        _esc(t.invoiceNumber),
        _dateFmt.format(local),
        _timeFmt.format(local),
        _esc(t.cashierName),
        _esc(t.displayType),
        _esc(t.displayStatus),
        _esc(methods),
        _moneyFmt.format(t.total),
        _moneyFmt.format(t.discount),
        _moneyFmt.format(t.refundedAmount),
        _moneyFmt.format(t.netTotal),
        _esc(t.voidReason ?? ''),
      ].join(','));
    }
  }

  static String _fmtDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_dateFmt.format(local)} ${_timeFmt.format(local)}';
  }

  static String _methodDisplay(String method) => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };

  static String _esc(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
