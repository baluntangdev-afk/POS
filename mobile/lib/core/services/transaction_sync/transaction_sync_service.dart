import '../../database/app_database.dart';
import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../features/live_orders/repositories/webhook_auth_repository.dart';

const kTransactionSyncJitterMax = Duration(seconds: 15);

typedef TransactionSyncOutcome = ({int syncedSales, int syncedRefunds});

typedef SyncAllProgress = ({int currentBatch, int totalBatches});

abstract final class TransactionSyncService {
  static Future<TransactionSyncOutcome> syncPending(
    AppDatabase db,
    TransactionSyncApi api,
    WebhookAuthRepository auth,
    String storeId,
  ) async {
    final saleIds = await db.salesDao.getUnsyncedSaleIds(storeId: storeId);
    final refundIds = await db.salesDao.getUnsyncedRefundIds(storeId: storeId);
    if (saleIds.isEmpty && refundIds.isEmpty) {
      return (syncedSales: 0, syncedRefunds: 0);
    }

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

    return (
      syncedSales: result.acceptedSaleIds.length,
      syncedRefunds: result.acceptedRefundIds.length,
    );
  }

  static Future<void> unsyncAll(AppDatabase db, String storeId) async {
    await db.transaction(() async {
      await db.salesDao.markAllSalesUnsynced(storeId);
      await db.salesDao.markAllRefundsUnsynced();
    });
  }

  static Future<void> unsyncAllKeepingStoreId(AppDatabase db) async {
    await db.transaction(() async {
      await db.salesDao.markAllSalesUnsyncedKeepingStoreId();
      await db.salesDao.markAllRefundsUnsynced();
    });
  }
}
