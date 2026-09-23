import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/merchant_table.dart';

part 'merchant_dao.g.dart';

@DriftAccessor(tables: [MerchantTable])
class MerchantDao extends DatabaseAccessor<AppDatabase>
    with _$MerchantDaoMixin {
  MerchantDao(super.db);

  // Ordered by id DESC: onboarding can run more than once (e.g. re-registering
  // a device under a new merchant), and `insertMerchant` used to leave the old
  // row behind. A bare `LIMIT 1` with no ORDER BY then returned whichever row
  // SQLite's table scan happened to hit first — the stale one — so requests
  // went out scoped to a merchant the device was no longer registered under.
  Future<MerchantTableData?> getMerchant() => (select(merchantTable)
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
        ..limit(1))
      .getSingleOrNull();

  /// Replaces the single merchant row. Deletes any existing rows first so the
  /// table never accumulates stale entries from repeated onboarding.
  Future<int> insertMerchant(MerchantTableCompanion companion) =>
      transaction(() async {
        await delete(merchantTable).go();
        return into(merchantTable).insert(companion);
      });
}
