import 'dart:isolate';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../services/history/pdf_document_builder.dart';
import '../entities/cashier_x_reading.dart';

final renderCashierReportPdfProvider = Provider<RenderCashierReportPdf>((ref) {
  return RenderCashierReportPdf();
});

/// Renders an X-reading ([CashierXReading]) to a History-archive PDF. Content mirrors
/// `encode_esc_pos_cashier_report.dart` (same data, different output).
class RenderCashierReportPdf {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required CashierXReading report,
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
      b.text('X-READING', bold: true, fontSize: 12);
      b.divider();

      b.text('Cashier: ${report.cashierName}', center: false);
      b.text('Period: ${_periodLabel(report.periodStart, report.periodEnd)}', center: false);
      b.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal())}',
        center: false,
      );
      b.divider();

      b.text('SALES SUMMARY', bold: true, center: false);
      for (final row in report.salesByPaymentMethod) {
        b.row(row.name, _moneyFormat.format(row.amount));
      }
      b.row('Total Sales', _moneyFormat.format(report.totalSales), bold: true);
      b.divider();

      for (final ledger in report.paymentLedgers) {
        final nameUpper = ledger.name.toUpperCase();
        final timeFormat = DateFormat.jm();
        b.text('$nameUpper LEDGER', bold: true, center: false);
        for (final group in ledger.entriesByDate) {
          b.text(DateFormat.yMd().format(group.date), bold: true, center: false);
          for (final entry in group.entries) {
            final label =
                '${timeFormat.format(entry.time.toLocal())}  $nameUpper'
                '${entry.reference != null ? '#${entry.reference}' : ''}';
            b.row(label, _moneyFormat.format(entry.amount));
          }
        }
        b.row('Total $nameUpper [${ledger.count}]', _moneyFormat.format(ledger.total), bold: true);
        b.divider();
      }

      b.text('TRANSACTION SUMMARY', bold: true, center: false);
      b.row('Total', '${report.totalTransactions}');
      b.row('Completed', '${report.completedTransactions}');
      b.row('Voided', '${report.voidedTransactions}');
      b.row('Refunded', '${report.refundedTransactions}');
      b.divider();

      b.text('DISCOUNT SUMMARY', bold: true, center: false);
      for (final row in report.discounts) {
        b.row(row.name, _moneyFormat.format(row.amount));
      }
      b.row('Total Discounts', _moneyFormat.format(report.totalDiscounts), bold: true);
      b.divider();

      b.text('TAX SUMMARY', bold: true, center: false);
      b.row('VAT Sales', _moneyFormat.format(report.vatSales));
      b.row('VAT Amount', _moneyFormat.format(report.vatAmount));
      b.row('VAT-Exempt Sales', _moneyFormat.format(report.vatExemptSales));
      b.divider();

      b.text('CASH COLLECTED', bold: true, center: false);
      b.row('Cash Collected', _moneyFormat.format(report.cashCollected), bold: true);
      b.divider();

      b.text('OTHER SUMMARY', bold: true, center: false);
      b.row('Average Sale', _moneyFormat.format(report.averageSale));
      b.row('Highest Sale', _moneyFormat.format(report.highestSale));
      b.row('Lowest Sale', _moneyFormat.format(report.lowestSale));
      b.row('Total Qty Sold', '${report.totalQuantitySold}');

      return b.build();
    });
  }

  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return '${format.format(start.toLocal())} - ${format.format(end.toLocal())}';
  }
}
