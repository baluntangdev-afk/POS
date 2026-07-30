import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/ordering/entities/receipt.dart';

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
    String currency = 'PHP',
    String storeFooter = 'Thank you!',
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
  }) async {
    final mac = await getSavedMac();
    if (mac == null) return false;

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      var bytes = <int>[];

      bytes += generator.reset();

      if (storeName != null && storeName.isNotEmpty) {
        bytes += generator.text(
          storeName,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }
      if (storeAddress != null && storeAddress.isNotEmpty) {
        bytes += generator.text(
          storeAddress,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      if (storeTin != null && storeTin.isNotEmpty) {
        bytes += generator.text(
          'TIN: $storeTin',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.text(
        'RECEIPT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);
      bytes += generator.text(
        receipt.docNumber,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.text('Cashier: ${receipt.cashierName}');
      bytes += generator.text('Date:    ${_fmtDate(receipt.docDate)}');
      bytes += generator.text('Type:    ${_fmtSaleType(receipt.type)}');
      if (terminalName != null && terminalName.isNotEmpty) {
        bytes += generator.text('Terminal: $terminalName');
      }
      bytes += generator.hr();

      for (final item in receipt.items) {
        bytes += generator.row([
          PosColumn(
            text: '${item.isMain ? '' : '  '}x${item.quantity}  ${item.description}',
            width: 8,
          ),
          PosColumn(
            text: '$currency ${item.totalAmount.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        if (item.discountAmount > 0) {
          bytes += generator.row([
            PosColumn(text: '   Discount', width: 8),
            PosColumn(
              text: '-$currency ${item.discountAmount.toStringAsFixed(2)}',
              width: 4,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
          if (item.discountBeneficiaryName != null && item.discountBeneficiaryName!.isNotEmpty) {
            bytes += generator.text(
              '   ${item.discountType}: ${item.discountBeneficiaryName} '
              '(${item.discountBeneficiaryId})',
              styles: const PosStyles(align: PosAlign.left),
            );
          }
        }
      }

      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(
          text: '$currency ${receipt.grossAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'VATable Sales', width: 8),
        PosColumn(
          text: '$currency ${receipt.vatableAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (receipt.vatExemptSales > 0) {
        bytes += generator.row([
          PosColumn(text: 'VAT-Exempt Sales', width: 8),
          PosColumn(
            text: '$currency ${receipt.vatExemptSales.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.row([
        PosColumn(text: 'VAT', width: 8),
        PosColumn(
          text: '$currency ${receipt.vatAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (receipt.discountAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Discount', width: 8),
          PosColumn(
            text: '-$currency ${receipt.discountAmount.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
          text: '$currency ${receipt.totalAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Payment', width: 8),
        PosColumn(
          text: _fmtMethod(receipt.payment.method),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (receipt.payment.method == 'cash') {
        bytes += generator.row([
          PosColumn(text: 'Tendered', width: 8),
          PosColumn(
            text: '$currency ${receipt.payment.amountPaid.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Change', width: 8),
          PosColumn(
            text: '$currency ${receipt.payment.change.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else if (receipt.payment.reference != null && receipt.payment.reference!.isNotEmpty) {
        bytes += generator.row([
          PosColumn(text: 'Reference', width: 8),
          PosColumn(
            text: receipt.payment.reference!,
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();
      bytes += generator.text(
        storeFooter.isNotEmpty ? storeFooter : 'Thank you!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }

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
        for (final e in data.cashLedger) {
          bytes += _amountRow(generator, _fmtDay(e.date), e.total, currency: currency);
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

      bytes += _sectionHeader(generator, 'TRANSACTION SUMMARY');
      bytes += _countRow(generator, 'Completed', data.completedCount);
      bytes += _countRow(generator, 'Voided', data.voidedCount);
      bytes += _countRow(generator, 'Refunded', data.refundedCount);

      bytes += _sectionHeader(generator, 'DISCOUNT SUMMARY');
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

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String _fmtSaleType(String type) => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };

  static String _fmtMethod(String method) => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };
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
