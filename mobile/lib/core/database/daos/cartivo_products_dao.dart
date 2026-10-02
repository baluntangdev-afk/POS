import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cartivo_product_variants_table.dart';
import '../tables/cartivo_products_table.dart';
import '../tables/cartivo_sync_state_table.dart';

part 'cartivo_products_dao.g.dart';

@DriftAccessor(
  tables: [CartivoProductsTable, CartivoProductVariantsTable, CartivoSyncStateTable],
)
class CartivoProductsDao extends DatabaseAccessor<AppDatabase>
    with _$CartivoProductsDaoMixin {
  CartivoProductsDao(super.db);

  static const _chunk = 500;

  Future<CartivoSyncStateTableData?> getSyncState(String merchantId) {
    return (select(cartivoSyncStateTable)
          ..where((t) => t.merchantId.equals(merchantId)))
        .getSingleOrNull();
  }

  Stream<CartivoSyncStateTableData?> watchSyncState(String merchantId) {
    return (select(cartivoSyncStateTable)
          ..where((t) => t.merchantId.equals(merchantId)))
        .watchSingleOrNull();
  }

  Stream<int> watchProductCount(String merchantId) {
    final count = cartivoProductsTable.productId.count();
    final query = selectOnly(cartivoProductsTable)
      ..addColumns([count])
      ..where(cartivoProductsTable.merchantId.equals(merchantId));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<CartivoProductsTableData>> getProducts(String merchantId) {
    return (select(cartivoProductsTable)
          ..where((t) => t.merchantId.equals(merchantId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<CartivoProductVariantsTableData>> getVariantsForMerchant(
    String merchantId,
  ) {
    final ids = selectOnly(cartivoProductsTable)
      ..addColumns([cartivoProductsTable.productId])
      ..where(cartivoProductsTable.merchantId.equals(merchantId));
    return (select(cartivoProductVariantsTable)
          ..where((t) => t.productId.isInQuery(ids)))
        .get();
  }

  Future<void> markSyncing(String merchantId) {
    return into(cartivoSyncStateTable).insert(
      CartivoSyncStateTableCompanion.insert(
        merchantId: merchantId,
        status: const Value(CartivoSyncStatus.syncing),
      ),
      onConflict: DoUpdate(
        (_) => const CartivoSyncStateTableCompanion(
          status: Value(CartivoSyncStatus.syncing),
          lastError: Value(null),
        ),
        target: [cartivoSyncStateTable.merchantId],
      ),
    );
  }

  Future<void> markFailed(String merchantId, String message) {
    return into(cartivoSyncStateTable).insert(
      CartivoSyncStateTableCompanion.insert(
        merchantId: merchantId,
        status: const Value(CartivoSyncStatus.failed),
        lastError: Value(message),
      ),
      onConflict: DoUpdate(
        (_) => CartivoSyncStateTableCompanion(
          status: const Value(CartivoSyncStatus.failed),
          lastError: Value(message),
        ),
        target: [cartivoSyncStateTable.merchantId],
      ),
    );
  }

  /// Saves one finished sync atomically. A [full] sync replaces the merchant's
  /// whole catalog (dropping products Cartivo no longer has); a delta only
  /// upserts the products it returned.
  Future<void> saveSync({
    required String merchantId,
    required List<CartivoProductsTableCompanion> products,
    required List<CartivoProductVariantsTableCompanion> variants,
    required DateTime watermark,
    required bool full,
    required DateTime syncedAt,
  }) {
    return transaction(() async {
      if (full) {
        final ids = selectOnly(cartivoProductsTable)
          ..addColumns([cartivoProductsTable.productId])
          ..where(cartivoProductsTable.merchantId.equals(merchantId));
        await (delete(cartivoProductVariantsTable)
              ..where((t) => t.productId.isInQuery(ids)))
            .go();
        await (delete(cartivoProductsTable)
              ..where((t) => t.merchantId.equals(merchantId)))
            .go();
      } else {
        final ids = [for (final p in products) p.productId.value];
        for (var i = 0; i < ids.length; i += _chunk) {
          final slice = ids.sublist(i, i + _chunk > ids.length ? ids.length : i + _chunk);
          await (delete(cartivoProductVariantsTable)
                ..where((t) => t.productId.isIn(slice)))
              .go();
        }
      }

      await batch((b) {
        b.insertAllOnConflictUpdate(cartivoProductsTable, products);
        b.insertAllOnConflictUpdate(cartivoProductVariantsTable, variants);
      });

      await into(cartivoSyncStateTable).insert(
        CartivoSyncStateTableCompanion.insert(
          merchantId: merchantId,
          watermark: Value(watermark),
          lastFullSyncAt: full ? Value(syncedAt) : const Value.absent(),
          status: const Value(CartivoSyncStatus.idle),
        ),
        onConflict: DoUpdate(
          (_) => CartivoSyncStateTableCompanion(
            watermark: Value(watermark),
            lastFullSyncAt: full ? Value(syncedAt) : const Value.absent(),
            status: const Value(CartivoSyncStatus.idle),
            lastError: const Value(null),
          ),
          target: [cartivoSyncStateTable.merchantId],
        ),
      );
    });
  }
}
