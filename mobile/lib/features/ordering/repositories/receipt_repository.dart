import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/receipt.dart';

abstract class ReceiptRepository {
  Future<Receipt> save(int saleId);
  Future<Receipt?> getById(int saleId);
}

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl(ref.watch(databaseProvider));
});

class ReceiptRepositoryImpl implements ReceiptRepository {
  const ReceiptRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Receipt> save(int saleId) async {
    await _db.salesDao.completeSale(saleId);
    final receipt = await _db.salesDao.getReceiptById(saleId);
    if (receipt == null) {
      throw StateError('Sale $saleId not found after completing it.');
    }
    return receipt;
  }

  @override
  Future<Receipt?> getById(int saleId) => _db.salesDao.getReceiptById(saleId);
}
