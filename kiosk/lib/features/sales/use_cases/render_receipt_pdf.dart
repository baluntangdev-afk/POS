import 'dart:isolate';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/history/pdf_document_builder.dart';
import '../../../utils/decimal_formatter.dart';
import '../entities/payment.dart';
import '../entities/receipt.dart';
import '../entities/receipt_item.dart';

final renderReceiptPdfProvider = Provider<RenderReceiptPdf>((ref) {
  return RenderReceiptPdf();
});

/// Renders a [Receipt] to a History-archive PDF. Content mirrors
/// `encode_esc_pos_receipt.dart` (same data, different output) -- kept in sync manually
/// since ESC/POS and PDF have no shared renderer to derive from.
class RenderReceiptPdf {
  Future<Uint8List> call({required Receipt receipt, String? serialNumber}) async {
    return Isolate.run(() async {
      final b = PdfDocumentBuilder();

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

      b.text(store.legalName, bold: true);
      b.text(store.addressLine1);
      b.text(store.addressLine2);
      b.spacing();
      b.text('TIN: ${store.tin}');
      if (serialNumber != null) b.text('S/N: $serialNumber');
      b.text('Sales Invoice', bold: true, fontSize: 12);
      b.spacing();

      b.row(DateFormat.yMd().add_jm().format(docDate.toLocal()), 'SI# $docNumber', bold: true);
      b.text('Cashier: ${cashier.id} - ${cashier.fullName}', center: false);
      b.divider();

      b.tableRow(['Description', 'Price'], flex: const [3, 1], bold: true);
      for (final group in _groupByCategory(items)) {
        b.text(group.category.toUpperCase(), bold: true, center: false);
        for (final item in group.items) {
          final refundedQty = item.isMain ? (refundedQuantities[item.id] ?? 0) : 0;
          final isFullyRefunded = item.isMain && refundedQty >= item.quantity;
          final prefix = item.isMain ? '' : '   ';
          final amountText = item.isMain || item.grossAmount > Decimal.zero
              ? item.grossAmount.withCommas
              : '';
          b.tableRow(
            ['$prefix${item.quantity} ${item.description}', amountText],
            flex: const [3, 1],
          );
          if (isFullyRefunded) b.text('  (Fully refunded)', center: false, fontSize: 8);
          if (item.isMain && item.discountBeneficiaryName != null) {
            final discountLabel = item.discountCode.isNotEmpty ? item.discountCode : 'Senior Citizen / PWD';
            b.text(
              '  LESS: $discountLabel - ${item.discountBeneficiaryName} (${item.discountBeneficiaryIdNumber})',
              center: false,
              fontSize: 8,
            );
          }
        }
      }
      b.divider();

      b.row('VATable Sales', vatableSales.withCommas);
      if (vatExemptSales > Decimal.zero) b.row('VAT-Exempt Sales', vatExemptSales.withCommas);
      b.row('VAT', vatAmount.withCommas);
      if (discountAmount > Decimal.zero) b.row('Discount', (-discountAmount).withCommas);
      b.spacing();
      b.row('Total', totalAmount.withCommas, bold: true, fontSize: 12);
      b.spacing();

      if (refunds.isNotEmpty) {
        b.divider();
        b.text('REFUNDS', bold: true, center: false);
        var totalRefund = Decimal.zero;
        for (final refund in refunds) {
          b.text('Reason: ${refund.reason}', center: false, fontSize: 8);
          for (final ri in refund.items.where((ri) => ri.isMain)) {
            totalRefund += ri.refundAmount;
            b.row('${ri.quantity} ${ri.description}', '-${ri.refundAmount.withCommas}');
          }
        }
        b.row('Total Refund', '-${totalRefund.withCommas}', bold: true);
        b.divider();
        b.row('Net Total', receipt.netTotalAmount.withCommas, bold: true, fontSize: 12);
      }

      if (isVoided && voidReason != null) {
        b.divider();
        b.text('VOID REASON:', bold: true);
        b.text(voidReason);
      }

      switch (payment) {
        case CashPayment(:final cashReceived, :final change):
          b.row('Cash', cashReceived.withCommas);
          b.row('Change', change.withCommas);
        case CardPayment(:final cardType, :final cardNumber, :final paidAmount, :final referenceNumber):
          b.row('$cardType ($cardNumber)', paidAmount.withCommas);
          b.text('Ref: $referenceNumber');
        case QRPayment(:final walletProvider, :final paidAmount, :final referenceNumber):
          b.row(walletProvider, paidAmount.withCommas);
          b.text('Ref: $referenceNumber');
        case ZeroPayment():
          b.text('ZERO PAYMENT');
      }

      b.spacing();
      b.text('Thank You!', bold: true, fontSize: 12);

      return b.build();
    });
  }
}

// Mirrors encode_esc_pos_receipt.dart's _groupByCategory so the History PDF matches the
// printed receipt's grouping exactly. See that file for the grouping rationale.
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
