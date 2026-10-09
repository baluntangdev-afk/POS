import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/clock/app_clock.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Sale> save(Sale sale, {required int cashierId});
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(ref.watch(databaseProvider), ref.watch(appClockProvider));
});

class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._db, this._appClock);

  final AppDatabase _db;
  final AppClock _appClock;

  @override
  Future<Sale> save(Sale sale, {required int cashierId}) async {
    try {
      final saleId = await _db.salesDao.insertPendingSale(
        cashierId: cashierId,
        sale: sale,
        now: _appClock.now(),
      );
      return sale.copyWith(id: saleId);
    } catch (e, s) {
      debugPrint('SALES ERROR ${e} ${s}');
      throw Exception(e);
    }

  }
}
