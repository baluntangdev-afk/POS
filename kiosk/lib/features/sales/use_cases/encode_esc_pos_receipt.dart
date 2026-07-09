import 'dart:isolate';

import 'package:decimal/decimal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../../gen/assets.gen.dart';
import '../../../utils/decimal_formatter.dart';
import '../entities/payment.dart';
import '../entities/receipt.dart';
import '../entities/receipt_item.dart';

final encodeEscPosReceiptProvider = Provider<EncodeEscPosReceipt>((ref) {
  return EncodeEscPosReceipt();
});

class EncodeEscPosReceipt {
  Future<Uint8List> call({required Receipt receipt}) async {
    final profile = await CapabilityProfile.load();
    final logoData = await rootBundle.load(Assets.images.cartivoLogo.path);
    final logoBytes = logoData.buffer.asUint8List();

    return Isolate.run(() async {
      var bytes = <int>[];
      final generator = Generator(PaperSize.mm80, profile);

      final Receipt(
        :store,
        :cashier,
        :docNumber,
        :docDate,
        :items,
        :payment,
        :vatableSales,
        :vatExemptSales,
        :vatAmount,
        :discountAmount,
        :totalAmount,
        :refunds,
        :isVoided,
        :voidReason,
      ) = receipt;

      final refundedQuantities = receipt.refundedQuantities;

      // Logo
      final image = img.decodeImage(logoBytes);
      if (image != null) {
        final resized = img.copyResize(image, width: 380);
        final grayscale = img.grayscale(resized);
        bytes += generator.image(grayscale);
      }
      // Reset after printing the logo to prevent formatting issues with subsequent text
      bytes += generator.reset();
      bytes += generator.feed(1);

      // Header
      bytes += generator.text(store.legalName, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(store.addressLine1, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(store.addressLine2, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);

      // TIN & Invoice Title
      bytes += generator.text('TIN: ${store.tin}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(
        'Sales Invoice',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);

      // Separator (*)
      bytes += generator.text(
        '************************************************',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Date and SI# Row
      bytes += generator.row([
        PosColumn(
          text: DateFormat.yMd().add_jm().format(docDate.toLocal()).replaceAll(RegExp(r'\s'), ' '),
          width: 6,
        ),
        PosColumn(
          text: 'SI# $docNumber',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      // Cashier
      bytes += generator.text('Cashier: ${cashier.id} - ${cashier.fullName}');

      // Separator (*)
      bytes += generator.text(
        '************************************************',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Line Items Header
      bytes += generator.row([
        PosColumn(text: 'Description', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Price',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.feed(1);

      // Line Items Body, grouped by category (mirrors receipt_screen.dart's _ItemsView)
      for (final group in _groupByCategory(items)) {
        bytes += generator.text(group.category.toUpperCase(), styles: const PosStyles(bold: true));

        for (final item in group.items) {
          final refundedQty = item.isMain ? (refundedQuantities[item.id] ?? 0) : 0;
          final isFullyRefunded = item.isMain && refundedQty >= item.quantity;
          final isPartiallyRefunded = item.isMain && refundedQty > 0 && !isFullyRefunded;

          bytes += generator.row([
            PosColumn(
              text: '${item.isMain ? '' : '   '}${item.quantity} ${item.description}',
              width: 8,
              styles: PosStyles(reverse: isFullyRefunded),
            ),
            PosColumn(
              text: item.isMain || item.grossAmount > Decimal.zero ? item.grossAmount.withCommas : '',
              width: 4,
              styles: PosStyles(align: PosAlign.right, reverse: isFullyRefunded),
            ),
          ]);

          if (item.isMain && (item.saleType != null || item.note != null)) {
            final tag = item.saleType != null ? '[${item.saleType!.displayName}] ' : '';
            bytes += generator.text('  $tag${item.note ?? ''}'.trimRight());
          }

          if (isPartiallyRefunded) {
            bytes += generator.text('  (Refunded: $refundedQty of ${item.quantity})');
          }
        }
      }

      // Separator (-)
      bytes += generator.text(
        '------------------------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Receipt Summary
      bytes += generator.row([
        PosColumn(text: 'VATable Sales', width: 6),
        PosColumn(
          text: vatableSales.withCommas,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (vatExemptSales > Decimal.zero) {
        bytes += generator.row([
          PosColumn(text: 'VAT-Exempt Sales', width: 6),
          PosColumn(
            text: vatExemptSales.withCommas,
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'VAT', width: 6),
        PosColumn(
          text: vatAmount.withCommas,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (discountAmount > Decimal.zero) {
        bytes += generator.row([
          PosColumn(text: 'Discount', width: 6),
          PosColumn(
            text: (-discountAmount).withCommas,
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.feed(1);

      // Total
      bytes += generator.row([
        PosColumn(
          text: 'Total',
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: totalAmount.withCommas,
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ),
        ),
      ]);
      bytes += generator.feed(1);

      // Refunds
      if (refunds.isNotEmpty) {
        bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += generator.feed(1);

        bytes += generator.row([
          PosColumn(text: 'REFUNDS', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: 'Amount',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);

        var totalRefund = Decimal.zero;
        for (final refund in refunds) {
          bytes += generator.text('Reason: ${refund.reason}');
          for (final ri in refund.items.where((ri) => ri.isMain)) {
            totalRefund += ri.refundAmount;
            bytes += generator.row([
              PosColumn(text: '${ri.quantity} ${ri.description}', width: 6),
              PosColumn(
                text: '-${ri.refundAmount.withCommas}',
                width: 6,
                styles: const PosStyles(align: PosAlign.right),
              ),
            ]);
          }
        }

        bytes += generator.row([
          PosColumn(text: 'Total Refund', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: '-${totalRefund.withCommas}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
        bytes += generator.feed(1);

        bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(align: PosAlign.center),
        );

        bytes += generator.row([
          PosColumn(
            text: 'Net Total',
            width: 6,
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
          ),
          PosColumn(
            text: receipt.netTotalAmount.withCommas,
            width: 6,
            styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              bold: true,
            ),
          ),
        ]);
        bytes += generator.feed(1);
      }

      // Void reason
      if (isVoided && voidReason != null) {
        bytes += generator.text(
          '------------------------------------------------',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += generator.text('VOID REASON:', styles: const PosStyles(bold: true));
        bytes += generator.text(voidReason, styles: const PosStyles(align: PosAlign.center));
        bytes += generator.feed(1);
      }

      // Payment Method & Received Amount
      switch (payment) {
        case CashPayment(:final cashReceived, :final change):
          bytes += generator.row([
            PosColumn(text: 'Cash', width: 6),
            PosColumn(
              text: cashReceived.withCommas,
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
          // Change
          bytes += generator.row([
            PosColumn(text: 'Change', width: 6),
            PosColumn(
              text: change.withCommas,
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        case CardPayment(
          :final cardType,
          :final cardNumber,
          :final paidAmount,
          :final referenceNumber,
        ):
          bytes += generator.row([
            PosColumn(text: '$cardType ($cardNumber)', width: 6),
            PosColumn(
              text: paidAmount.withCommas,
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
          bytes += generator.text(
            'Ref: $referenceNumber',
            styles: const PosStyles(align: PosAlign.center),
          );
        case QRPayment(:final walletProvider, :final paidAmount, :final referenceNumber):
          bytes += generator.row([
            PosColumn(text: walletProvider, width: 6),
            PosColumn(
              text: paidAmount.withCommas,
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
          bytes += generator.text(
            'Ref: $referenceNumber',
            styles: const PosStyles(align: PosAlign.center),
          );
        case ZeroPayment():
          bytes += generator.row([PosColumn(text: 'ZERO PAYMENT', width: 12)]);
      }

      // Footer
      bytes += generator.feed(2);
      bytes += generator.text(
        'Thank You!',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      return Uint8List.fromList(bytes);
    });
  }
}

// Groups items by their main item's category, preserving first-appearance
// order. Add-on/modifier lines stay attached to the main item that precedes
// them regardless of their own category. Uncategorized items are collected
// into an "Other" group placed last. Mirrors receipt_screen.dart's
// _ItemsView._groupByCategory so the printed receipt matches the on-screen
// preview.
class _CategoryGroup {
  const _CategoryGroup({required String? category, required this.items})
      : category = category ?? 'Other';

  final String category;
  final List<ReceiptItem> items;
}

List<_CategoryGroup> _groupByCategory(Iterable<ReceiptItem> items) {
  final clusters = <List<ReceiptItem>>[];
  for (final item in items) {
    if (item.isMain || clusters.isEmpty) {
      clusters.add([item]);
    } else {
      clusters.last.add(item);
    }
  }

  final itemsByCategory = <String?, List<ReceiptItem>>{};
  for (final cluster in clusters) {
    itemsByCategory.putIfAbsent(cluster.first.category, () => []).addAll(cluster);
  }

  final otherItems = itemsByCategory.remove(null);
  return [
    for (final entry in itemsByCategory.entries)
      _CategoryGroup(category: entry.key, items: entry.value),
    if (otherItems != null) _CategoryGroup(category: 'Other', items: otherItems),
  ];
}
