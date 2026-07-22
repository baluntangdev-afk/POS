import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class StoreInfoNotifier extends AsyncNotifier<StoreInfoTableData?> {
  @override
  Future<StoreInfoTableData?> build() async {
    final db = ref.watch(databaseProvider);
    await db.storeInfoDao.ensureStoreInfoExists();
    return db.storeInfoDao.getStoreInfo();
  }

  Future<void> save({
    required String storeName,
    required String address,
    required double taxRate,
    required String currency,
    required String receiptFooter,
  }) async {
    final db = ref.read(databaseProvider);
    final existing = state.value;
    await db.storeInfoDao.upsertStoreInfo(StoreInfoTableCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      storeName: Value(storeName),
      address: Value(address),
      taxRate: Value(taxRate),
      currency: Value(currency),
      receiptFooter: Value(receiptFooter),
    ));
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final storeInfoProvider =
    AsyncNotifierProvider<StoreInfoNotifier, StoreInfoTableData?>(StoreInfoNotifier.new);
