import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ordering/entities/sale_receipt_data.dart';

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
    SaleReceiptData receipt, {
    String currency = 'PHP',
    String storeFooter = 'Thank you!',
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
        'Sale #${receipt.saleId.toString().padLeft(6, '0')}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.text('Cashier: ${receipt.cashierName}');
      bytes += generator.text('Date:    ${_fmtDate(receipt.createdAt)}');
      bytes += generator.text('Type:    ${_fmtSaleType(receipt.saleType)}');
      bytes += generator.hr();

      for (final item in receipt.items) {
        bytes += generator.row([
          PosColumn(
            text: 'x${item.quantity}  ${item.productName}',
            width: 8,
          ),
          PosColumn(
            text: '$currency ${item.lineTotal.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        final mods = item.modifiers
            .expand((g) => g.selected.map((o) => o.name))
            .join(', ');
        if (mods.isNotEmpty) {
          bytes += generator.text(
            '   $mods',
            styles: const PosStyles(fontType: PosFontType.fontB),
          );
        }
        if (item.notes != null && item.notes!.isNotEmpty) {
          bytes += generator.text(
            '   Note: ${item.notes}',
            styles: const PosStyles(fontType: PosFontType.fontB),
          );
        }
        if (item.discountAmount != null && item.discountAmount! > 0) {
          bytes += generator.row([
            PosColumn(text: '   Discount', width: 8),
            PosColumn(
              text: '-$currency ${item.discountAmount!.toStringAsFixed(2)}',
              width: 4,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        }
      }

      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(
          text: '$currency ${receipt.subtotal.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (receipt.totalDiscount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Discount', width: 8),
          PosColumn(
            text: '-$currency ${receipt.totalDiscount.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
          text: '$currency ${receipt.total.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Payment', width: 8),
        PosColumn(
          text: _fmtMethod(receipt.paymentMethod),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (receipt.paymentMethod == 'cash') {
        bytes += generator.row([
          PosColumn(text: 'Tendered', width: 8),
          PosColumn(
            text: '$currency ${receipt.amountPaid.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.row([
          PosColumn(text: 'Change', width: 8),
          PosColumn(
            text: '$currency ${receipt.change.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else if (receipt.reference != null && receipt.reference!.isNotEmpty) {
        bytes += generator.row([
          PosColumn(text: 'Reference', width: 8),
          PosColumn(
            text: receipt.reference!,
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
