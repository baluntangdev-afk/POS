import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/decimal_rounding.dart';
import '../../../utils/uuidv7.dart';
import '../entities/payment.dart';
import '../entities/receipt.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';
import '../repositories/refund_repository.dart';

final processRefundProvider = Provider<ProcessRefund>((ref) {
  final refundRepository = ref.watch(refundRepositoryProvider);
  return ProcessRefund(refundRepository);
});

class ProcessRefund {
  const ProcessRefund(this._refundRepository);

  final RefundRepository _refundRepository;

  Future<Refund> call({
    required Receipt receipt,
    required Map<String, int> selectedQuantities,
    required String reason,
    required String refundMethod,
  }) async {
    final refundItems = _createRefundItems(receipt, selectedQuantities);
    final payment = _createPaymentFromMethod(
      refundMethod,
      _calculateTotalRefundAmount(refundItems),
    );

    final refund = Refund(
      id: UuidV7.generate(),
      docNumber: '', // Will be generated when refund is successfully processed
      docDate: DateTime.now(),
      receiptId: receipt.id,
      reason: reason,
      payment: payment,
      items: refundItems.toIList(),
    );

    return _refundRepository.save(refund);
  }

  List<RefundItem> _createRefundItems(Receipt receipt, Map<String, int> selectedQuantities) {
    final refundItems = <RefundItem>[];

    for (final entry in selectedQuantities.entries) {
      final receiptItemId = entry.key;
      final quantity = entry.value;

      final receiptItem = receipt.items.firstWhere((item) => item.id == receiptItemId);
      final unitPrice = (receiptItem.totalAmount / Decimal.fromInt(receiptItem.quantity))
          .toDecimal(scaleOnInfinitePrecision: 2)
          .toPrecision(2);
      final refundAmount = unitPrice * Decimal.fromInt(quantity);

      refundItems.add(
        RefundItem(
          id: UuidV7.generate(),
          receiptItemId: receiptItemId,
          sequence: receiptItem.sequence,
          description: receiptItem.description,
          quantity: quantity,
          refundAmount: refundAmount,
          isMain: receiptItem.isMain,
        ),
      );
    }

    return refundItems;
  }

  Decimal _calculateTotalRefundAmount(List<RefundItem> refundItems) {
    return refundItems.fold(Decimal.zero, (sum, item) => sum + item.refundAmount);
  }

  Payment _createPaymentFromMethod(String method, Decimal amount) {
    switch (method) {
      case 'Cash Refund':
        return CashPayment(paidAmount: amount, cashReceived: amount);
      case 'Card Refund':
        return CardPayment(
          paidAmount: amount,
          referenceNumber: '',
          cardType: 'Credit',
          cardNumber: '0000',
        );
      case 'E-wallet Refund':
        return QRPayment(paidAmount: amount, referenceNumber: '', walletProvider: 'GCash');
      default:
        return CashPayment(paidAmount: amount, cashReceived: amount);
    }
  }
}
