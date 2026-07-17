import 'dart:isolate';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../utils/printer_text_sanitizer.dart';
import '../entities/cashier_x_reading.dart';

final encodeEscPosCashierReportProvider = Provider<EncodeEscPosCashierReport>((ref) {
  return EncodeEscPosCashierReport();
});

class EncodeEscPosCashierReport {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required CashierXReading report,
    required PosTerminalDto terminal,
    String? serialNumber,
  }) async {
    final profile = await CapabilityProfile.load();

    return Isolate.run(() async {
      var bytes = <int>[];
      final generator = Generator(PaperSize.mm80, profile);

      bytes += generator.reset();
      bytes += generator.feed(1);

      bytes += generator.text(
        sanitizeForPrinter(
          terminal.legalName?.trim().isNotEmpty == true
              ? terminal.legalName!.trim()
              : 'POS Terminal',
        ),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        sanitizeForPrinter(terminal.address.trim()),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'TIN: ${sanitizeForPrinter(terminal.tinNumber)}',
        styles: const PosStyles(align: PosAlign.center),
      );
      if (serialNumber != null) {
        bytes += generator.text(
          'S/N: ${sanitizeForPrinter(serialNumber)}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.feed(1);

      bytes += generator.text('X-READING', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(1);

      bytes += generator.text(
        '------------------------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Cashier: ${sanitizeForPrinter(report.cashierName)}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Period: ${_periodLabel(report.periodStart, report.periodEnd)}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        'Generated: ${sanitizeForPrinter(DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()))}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'SALES SUMMARY');
      for (final row in report.salesByPaymentMethod) {
        bytes += _amountRow(generator, row.name, row.amount);
      }
      bytes += _amountRow(generator, 'Total Sales', report.totalSales, bold: true);
      bytes += _divider(generator);

      for (final ledger in report.paymentLedgers) {
        final nameUpper = ledger.name.toUpperCase();
        final timeFormat = DateFormat.jm();
        bytes += _sectionHeader(generator, '$nameUpper LEDGER');
        for (final group in ledger.entriesByDate) {
          bytes += generator.text(
            DateFormat.yMd().format(group.date),
            styles: const PosStyles(bold: true),
          );
          for (final entry in group.entries) {
            final label = sanitizeForPrinter(
              '${timeFormat.format(entry.time.toLocal())}  $nameUpper'
              '${entry.reference != null ? '#${entry.reference}' : ''}',
            );
            bytes += _amountRow(generator, label, entry.amount);
          }
        }
        bytes += _amountRow(generator, 'Total $nameUpper [${ledger.count}]', ledger.total, bold: true);
        bytes += _divider(generator);
      }

      bytes += _sectionHeader(generator, 'TRANSACTION SUMMARY');
      bytes += _countRow(generator, 'Total', report.totalTransactions);
      bytes += _countRow(generator, 'Completed', report.completedTransactions);
      bytes += _countRow(generator, 'Voided', report.voidedTransactions);
      bytes += _countRow(generator, 'Refunded', report.refundedTransactions);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'DISCOUNT SUMMARY');
      for (final row in report.discounts) {
        bytes += _amountRow(generator, row.name, row.amount);
      }
      bytes += _amountRow(generator, 'Total Discounts', report.totalDiscounts, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'TAX SUMMARY');
      bytes += _amountRow(generator, 'VAT Sales', report.vatSales);
      bytes += _amountRow(generator, 'VAT Amount', report.vatAmount);
      bytes += _amountRow(generator, 'VAT-Exempt Sales', report.vatExemptSales);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'CASH COLLECTED');
      bytes += _amountRow(generator, 'Cash Collected', report.cashCollected, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'OTHER SUMMARY');
      bytes += _amountRow(generator, 'Average Sale', report.averageSale);
      bytes += _amountRow(generator, 'Highest Sale', report.highestSale);
      bytes += _amountRow(generator, 'Lowest Sale', report.lowestSale);
      bytes += _countRow(generator, 'Total Qty Sold', report.totalQuantitySold);

      bytes += generator.feed(3);
      bytes += generator.cut();

      return Uint8List.fromList(bytes);
    });
  }

  List<int> _sectionHeader(Generator generator, String title) {
    return generator.text(sanitizeForPrinter(title), styles: const PosStyles(bold: true));
  }

  List<int> _divider(Generator generator) {
    return generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
  }

  List<int> _amountRow(Generator generator, String label, double amount, {bool bold = false}) {
    return generator.row([
      PosColumn(text: sanitizeForPrinter(label), width: 8, styles: PosStyles(bold: bold)),
      PosColumn(
        text: _moneyFormat.format(amount),
        width: 4,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  List<int> _countRow(Generator generator, String label, int value) {
    return generator.row([
      PosColumn(text: sanitizeForPrinter(label), width: 8),
      PosColumn(text: '$value', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
  }

  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No transactions yet';
    final format = DateFormat.yMd().add_jm();
    return sanitizeForPrinter(
      '${format.format(start.toLocal())} - ${format.format(end.toLocal())}',
    );
  }
}
