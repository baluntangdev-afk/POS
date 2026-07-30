import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

final voidSaleProvider = Provider<VoidSale>((ref) => VoidSale(ref.watch(databaseProvider)));

class VoidSale {
  const VoidSale(this._db);

  final AppDatabase _db;

  Future<void> call({required int saleId, required String reason}) {
    return _db.salesDao.voidSale(saleId, reason: reason);
  }
}
