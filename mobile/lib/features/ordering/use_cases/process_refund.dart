import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/receipt.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';
import '../repositories/refund_repository.dart';

final processRefundProvider = Provider<ProcessRefund>((ref) {
  return ProcessRefund(ref.watch(refundRepositoryProvider));
});

class ProcessRefund {
  const ProcessRefund(this._refundRepository);

  final RefundRepository _refundRepository;

  Future<Refund> call({
    required Receipt receipt,
    required Map<int, int> selectedQuantities,
    required String reason,
    required String refundMethod,
  }) async {
    final refundItems = <RefundItem>[];
    for (final entry in selectedQuantities.entries) {
      if (entry.value <= 0) continue;
      final receiptItem = receipt.items.firstWhere((i) => i.id == entry.key);
      final refundAmount = receiptItem.unitPrice * entry.value;
      refundItems.add(RefundItem(
        id: 0,
        receiptItemId: receiptItem.id,
        sequence: receiptItem.sequence,
        description: receiptItem.description,
        quantity: entry.value,
        refundAmount: refundAmount,
        isMain: receiptItem.isMain,
      ));
    }

    final refund = Refund(
      id: 0,
      docNumber: '',
      docDate: DateTime.now(),
      receiptId: receipt.id,
      reason: reason,
      method: refundMethod,
      items: refundItems,
    );

    return _refundRepository.save(refund);
  }
}
