import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/ordering/entities/receipt.dart';
import '../../features/reports/entities/report_data.dart';
import 'built_in_printer.dart';
import 'print_row_layout.dart';
import 'receipt_print_document.dart';

const _prefMacKey = 'printer_mac';
const _prefNameKey = 'printer_name';

abstract final class PrintService {
  static Future<String?> getSavedMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefMacKey);
  }

  static Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefNameKey);
  }

  static Future<void> savePrinter(String mac, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefMacKey, mac);
    await prefs.setString(_prefNameKey, name);
  }

  static Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefMacKey);
    await prefs.remove(_prefNameKey);
  }

  static Future<bool> printReceipt(
    Receipt receipt, {
    String storeFooter = 'Thank You!',
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
  }) async {
    final document = ReceiptPrintDocument.build(
      receipt,
      storeName: storeName,
      storeAddress: storeAddress,
      storeTin: storeTin,
      terminalName: terminalName,
      storeFooter: storeFooter,
    );

    if (await BuiltInPrinter.isAvailable()) {
      return BuiltInPrinter.print(document);
    }

    return _printViaBluetooth(document);
  }

  static Future<bool> _printViaBluetooth(List<PrintInstruction> document) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();
      for (final instruction in document) {
        bytes += _encodeBluetoothInstruction(generator, instruction);
      }
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static List<int> _encodeBluetoothInstruction(
    Generator generator,
    PrintInstruction instruction,
  ) {
    return switch (instruction) {
      PrintText(:final text, :final align, :final bold, :final sizeMultiplier) => generator.text(
          text,
          styles: PosStyles(
            align: _posAlign(align),
            bold: bold,
            height: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
            width: sizeMultiplier >= 2 ? PosTextSize.size2 : PosTextSize.size1,
          ),
        ),
      PrintRow(:final columns, :final resolvedWeights, :final minGap) =>
        _generateRowBytes(generator, columns, resolvedWeights, minGap),
      PrintDivider() => generator.hr(),
      PrintFeed(:final lines) => generator.feed(lines),
    };
  }

  // esc_pos_utils_plus (PaperSize.mm80, font A) prints 48 chars/line — see
  // Generator._getMaxCharsPerLine, which isn't exposed publicly.
  static const int _lineWidthChars = 48;

  // Columns are laid out in fixed-width slots sized proportionally to
  // [weights], spanning the full [_lineWidthChars] edge-to-edge — like a
  // real receipt table rather than a two-item spaceBetween row. Each column
  // is aligned per its own [PrintText.align] within its slot, so a
  // right-aligned column lands flush against the right edge of that slot.
  // A row is only joined into one physical line when every column shares
  // the same [PrintText.bold]; otherwise each column is printed with its
  // own style on its own line. Matches the built-in Nyx printer path
  // (NyxPrinterPlugin.kt).
  static List<int> _generateRowBytes(
    Generator generator,
    List<PrintText> columns,
    List<int> weights,
    int minGap,
  ) {
    final line = buildPrintRowLine(columns, weights, _lineWidthChars, minGap);
    if (line != null) {
      return generator.text(line, styles: PosStyles(bold: columns.first.bold));
    }

    var bytes = <int>[];
    for (final column in columns) {
      bytes += generator.text(
        column.text,
        styles: PosStyles(align: _posAlign(column.align), bold: column.bold),
      );
    }
    return bytes;
  }

  static PosAlign _posAlign(PrintAlign align) => switch (align) {
        PrintAlign.left => PosAlign.left,
        PrintAlign.center => PosAlign.center,
        PrintAlign.right => PosAlign.right,
      };

  static Future<bool> printXReading(XReadingData data, {String currency = 'PHP'}) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();

      bytes += generator.text(
        'X-READING',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
      if (data.id != null) {
        bytes += generator.text(
          'X-Reading #${data.id}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.hr();
      bytes += generator.text('Cashier: ${data.cashierName}');
      bytes += generator.text('Period:  ${_fmtDate(data.periodStart)} -');
      bytes += generator.text('         ${_fmtDate(data.periodEnd)}');
      bytes += generator.text('Printed: ${_fmtDate(data.generatedAt)}');

      bytes += _sectionHeader(generator, 'SALES SUMMARY');
      bytes += _amountRow(generator, 'Total Sales', data.totalSales, currency: currency);
      bytes += _countRow(generator, 'Transactions', data.transactionCount);

      if (data.paymentBreakdown.isNotEmpty) {
        bytes += _sectionHeader(generator, 'PAYMENT BREAKDOWN');
        for (final p in data.paymentBreakdown) {
          bytes += _amountRow(generator, p.displayName, p.total, currency: currency);
        }
      }

      for (final ledger in data.paymentLedgers) {
        bytes += _paymentLedgerBytes(generator, ledger, currency: currency);
      }

      if (data.topProducts.isNotEmpty) {
        bytes += _sectionHeader(generator, 'TOP PRODUCTS');
        for (final p in data.topProducts) {
          bytes += _amountRow(generator, '${p.name} x${p.quantity}', p.total, currency: currency);
        }
      }

      bytes += _sectionHeader(generator, 'TRANSACTION SUMMARY');
      bytes += _countRow(generator, 'Completed', data.transactionCount);
      bytes += _countRow(generator, 'Voided', data.voidedCount);
      bytes += _countRow(generator, 'Refunded', data.refundedCount);

      bytes += _sectionHeader(generator, 'DISCOUNT SUMMARY');
      for (final d in data.discounts) {
        bytes += _amountRow(generator, d.name, d.amount, currency: currency);
      }
      bytes += _amountRow(generator, 'Total Discounts', data.totalDiscounts, currency: currency);

      bytes += _sectionHeader(generator, 'TAX SUMMARY');
      bytes += _amountRow(generator, 'VAT Sales', data.vatableSales, currency: currency);
      bytes += _amountRow(generator, 'VAT Amount', data.vatAmount, currency: currency);
      bytes += _amountRow(generator, 'VAT-Exempt Sales', data.vatExemptSales, currency: currency);

      bytes += _sectionHeader(generator, 'CASH COLLECTED');
      bytes += _amountRow(generator, 'Cash Collected', data.cashCollected, currency: currency);

      bytes += _sectionHeader(generator, 'OTHER SUMMARY');
      bytes += _amountRow(generator, 'Average Sale', data.averageSale, currency: currency);
      bytes += _amountRow(generator, 'Highest Sale', data.highestSale, currency: currency);
      bytes += _amountRow(generator, 'Lowest Sale', data.lowestSale, currency: currency);

      bytes += generator.hr();
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static Future<bool> printDailyReport(DailyReportData data, {String currency = 'PHP'}) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();

      bytes += generator.text(
        'DAILY REPORT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
      if (data.id != null) {
        bytes += generator.text(
          'Daily Report #${data.id}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.hr();
      bytes += generator.text('Cashier: ${data.cashierName}');
      bytes += generator.text('Period:  ${_fmtDate(data.periodStart)} -');
      bytes += generator.text('         ${_fmtDate(data.periodEnd)}');
      bytes += generator.text('Printed: ${_fmtDate(data.generatedAt)}');

      bytes += _sectionHeader(generator, 'GROSS SALES');
      bytes += _amountRow(generator, 'Gross Sales', data.grossSales, currency: currency);

      bytes += _sectionHeader(generator, 'VAT SUMMARY');
      bytes += _amountRow(generator, 'Vatable Sales', data.vatableSales, currency: currency);
      bytes += _amountRow(generator, 'VAT Amount', data.vatAmount, currency: currency);
      bytes += _amountRow(generator, 'VAT-Exempt Sales', data.vatExemptSales, currency: currency);

      bytes += _sectionHeader(generator, 'OTHERS');
      bytes += _amountRow(generator, 'Net of Tax', data.netOfTax, currency: currency);
      bytes += _countRow(generator, 'Transactions', data.transactionCount);
      bytes += _countRow(generator, 'Total Qty Sold', data.totalQtySold);

      bytes += _sectionHeader(generator, 'CASH SALES');
      bytes += _amountRow(generator, 'Cash Sales Total', data.cashSalesTotal, currency: currency);
      bytes += _countRow(generator, 'Cash Sales Count', data.cashSalesCount);

      if (data.salesByProduct.isNotEmpty) {
        bytes += _sectionHeader(generator, 'SALES BY PRODUCT');
        for (final p in data.salesByProduct) {
          bytes += _amountRow(generator, '${p.name} x${p.quantity}', p.total, currency: currency);
        }
      }

      if (data.cashLedger.isNotEmpty) {
        bytes += _sectionHeader(generator, 'CASH LEDGER');
        for (final group in data.cashLedgerSummariesByDate) {
          bytes += generator.text(_fmtDay(group.date), styles: const PosStyles(bold: true));
          for (final entry in group.entries) {
            bytes += _amountRow(
              generator,
              '${_fmtTime(entry.time)}${entry.reference != null ? ' #${entry.reference}' : ''}',
              entry.amount,
              currency: currency,
            );
          }
          bytes += _amountRow(generator, 'Total', group.total, currency: currency);
        }
      }

      bytes += generator.hr();
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static Future<bool> printZReading(ZReadingData data, {String currency = 'PHP'}) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();

      bytes += generator.text(
        'Z-READING',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
      bytes += generator.text(
        'Z-Reading #${data.zCounter}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.text('Closed by:     ${data.closedByName}');
      bytes += generator.text('Authorized by: ${data.authorizedByName}');
      bytes += generator.text('Period:  ${_fmtDate(data.periodStart)} -');
      bytes += generator.text('         ${_fmtDate(data.periodEnd)}');
      bytes += generator.text('Printed: ${_fmtDate(data.generatedAt)}');

      bytes += _sectionHeader(generator, 'GRAND TOTAL');
      bytes += _amountRow(generator, 'Beginning Balance', data.beginningBalance, currency: currency);
      bytes += _amountRow(generator, 'Ending Balance', data.endingBalance, currency: currency);

      bytes += _sectionHeader(generator, 'SALES SUMMARY');
      bytes += _amountRow(generator, 'Total Sales', data.totalSales, currency: currency);
      bytes += _countRow(generator, 'Transactions', data.transactionCount);

      if (data.paymentBreakdown.isNotEmpty) {
        bytes += _sectionHeader(generator, 'PAYMENT BREAKDOWN');
        for (final p in data.paymentBreakdown) {
          bytes += _amountRow(generator, p.displayName, p.total, currency: currency);
        }
      }

      for (final ledger in data.paymentLedgers) {
        bytes += _paymentLedgerBytes(generator, ledger, currency: currency);
      }

      bytes += _sectionHeader(generator, 'TRANSACTION SUMMARY');
      bytes += _countRow(generator, 'Completed', data.completedCount);
      bytes += _countRow(generator, 'Voided', data.voidedCount);
      bytes += _countRow(generator, 'Refunded', data.refundedCount);

      bytes += _sectionHeader(generator, 'DISCOUNT SUMMARY');
      for (final d in data.discounts) {
        bytes += _amountRow(generator, d.name, d.amount, currency: currency);
      }
      bytes += _amountRow(generator, 'Total Discounts', data.discountTotal, currency: currency);

      bytes += _sectionHeader(generator, 'TAX SUMMARY (VAT)');
      bytes += _amountRow(generator, 'Vatable Sales', data.vatableSales, currency: currency);
      bytes += _amountRow(generator, 'VAT Amount', data.vatAmount, currency: currency);
      bytes += _amountRow(generator, 'VAT-Exempt Sales', data.vatExemptSales, currency: currency);

      bytes += _sectionHeader(generator, 'CASH COLLECTED');
      bytes += _amountRow(generator, 'Cash Collected', data.cashCollected, currency: currency);
      bytes += _countRow(generator, 'Total Qty Sold', data.totalQtySold);

      if (data.salesByCashier.isNotEmpty) {
        bytes += _sectionHeader(generator, 'SALES BY CASHIER');
        for (final c in data.salesByCashier) {
          bytes += _amountRow(generator, '${c.cashierName} (${c.transactionCount})', c.total, currency: currency);
        }
      }

      bytes += generator.hr();
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

  static String _fmtDay(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

}

// ─── Shared byte-building helpers for cashier-accounting reports ──────────────
//
// Generic (not X-Reading-specific) so Daily Report and Z-Reading print methods
// can reuse them too.

List<int> _sectionHeader(Generator g, String title) {
  var bytes = <int>[];
  bytes += g.hr();
  bytes += g.text(title, styles: const PosStyles(bold: true));
  return bytes;
}

List<int> _amountRow(Generator g, String label, double amount, {String currency = 'PHP'}) {
  return g.row([
    PosColumn(text: label, width: 8),
    PosColumn(
      text: '$currency ${amount.toStringAsFixed(2)}',
      width: 4,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
}

List<int> _countRow(Generator g, String label, int count) {
  return g.row([
    PosColumn(text: label, width: 8),
    PosColumn(
      text: '$count',
      width: 4,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
}

/// Itemized per-payment-method ledger, grouped by date, followed by a total
/// row — the printed counterpart of `PaymentLedgerSection` on screen.
List<int> _paymentLedgerBytes(Generator g, PaymentLedger ledger, {String currency = 'PHP'}) {
  final nameUpper = ledger.displayName.toUpperCase();
  var bytes = <int>[];
  bytes += _sectionHeader(g, '$nameUpper LEDGER');
  for (final group in ledger.entriesByDate) {
    bytes += g.text(
      '${group.date.year}-${group.date.month.toString().padLeft(2, '0')}-'
      '${group.date.day.toString().padLeft(2, '0')}',
      styles: const PosStyles(bold: true),
    );
    for (final entry in group.entries) {
      final local = entry.time.toLocal();
      final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      bytes += _amountRow(
        g,
        '$time  $nameUpper${entry.reference != null ? ' #${entry.reference}' : ''}',
        entry.amount,
        currency: currency,
      );
    }
  }
  bytes += _amountRow(g, 'Total $nameUpper [${ledger.count}]', ledger.total, currency: currency);
  return bytes;
}
