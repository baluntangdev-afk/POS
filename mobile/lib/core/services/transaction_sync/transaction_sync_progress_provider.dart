import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../features/live_orders/repositories/webhook_auth_repository.dart';
import '../../database/app_database.dart';
import 'transaction_sync_service.dart';

/// Drains every pending sale/refund batch-by-batch, publishing [SyncAllProgress]
/// as it goes so any screen — not just the one that started the run — can show
/// a live indicator. Shared across features (Transactions triggers it,
/// Dashboard just watches it), so it lives in `core/`, like
/// `connectivity_status_provider.dart`.
class TransactionSyncProgressNotifier extends Notifier<SyncAllProgress?> {
  @override
  SyncAllProgress? build() => null;

  Future<TransactionSyncOutcome> syncAll({
    required AppDatabase db,
    required TransactionSyncApi api,
    required WebhookAuthRepository auth,
    required String storeId,
  }) async {
    if (state != null) return (syncedSales: 0, syncedRefunds: 0);

    var total = (syncedSales: 0, syncedRefunds: 0);
    try {
      var batch = 0;
      while (true) {
        final salesPending = await db.salesDao.getUnsyncedSaleCount(
          storeId: storeId,
        );
        final refundsPending = await db.salesDao.getUnsyncedRefundCount(
          storeId: storeId,
        );
        if (salesPending == 0 && refundsPending == 0) break;

        batch++;
        final remaining =
            salesPending > refundsPending ? salesPending : refundsPending;
        state = (
          currentBatch: batch,
          totalBatches: batch + ((remaining - 1) ~/ 15),
        );

        final outcome = await TransactionSyncService.syncPending(
          db,
          api,
          auth,
          storeId,
        );
        total = (
          syncedSales: total.syncedSales + outcome.syncedSales,
          syncedRefunds: total.syncedRefunds + outcome.syncedRefunds,
        );
        // Safety valve: stop if a batch synced nothing, so a server that
        // rejects every record without erroring can't loop forever.
        if (outcome.syncedSales == 0 && outcome.syncedRefunds == 0) break;
      }
    } finally {
      state = null;
    }
    return total;
  }


}

final transactionSyncProgressProvider =
    NotifierProvider<TransactionSyncProgressNotifier, SyncAllProgress?>(
      TransactionSyncProgressNotifier.new,
    );
