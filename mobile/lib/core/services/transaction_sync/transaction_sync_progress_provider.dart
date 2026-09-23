import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../features/live_orders/repositories/webhook_auth_repository.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import 'transaction_sync_service.dart';

/// Fires whenever a sale/refund/void commits locally into a syncable state
/// (see `SalesDao.onSyncNeeded`), so the app can push it within seconds
/// instead of waiting for the next reconnect edge or 15-minute WorkManager
/// tick.
final salesSyncTriggerProvider = StreamProvider<void>((ref) {
  return ref.watch(databaseProvider).salesDao.onSyncNeeded;
});

/// Drains every pending sale/refund batch-by-batch, publishing [SyncAllProgress]
/// as it goes so any screen — not just the one that started the run — can show
/// a live indicator. Shared across features (Transactions triggers it,
/// Dashboard just watches it), so it lives in `core/`, like
/// `connectivity_status_provider.dart`.
class TransactionSyncProgressNotifier extends Notifier<SyncAllProgress?> {
  @override
  SyncAllProgress? build() => null;

  // Guards re-entrancy independently of [state]. `state` isn't set until
  // after the first pending-count queries resolve, which leaves a window
  // (two awaits wide) where a second trigger — reconnect edge, login,
  // the Transactions screen's mount-time catch-up, or the per-transaction
  // `salesSyncTriggerProvider` stream — can also see `state == null` and
  // start its own concurrent drain. Flipping this flag synchronously, before
  // any await, closes that window: only the first caller ever proceeds.
  bool _isRunning = false;

  Future<TransactionSyncOutcome> syncAll({
    required AppDatabase db,
    required TransactionSyncApi api,
    required WebhookAuthRepository auth,
    required String storeId,
  }) async {
    if (_isRunning) return (syncedSales: 0, syncedRefunds: 0);
    _isRunning = true;

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
      _isRunning = false;
    }
    return total;
  }
}

final transactionSyncProgressProvider =
    NotifierProvider<TransactionSyncProgressNotifier, SyncAllProgress?>(
      TransactionSyncProgressNotifier.new,
    );
