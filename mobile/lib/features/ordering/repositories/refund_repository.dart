import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/refund.dart';

abstract class RefundRepository {
  Future<Refund> save(Refund refund);
}

final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  return RefundRepositoryImpl(ref.watch(databaseProvider));
});

class RefundRepositoryImpl implements RefundRepository {
  const RefundRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Refund> save(Refund refund) async {
    final refundId = await _db.salesDao.insertRefundRecord(
      saleId: refund.receiptId,
      reason: refund.reason,
      method: refund.method,
      total: refund.items.fold(0.0, (s, i) => s + i.refundAmount),
      items: refund.items
          .map((i) => (saleItemId: i.receiptItemId, qty: i.quantity, amount: i.refundAmount))
          .toList(),
    );
    return refund.copyWith(id: refundId, docNumber: 'RF-${refundId.toString().padLeft(6, '0')}');
  }
}
