import '../../database/app_database.dart';
import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../features/live_orders/repositories/webhook_auth_repository.dart';

/// Upper bound on the random delay applied before every sync attempt
/// (periodic tick and reconnect trigger alike), so devices whose ticks
/// happen to align — or that all reconnect after a shared outage — don't
/// all hit the sync endpoint in the same instant.
const kTransactionSyncJitterMax = Duration(seconds: 15);

/// One attempt to push everything currently unsynced, capped at
/// [SalesDao.getUnsyncedSaleIds]/[getUnsyncedRefundIds]'s default 15-per-table
/// limit. Called by both the periodic worker and the reconnect listener —
/// this is the only place sync logic lives.
///
/// Throws on any failure (auth or network) so the caller decides how to
/// react; per the design doc this is always "do nothing, let the next tick
/// retry" — no row is marked synced unless the server actually accepted it.
abstract final class TransactionSyncService {
  static Future<void> syncPending(
    AppDatabase db,
    TransactionSyncApi api,
    WebhookAuthRepository auth,
    String storeId,
  ) async {
    final saleIds = await db.salesDao.getUnsyncedSaleIds();
    final refundIds = await db.salesDao.getUnsyncedRefundIds();
    if (saleIds.isEmpty && refundIds.isEmpty) return;

    await auth.ensureToken(storeId);

    final sales = [
      for (final id in saleIds) await db.salesDao.getSaleSyncPayload(id),
    ];
    final refunds = [
      for (final id in refundIds) await db.salesDao.getRefundSyncPayload(id),
    ];

    final result = await api.pushBatch(
      storeId: storeId,
      sales: sales,
      refunds: refunds,
    );

    await db.transaction(() async {
      await db.salesDao.markSalesSynced(result.acceptedSaleIds);
      await db.salesDao.markRefundsSynced(result.acceptedRefundIds);
    });
  }
}
