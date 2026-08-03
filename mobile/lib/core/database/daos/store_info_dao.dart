import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/store_info_table.dart';
import '../tables/payment_methods_table.dart';

part 'store_info_dao.g.dart';

@DriftAccessor(tables: [StoreInfoTable, PaymentMethodsTable])
class StoreInfoDao extends DatabaseAccessor<AppDatabase> with _$StoreInfoDaoMixin {
  StoreInfoDao(super.db);

  Future<StoreInfoTableData?> getStoreInfo() =>
      (select(storeInfoTable)..limit(1)).getSingleOrNull();

  Future<int> upsertStoreInfo(StoreInfoTableCompanion companion) =>
      into(storeInfoTable).insertOnConflictUpdate(companion);

  Future<void> ensureStoreInfoExists() async {
    final existing = await getStoreInfo();
    if (existing == null) {
      await into(storeInfoTable).insert(const StoreInfoTableCompanion());
    }
  }

  Future<List<PaymentMethodsTableData>> getAllPaymentMethods() =>
      (select(paymentMethodsTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<int> insertPaymentMethod(PaymentMethodsTableCompanion companion) =>
      into(paymentMethodsTable).insert(companion);

  Future<int> updatePaymentMethod(int id, PaymentMethodsTableCompanion companion) =>
      (update(paymentMethodsTable)..where((t) => t.id.equals(id))).write(companion);

  Future<int> deletePaymentMethod(int id) =>
      (delete(paymentMethodsTable)..where((t) => t.id.equals(id))).go();
}
