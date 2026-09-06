import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/merchant_table.dart';

part 'merchant_dao.g.dart';

@DriftAccessor(tables: [MerchantTable])
class MerchantDao extends DatabaseAccessor<AppDatabase>
    with _$MerchantDaoMixin {
  MerchantDao(super.db);

  Future<MerchantTableData?> getMerchant() =>
      (select(merchantTable)..limit(1)).getSingleOrNull();

  Future<int> insertMerchant(MerchantTableCompanion companion) =>
      into(merchantTable).insert(companion);
}
