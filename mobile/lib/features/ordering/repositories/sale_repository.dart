import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Sale> save(Sale sale, {required int cashierId});
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(ref.watch(databaseProvider));
});

class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Sale> save(Sale sale, {required int cashierId}) async {
    final saleId = await _db.salesDao.insertPendingSale(cashierId: cashierId, sale: sale);
    return sale.copyWith(id: saleId);
  }
}
