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

final encodeEscPosReceiptProvider = Provider<EncodeEscPosReceipt>((ref) {
  return EncodeEscPosReceipt();
});

class EncodeEscPosReceipt {
  Future<Uint8List> call({required Receipt receipt}) async {
    final profile = await CapabilityProfile.load();
    final logoData = await rootBundle.load(Assets.images.png.imgAdtoKart.path);
    final logoBytes = logoData.buffer.asUint8List();

    return Isolate.run(() async {
      var bytes = <int>[];
      final generator = Generator(PaperSize.mm80, profile);

      final Receipt(
        :store,
        :cashier,
        :docNumber,
        :docDate,
        :type,
        :items,
        :payment,
        :vatableSales,
        :vatExemptSales,
        :vatAmount,
        :discountAmount,
        :totalAmount,
      ) = receipt;

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
      bytes += generator.text('Cashier: ${cashier.id} ${cashier.fullName}');

      // Separator (*)
      bytes += generator.text(
        '************************************************',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Order Type
      bytes += generator.row([
        PosColumn(
          text: '---------------',
          width: 4,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: type.displayName.toUpperCase(),
          width: 4,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: '---------------',
          width: 4,
          styles: const PosStyles(align: PosAlign.center),
        ),
      ]);
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

      // Line Items Body
      for (final item in items) {
        bytes += generator.row([
          PosColumn(
            text: '${item.isMain ? '' : '   '}${item.quantity} ${item.description}',
            width: 8,
          ),
          PosColumn(
            text: item.isMain || item.grossAmount > Decimal.zero ? item.grossAmount.withCommas : '',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
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
