import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/tax_calculator.dart';
import '../../../utils/uuidv7.dart';
import '../entities/cashier.dart';
import '../entities/discount.dart';
import '../entities/line_item.dart';
import '../entities/receipt.dart';
import '../entities/receipt_item.dart';
import '../entities/sale.dart';
import '../entities/selected_modifier.dart';
import '../entities/store.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/sale_repository.dart';

final finalizeSaleProvider = Provider<FinalizeSale>((ref) {
  final saleRepository = ref.watch(saleRepositoryProvider);
  final receiptRepository = ref.watch(receiptRepositoryProvider);
  return FinalizeSale(saleRepository, receiptRepository);
});

class FinalizeSale {
  const FinalizeSale(this._saleRepository, this._receiptRepository);

  final SaleRepository _saleRepository;
  final ReceiptRepository _receiptRepository;

  Future<Receipt> call(Sale sale, {required Store store, required Cashier cashier}) async {
    if (sale.payment == null) throw 'Payment is required to finalize sale.';

    final actualSale = await _saleRepository.save(sale);
    final draftReceipt = _receiptFromSale(actualSale, store: store, cashier: cashier);
    return _receiptRepository.save(draftReceipt);
  }

  Receipt _receiptFromSale(Sale sale, {required Store store, required Cashier cashier}) {
    final receiptItems = <ReceiptItem>[];
    var sequence = 1;

    for (final item in sale.items) {
      // Main item
      receiptItems.add(_receiptItemFromLineItem(item, sequence: sequence));
      // Modifiers as separate receipt items
      for (final modifier in item.modifiers) {
        receiptItems.addAll(
          _receiptItemIListFromSelectedModifier(modifier, sequence: sequence, lineItem: item),
        );
      }
      sequence++;
    }

    return Receipt(
      id: sale.id,
      store: store,
      cashier: cashier,
      docNumber: sale.soNumber,
      docDate: sale.createdAt,
      type: sale.type,
      payment: sale.payment!,
      items: receiptItems.toIList(),
    );
  }

  ReceiptItem _receiptItemFromLineItem(LineItem lineItem, {required int sequence}) {
    final id = lineItem.id;
    final description = '${lineItem.variant.name} ${lineItem.productName}';

    final quantity = lineItem.quantity;
    final unitPrice = lineItem.variant.price;
    final grossAmount = Decimal.fromInt(quantity) * unitPrice;

    final discountCode = lineItem.discount?.code ?? '';
    final discountRate = switch (lineItem.discount) {
      final PercentageDiscount discount => discount.rate,
      final SeniorPwdDiscount discount => discount.rate,
      _ => Decimal.zero,
    };
    final discountAmount = lineItem.discount?.calculateAmount(grossAmount) ?? Decimal.zero;

    final isVatExempt = lineItem.isVatExempt;
    final vatExclusiveAmount = grossAmount.vatableAmount;
    final vatAmount = isVatExempt ? Decimal.zero : grossAmount.vatAmount;

    final totalAmount = vatExclusiveAmount + vatAmount - discountAmount;

    return ReceiptItem(
      id: id,
      sequence: sequence,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      grossAmount: grossAmount,
      discountCode: discountCode,
      discountRate: discountRate,
      discountAmount: discountAmount,
      vatExclusiveAmount: vatExclusiveAmount,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      isMain: true,
    );
  }

  IList<ReceiptItem> _receiptItemIListFromSelectedModifier(
    SelectedModifier modifier, {
    required int sequence,
    required LineItem lineItem,
  }) {
    final discountCode = lineItem.discount?.code ?? '';
    final discountRate = switch (lineItem.discount) {
      final PercentageDiscount discount => discount.rate,
      final SeniorPwdDiscount discount => discount.rate,
      _ => Decimal.zero,
    };

    return modifier.options.map((option) {
      final id = UuidV7.generate();
      final description = option.name;

      final quantity = lineItem.quantity;
      final unitPrice = option.price;
      final grossAmount = Decimal.fromInt(quantity) * unitPrice;

      final discountAmount = switch (lineItem.discount) {
        FixedAmountDiscount() => Decimal.zero, // Fixed discounts don't apply to add-ons
        final discount => discount?.calculateAmount(grossAmount) ?? Decimal.zero,
      };

      final isVatExempt = lineItem.isVatExempt;
      final vatExclusiveAmount = grossAmount.vatableAmount;
      final vatAmount = isVatExempt ? Decimal.zero : grossAmount.vatAmount;

      final totalAmount = vatExclusiveAmount + vatAmount - discountAmount;

      return ReceiptItem(
        id: id,
        sequence: sequence,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        grossAmount: grossAmount,
        discountCode: discountCode,
        discountRate: discountRate,
        discountAmount: discountAmount,
        vatExclusiveAmount: vatExclusiveAmount,
        vatAmount: vatAmount,
        totalAmount: totalAmount,
        isMain: false,
      );
    }).toIList();
  }
}
