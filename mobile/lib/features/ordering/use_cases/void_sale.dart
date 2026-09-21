import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/clock/app_clock.dart';

final voidSaleProvider = Provider<VoidSale>(
  (ref) => VoidSale(ref.watch(databaseProvider), ref.watch(appClockProvider)),
);

class VoidSale {
  const VoidSale(this._db, this._appClock);

  final AppDatabase _db;
  final AppClock _appClock;

  Future<void> call({required int saleId, required String reason}) {
    return _db.salesDao.voidSale(saleId, now: _appClock.now(), reason: reason);
  }
}
