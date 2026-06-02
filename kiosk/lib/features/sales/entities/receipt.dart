import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../enums/sale_type.dart';
import 'cashier.dart';
import 'payment.dart';
import 'receipt_item.dart';
import 'refund.dart';
import 'store.dart';

part 'receipt.mapper.dart';

@MappableClass()
class Receipt with ReceiptMappable {
  const Receipt({
    required this.id,
    required this.store,
    required this.cashier,
    required this.docNumber,
    required this.docDate,
    required this.type,
    required this.payment,
    required this.items,
    this.refunds = const IList.empty(),
    this.refundedAmount,
    this.isVoided = false,
    this.voidReason,
    this.voidedAt,
  });

  final String id;
  final Store store;
  final Cashier cashier;
  final String docNumber;
  final DateTime docDate;
  final SaleType type;
  final Payment payment;
  final IList<ReceiptItem> items;
  final IList<Refund> refunds;
  final Decimal? refundedAmount;
  final bool isVoided;
  final String? voidReason;
  final DateTime? voidedAt;

  Decimal get grossAmount => items.fold(Decimal.zero, (total, item) => total + item.grossAmount);

  Decimal get vatableSales => items
      .where((item) => item.vatAmount > Decimal.zero)
      .fold(Decimal.zero, (total, item) => total + item.vatExclusiveAmount);

  Decimal get vatExemptSales => items
      .where((item) => item.vatAmount == Decimal.zero)
      .fold(Decimal.zero, (total, item) => total + item.vatExclusiveAmount);

  Decimal get vatAmount => items.fold(Decimal.zero, (total, item) => total + item.vatAmount);

  Decimal get discountAmount =>
      items.fold(Decimal.zero, (total, item) => total + item.discountAmount);

  Decimal get totalAmount => items.fold(Decimal.zero, (total, item) => total + item.totalAmount);

  bool get hasRefunds =>
      refunds.isNotEmpty || (refundedAmount != null && refundedAmount! > Decimal.zero);

  Decimal get netTotalAmount {
    if (refunds.isNotEmpty) {
      final totalRefunded = refunds.fold(Decimal.zero, (sum, refund) {
        return sum +
            refund.items
                .where((ri) => ri.isMain)
                .fold(Decimal.zero, (s, ri) => s + ri.refundAmount);
      });
      return totalAmount - totalRefunded;
    }
    if (refundedAmount != null) return totalAmount - refundedAmount!;
    return totalAmount;
  }

  Map<String, int> get refundedQuantities {
    final result = <String, int>{};
    for (final refund in refunds) {
      for (final ri in refund.items) {
        result[ri.receiptItemId] = (result[ri.receiptItemId] ?? 0) + ri.quantity;
      }
    }
    return result;
  }

  bool get isFullyRefunded {
    final mainItems = items.where((item) => item.isMain).toList();
    if (mainItems.isEmpty || refunds.isEmpty) return false;
    for (final mainItem in mainItems) {
      final refunded = refunds.fold<int>(0, (sum, refund) {
        return sum +
            refund.items
                .where((ri) => ri.receiptItemId == mainItem.id && ri.isMain)
                .fold<int>(0, (s, ri) => s + ri.quantity);
      });
      if (refunded < mainItem.quantity) return false;
    }
    return true;
  }

  IList<({ReceiptItem mainItem, IList<ReceiptItem> addOns})> get mainItemsWithAddOns {
    final grouped = <int, ({ReceiptItem mainItem, IList<ReceiptItem> addOns})>{};

    for (final item in items) {
      final current = grouped[item.sequence];
      if (item.isMain) {
        grouped[item.sequence] = (mainItem: item, addOns: current?.addOns ?? const IList.empty());
      } else {
        grouped[item.sequence] = (
          mainItem: current?.mainItem ?? item,
          addOns: current?.addOns.add(item) ?? const IList.empty(),
        );
      }
    }

    final sortedEntries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sortedEntries.map((entry) => entry.value).toIList();
  }
}
