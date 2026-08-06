import 'receipt_item.dart';
import 'refund.dart';
import 'sale_payment.dart';

class Receipt {
  final int id;
  final int cashierId;
  final String storeName;
  final String cashierName;
  final String docNumber;
  final DateTime docDate;
  final String type;
  final SalePayment payment;
  final List<ReceiptItem> items;
  final List<Refund> refunds;
  final bool isVoided;
  final String? voidReason;
  final bool voidLocked;

  const Receipt({
    required this.id,
    required this.cashierId,
    required this.storeName,
    required this.cashierName,
    required this.docNumber,
    required this.docDate,
    required this.type,
    required this.payment,
    required this.items,
    this.refunds = const [],
    this.isVoided = false,
    this.voidReason,
    this.voidLocked = false,
  });

  double get grossAmount => items.fold(0.0, (s, i) => s + i.grossAmount);
  double get discountAmount => items.fold(0.0, (s, i) => s + i.discountAmount);
  double get totalAmount => items.fold(0.0, (s, i) => s + i.totalAmount);

  double get vatableAmount =>
      items.where((i) => !i.isVatExempt).fold(0.0, (s, i) => s + i.vatExclusiveAmount);
  double get vatAmount => items.fold(0.0, (s, i) => s + i.vatAmount);
  double get vatExemptSales =>
      items.where((i) => i.isVatExempt).fold(0.0, (s, i) => s + i.vatExclusiveAmount);

  bool get hasRefunds => refunds.isNotEmpty;

  double get refundedAmount => refunds.fold(
        0.0,
        (sum, r) => sum + r.items.where((ri) => ri.isMain).fold(0.0, (s, ri) => s + ri.refundAmount),
      );

  double get netTotalAmount => totalAmount - refundedAmount;

  Map<int, int> get refundedQuantities {
    final result = <int, int>{};
    for (final refund in refunds) {
      for (final ri in refund.items) {
        result[ri.receiptItemId] = (result[ri.receiptItemId] ?? 0) + ri.quantity;
      }
    }
    return result;
  }

  bool get isFullyRefunded {
    final mainItems = items.where((i) => i.isMain).toList();
    if (mainItems.isEmpty || refunds.isEmpty) return false;
    final refunded = refundedQuantities;
    for (final item in mainItems) {
      if ((refunded[item.id] ?? 0) < item.quantity) return false;
    }
    return true;
  }

  List<({ReceiptItem mainItem, List<ReceiptItem> addOns})> get mainItemsWithAddOns {
    final grouped = <int, ({ReceiptItem mainItem, List<ReceiptItem> addOns})>{};
    for (final item in items) {
      final current = grouped[item.sequence];
      if (item.isMain) {
        grouped[item.sequence] = (mainItem: item, addOns: current?.addOns ?? const []);
      } else {
        grouped[item.sequence] = (
          mainItem: current?.mainItem ?? item,
          addOns: [...current?.addOns ?? const [], item],
        );
      }
    }
    final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).toList();
  }
}
