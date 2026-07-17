import 'dart:isolate';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../utils/printer_text_sanitizer.dart';
import '../entities/cashier_daily_report.dart';

final encodeEscPosCashierDailyReportProvider = Provider<EncodeEscPosCashierDailyReport>((ref) {
  return EncodeEscPosCashierDailyReport();
});

class EncodeEscPosCashierDailyReport {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required CashierDailyReport report,
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
          terminal.legalName?.trim().isNotEmpty ?? false
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

      bytes += generator.text(
        'CASHIER REPORT',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(1);

      bytes += _keyValueRow(generator, 'Terminal', report.terminalName);
      bytes += _keyValueRow(generator, 'Cashier', report.cashierName);
      bytes += generator.text('Period: ${_periodLabel(report.periodStart, report.periodEnd)}');
      bytes += generator.text(
        'Generated: ${sanitizeForPrinter(DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()))}',
      );
      bytes += _divider(generator);

      bytes += _amountRow(generator, 'Gross Sales', report.grossSales, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'SUMMARY');
      bytes += _amountRow(generator, 'Vatable Sales', report.vatableSales);
      bytes += _amountRow(generator, 'VAT Amount', report.vatAmount);
      bytes += _amountRow(generator, 'VAT Exempt Sales', report.vatExemptSales);
      bytes += _amountRow(generator, 'Zero Rated Sales', report.zeroRatedSales);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'OTHERS');
      bytes += _amountRow(generator, 'Net of Tax', report.netOfTax);
      bytes += _countRow(generator, 'No. Transactions', report.transactionCount);
      bytes += _countRow(generator, 'Total Quantity', report.totalQuantity);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'CASH SALES');
      bytes += _amountRow(generator, 'Total Cash Sales', report.totalCashSales);
      bytes += _countRow(generator, 'No. Cash Sales', report.cashSalesCount);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'SALES BY PRODUCT');
      bytes += generator.row([
        PosColumn(text: 'QTY x PRODUCT', width: 8),
        PosColumn(text: 'AMOUNT', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (report.salesByProduct.isEmpty) {
        bytes += generator.text('No products sold today');
      } else {
        for (final line in report.salesByProduct) {
          bytes += _amountRow(generator, '${line.quantity} ${line.productName}', line.amount);
        }
      }
      bytes += _amountRow(generator, 'TOTAL', report.grossSales, bold: true);
      bytes += _divider(generator);

      bytes += _sectionHeader(generator, 'CASH LEDGER');
      final timeFormat = DateFormat.jm();
      for (final summary in report.cashLedgerSummariesByDate) {
        bytes += generator.text(
          DateFormat.yMd().format(summary.date),
          styles: const PosStyles(bold: true),
        );
        final label = sanitizeForPrinter(
          '${timeFormat.format(summary.start.toLocal())}'
              ' - ${timeFormat.format(summary.end.toLocal())}  CASH',
        );
        bytes += _amountRow(generator, label, summary.amount);
      }
      bytes += _amountRow(generator, '***** TOTAL CASH', report.totalCashSales, bold: true);

      bytes += generator.feed(3);
      bytes += generator.cut();

      return Uint8List.fromList(bytes);
    });
  }

  List<int> _sectionHeader(Generator generator, String title) {
    return generator.text(sanitizeForPrinter(title), styles: const PosStyles(bold: true));
  }

  List<int> _keyValueRow(Generator generator, String label, String value) {
    return generator.row([
      PosColumn(text: sanitizeForPrinter(label), width: 6),
      PosColumn(
        text: sanitizeForPrinter(value),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
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
