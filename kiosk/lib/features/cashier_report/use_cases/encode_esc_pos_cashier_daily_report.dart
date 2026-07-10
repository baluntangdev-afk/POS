import 'dart:isolate';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../gen/assets.gen.dart';
import '../entities/cashier_daily_report.dart';

final encodeEscPosCashierDailyReportProvider = Provider<EncodeEscPosCashierDailyReport>((ref) {
  return EncodeEscPosCashierDailyReport();
});

class EncodeEscPosCashierDailyReport {
  static final _moneyFormat = NumberFormat('#,##0.00');

  Future<Uint8List> call({
    required CashierDailyReport report,
    required PosTerminalDto terminal,
  }) async {
    final profile = await CapabilityProfile.load();
    final logoData = await rootBundle.load(Assets.images.cartivoLogo.path);
    final logoBytes = logoData.buffer.asUint8List();

    return Isolate.run(() async {
      var bytes = <int>[];
      final generator = Generator(PaperSize.mm80, profile);

      final logo = img.decodeImage(logoBytes);
      if (logo != null) {
        final resized = img.copyResize(logo, width: 380);
        final grayscale = img.grayscale(resized);
        bytes += generator.image(grayscale);
      }
      bytes += generator.reset();
      bytes += generator.feed(1);

      bytes += generator.text(
        terminal.legalName?.trim().isNotEmpty ?? false ? terminal.legalName!.trim() : 'POS Terminal',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        terminal.address.trim(),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'TIN: ${terminal.tinNumber}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'CASHIER REPORT',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(1);

      bytes += generator.row([
        PosColumn(text: report.terminalName, width: 6),
        PosColumn(text: report.businessDate, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'CASHIER REPORT', width: 6),
        PosColumn(
          text: report.cashierName,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.text(
        'Generated: ${DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal())}',
      );
      bytes += _divider(generator);

      bytes += _amountRow(generator, 'Gross Sales', report.grossSales, bold: true);
      bytes += generator.feed(1);

      bytes += generator.text('Summary:', styles: const PosStyles(bold: true));
      bytes += _amountRow(generator, '  Vatable Sales', report.vatableSales);
      bytes += _amountRow(generator, '  VAT Amount', report.vatAmount);
      bytes += _amountRow(generator, '  VAT Exempt Sales', report.vatExemptSales);
      bytes += _amountRow(generator, '  Zero Rated Sales', report.zeroRatedSales);
      bytes += generator.feed(1);

      bytes += generator.text('Others:', styles: const PosStyles(bold: true));
      bytes += _amountRow(generator, '  Net of Tax', report.netOfTax);
      bytes += _countRow(generator, '  No. Transactions', report.transactionCount);
      bytes += _countRow(generator, '  Total Quantity', report.totalQuantity);
      bytes += generator.feed(1);

      bytes += _amountRow(generator, 'Total Cash Sales', report.totalCashSales);
      bytes += _countRow(generator, 'No. Cash Sales', report.cashSalesCount);
      bytes += _divider(generator);

      bytes += generator.text('SALES BY PRODUCT', styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: 'QTY x PRODUCT', width: 8),
        PosColumn(text: 'AMOUNT', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += _divider(generator);
      for (final line in report.salesByProduct) {
        bytes += _amountRow(generator, '${line.quantity} ${line.productName}', line.amount);
      }
      bytes += _divider(generator);
      bytes += _amountRow(generator, 'TOTAL', report.grossSales, bold: true);
      bytes += generator.feed(1);

      bytes += generator.text('CASH LEDGER', styles: const PosStyles(bold: true));
      final timeFormat = DateFormat.jm();
      if (report.cashLedgerSummary case final summary?) {
        final label =
            '${timeFormat.format(summary.start.toLocal())}'
            ' - ${timeFormat.format(summary.end.toLocal())}  CASH';
        bytes += _amountRow(generator, label, summary.amount);
      }
      bytes += _amountRow(generator, '***** TOTAL CASH', report.totalCashSales, bold: true);

      bytes += generator.feed(3);
      bytes += generator.cut();

      return Uint8List.fromList(bytes);
    });
  }

  List<int> _divider(Generator generator) {
    return generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
  }

  List<int> _amountRow(Generator generator, String label, double amount, {bool bold = false}) {
    return generator.row([
      PosColumn(text: label, width: 8, styles: PosStyles(bold: bold)),
      PosColumn(
        text: _moneyFormat.format(amount),
        width: 4,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  List<int> _countRow(Generator generator, String label, int value) {
    return generator.row([
      PosColumn(text: label, width: 8),
      PosColumn(text: '$value', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
  }
}
