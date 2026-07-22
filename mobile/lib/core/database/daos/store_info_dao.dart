import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/store_info_table.dart';

part 'store_info_dao.g.dart';

@DriftAccessor(tables: [StoreInfoTable])
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
}
