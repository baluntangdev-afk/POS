import 'dart:isolate';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../services/history/pdf_document_builder.dart';
import '../entities/z_reading.dart';

final renderZReadingPdfProvider = Provider<RenderZReadingPdf>((ref) {
  return RenderZReadingPdf();
});

/// Renders a [ZReading] to a History-archive PDF. Content mirrors
/// `encode_esc_pos_z_reading.dart` (same data, different output).
class RenderZReadingPdf {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required ZReading report,
    required PosTerminalDto terminal,
    String? serialNumber,
  }) async {
    return Isolate.run(() async {
      final b = PdfDocumentBuilder();

      b.text(
        terminal.legalName?.trim().isNotEmpty == true ? terminal.legalName!.trim() : 'POS Terminal',
        bold: true,
      );
      b.text(terminal.address.trim());
      b.text('TIN: ${terminal.tinNumber}');
      if (serialNumber != null) b.text('S/N: $serialNumber');
      b.spacing();
      b.text('Z-READING', bold: true, fontSize: 12);
      if (report.zCounter != null) b.text('Z-Counter: ${report.zCounter}');
      b.divider();

      b.text('Period: ${_periodLabel(report.periodStart, report.periodEnd)}', center: false);
      b.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal())}',
        center: false,
      );
      if (report.closedByName != null) b.text('Closed by: ${report.closedByName}', center: false);
      if (report.authorizedByName != null) {
        b.text('Authorized by: ${report.authorizedByName}', center: false);
      }
      b.divider();

      b.text('GRAND TOTAL', bold: true, center: false);
      b.row('Beginning Balance', _moneyFormat.format(report.beginningBalance));
      b.row('Ending Balance', _moneyFormat.format(report.endingBalance), bold: true);
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

      b.tableRow(['QTY x PRODUCT', 'AMOUNT'], flex: const [3, 1], bold: true);
      for (final row in report.salesByItem) {
        b.row('${row.quantity} ${row.name}', _moneyFormat.format(row.amount));
      }
      b.divider();

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
      b.row('Total Qty Sold', '${report.totalQuantitySold}');
      b.divider();

      b.text('SALES BY CASHIER', bold: true, center: false);
      for (final row in report.salesByCashier) {
        b.row('${row.cashierName} [${row.transactionCount}]', _moneyFormat.format(row.salesTotal));
      }

      return b.build();
    });
  }

  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return '${format.format(start.toLocal())} - ${format.format(end.toLocal())}';
  }
}
