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
    required String storeId,
    required String storeName,
    required String address,
    required double taxRate,
    required String currency,
    required String receiptFooter,
    required String tin,
    required String terminalName,
  }) async {
    final db = ref.read(databaseProvider);
    final existing = state.value;
    await db.storeInfoDao.upsertStoreInfo(StoreInfoTableCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      storeId: Value(storeId),
      storeName: Value(storeName),
      address: Value(address),
      taxRate: Value(taxRate),
      currency: Value(currency),
      receiptFooter: Value(receiptFooter),
      tin: Value(tin),
      terminalName: Value(terminalName),
    ));
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final storeInfoProvider =
    AsyncNotifierProvider<StoreInfoNotifier, StoreInfoTableData?>(StoreInfoNotifier.new);

class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethodsTableData>> {
  @override
  Future<List<PaymentMethodsTableData>> build() {
    final db = ref.watch(databaseProvider);
    return db.storeInfoDao.getAllPaymentMethods();
  }

  Future<void> create({
    required String label,
    String? accountName,
    String? accountNumber,
  }) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.insertPaymentMethod(PaymentMethodsTableCompanion.insert(
      label: label,
      accountName: Value(accountName),
      accountNumber: Value(accountNumber),
    ));
    await refresh();
  }

  Future<void> edit({
    required int id,
    required String label,
    String? accountName,
    String? accountNumber,
  }) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.updatePaymentMethod(
      id,
      PaymentMethodsTableCompanion(
        label: Value(label),
        accountName: Value(accountName),
        accountNumber: Value(accountNumber),
      ),
    );
    await refresh();
  }

  Future<void> delete(int id) async {
    final db = ref.read(databaseProvider);
    await db.storeInfoDao.deletePaymentMethod(id);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethodsTableData>>(
        PaymentMethodsNotifier.new);
