import 'dart:isolate';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../services/history/pdf_document_builder.dart';
import '../entities/cashier_daily_report.dart';

final renderCashierDailyReportPdfProvider = Provider<RenderCashierDailyReportPdf>((ref) {
  return RenderCashierDailyReportPdf();
});

/// Renders a [CashierDailyReport] to a History-archive PDF. Content mirrors
/// `encode_esc_pos_cashier_daily_report.dart` (same data, different output).
class RenderCashierDailyReportPdf {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required CashierDailyReport report,
    required PosTerminalDto terminal,
    String? serialNumber,
  }) async {
    return Isolate.run(() async {
      final b = PdfDocumentBuilder();

      b.text(
        terminal.legalName?.trim().isNotEmpty ?? false ? terminal.legalName!.trim() : 'POS Terminal',
        bold: true,
      );
      b.text(terminal.address.trim());
      b.text('TIN: ${terminal.tinNumber}');
      if (serialNumber != null) b.text('S/N: $serialNumber');
      b.spacing();
      b.text('CASHIER REPORT', bold: true, fontSize: 12);
      b.divider();

      b.row('Terminal', report.terminalName);
      b.row('Cashier', report.cashierName);
      b.text('Period: ${_periodLabel(report.periodStart, report.periodEnd)}', center: false);
      b.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal())}',
        center: false,
      );
      b.divider();

      b.row('Gross Sales', _moneyFormat.format(report.grossSales), bold: true);
      b.divider();

      b.text('SUMMARY', bold: true, center: false);
      b.row('Vatable Sales', _moneyFormat.format(report.vatableSales));
      b.row('VAT Amount', _moneyFormat.format(report.vatAmount));
      b.row('VAT Exempt Sales', _moneyFormat.format(report.vatExemptSales));
      b.row('Zero Rated Sales', _moneyFormat.format(report.zeroRatedSales));
      b.divider();

      b.text('OTHERS', bold: true, center: false);
      b.row('Net of Tax', _moneyFormat.format(report.netOfTax));
      b.row('No. Transactions', '${report.transactionCount}');
      b.row('Total Quantity', '${report.totalQuantity}');
      b.divider();

      b.text('CASH SALES', bold: true, center: false);
      b.row('Total Cash Sales', _moneyFormat.format(report.totalCashSales));
      b.row('No. Cash Sales', '${report.cashSalesCount}');
      b.divider();

      b.text('SALES BY PRODUCT', bold: true, center: false);
      b.tableRow(['QTY x PRODUCT', 'AMOUNT'], flex: const [3, 1], bold: true);
      if (report.salesByProduct.isEmpty) {
        b.text('No products sold today', center: false);
      } else {
        for (final line in report.salesByProduct) {
          b.row('${line.quantity} ${line.productName}', _moneyFormat.format(line.amount));
        }
      }
      b.row('TOTAL', _moneyFormat.format(report.grossSales), bold: true);
      b.divider();

      b.text('CASH LEDGER', bold: true, center: false);
      final timeFormat = DateFormat.jm();
      for (final summary in report.cashLedgerSummariesByDate) {
        b.text(DateFormat.yMd().format(summary.date), bold: true, center: false);
        final label =
            '${timeFormat.format(summary.start.toLocal())}'
            ' - ${timeFormat.format(summary.end.toLocal())}  CASH';
        b.row(label, _moneyFormat.format(summary.amount));
      }
      b.row('***** TOTAL CASH', _moneyFormat.format(report.totalCashSales), bold: true);

      return b.build();
    });
  }

  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return '${format.format(start.toLocal())} - ${format.format(end.toLocal())}';
  }
}
