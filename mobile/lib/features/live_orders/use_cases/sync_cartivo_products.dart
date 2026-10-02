import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/cartivo_products_dao.dart';
import '../../../core/providers/database_provider.dart';
import 'cartivo_pos_error.dart';
import 'fetch_all_cartivo_products.dart';

final syncCartivoProductsProvider = Provider<SyncCartivoProducts>((ref) {
  return SyncCartivoProducts(
    ref.watch(fetchAllCartivoProductsProvider),
    ref.watch(databaseProvider).cartivoProductsDao,
  );
});

/// Downloads the merchant's Cartivo catalog and saves it locally.
///
/// Runs a delta sync from the saved watermark, or a full sync (which also
/// drops products Cartivo removed) on the first run and once a day after.
/// Failures are recorded on the sync-state row instead of thrown.
class SyncCartivoProducts {
  const SyncCartivoProducts(
    this._fetchAll,
    this._dao, {
    this.fullSyncEvery = const Duration(hours: 24),
  });

  final FetchAllCartivoProducts _fetchAll;
  final CartivoProductsDao _dao;
  final Duration fullSyncEvery;

  Future<void> call(
    String merchantId, {
    CartivoSyncProgress? onProgress,
  }) async {
    final now = DateTime.now();
    final state = await _dao.getSyncState(merchantId);
    final lastFull = state?.lastFullSyncAt;
    final full =
        state?.watermark == null ||
        lastFull == null ||
        now.difference(lastFull) > fullSyncEvery;

    await _dao.markSyncing(merchantId);
    try {
      final result = await _fetchAll(
        merchantId,
        updatedSince: full ? null : state!.watermark,
        onProgress: onProgress,
      );
      await _dao.saveSync(
        merchantId: merchantId,
        products: [
          for (final p in result.products)
            CartivoProductsTableCompanion.insert(
              productId: Value(p.productId),
              merchantId: merchantId,
              name: p.name,
              category: Value(p.category),
              imageUrl: Value(p.imageUrl),
              updatedAt: p.updatedAt,
            ),
        ],
        variants: [
          for (final p in result.products)
            for (final v in p.variants)
              CartivoProductVariantsTableCompanion.insert(
                variantId: Value(v.variantId),
                productId: p.productId,
                sku: v.sku,
                variantName: v.variantName,
                price: v.price,
                availableQuantity: v.availableQuantity,
                isAvailable: v.isAvailable,
                updatedAt: v.updatedAt,
              ),
        ],
        watermark: result.watermark,
        full: full,
        syncedAt: now,
      );
    } catch (error) {
      await _dao.markFailed(merchantId, _messageFrom(error));
    }
  }

  String _messageFrom(Object error) => error is CartivoProductsSyncException
      ? error.message
      : cartivoPosFailureFrom(error).message;
}
