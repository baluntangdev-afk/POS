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
