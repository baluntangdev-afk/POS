import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/clock/app_clock.dart';
import '../entities/receipt.dart';
import '../entities/refund.dart';
import '../entities/refund_item.dart';
import '../repositories/refund_repository.dart';

final processRefundProvider = Provider<ProcessRefund>((ref) {
  return ProcessRefund(ref.watch(refundRepositoryProvider), ref.watch(appClockProvider));
});

class ProcessRefund {
  const ProcessRefund(this._refundRepository, this._appClock);

  final RefundRepository _refundRepository;
  final AppClock _appClock;

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
      final refundAmount = receiptItem.refundAmountFor(entry.value);
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
      docDate: _appClock.now(),
      receiptId: receipt.id,
      reason: reason,
      method: refundMethod,
      items: refundItems,
    );

    return _refundRepository.save(refund);
  }
}
