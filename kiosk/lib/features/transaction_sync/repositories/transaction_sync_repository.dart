import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../data/backend_api/sources/transaction_sync_state_api.dart';
import '../../orders/repositories/webhook_auth_repository.dart';

final transactionSyncRepositoryProvider = Provider<TransactionSyncRepository>((ref) {
  return TransactionSyncRepositoryImpl(
    ref.watch(transactionSyncStateApiProvider),
    ref.watch(transactionSyncApiProvider),
    ref.watch(webhookAuthRepositoryProvider),
  );
});

typedef TransactionSyncOutcome = ({int syncedSales, int syncedRefunds});

/// Moves this kiosk's sales/refunds to the orders service: pulls a batch of
/// pending records from our backend, pushes it to
/// `POST /merchant/transactions/sync`, and records what was accepted. The
/// kiosk counterpart of mobile's `TransactionSyncService`.
abstract class TransactionSyncRepository {
  /// Pushes one batch for [storeId] (the Kiosk ID). Anything the orders
  /// service doesn't accept stays pending and is retried next run.
  Future<TransactionSyncOutcome> syncPending(String storeId);

  Future<PendingTransactionCounts> countPending(String storeId);

  /// True if this device has any sale or refund at all, regardless of sync
  /// state.
  Future<bool> hasAnyTransactions();

  /// Re-queues every sale/refund and reassigns every sale to [storeId], so
  /// the next sync pushes the full history to that merchant.
  Future<void> transferAll(String storeId);
}

class TransactionSyncRepositoryImpl implements TransactionSyncRepository {
  const TransactionSyncRepositoryImpl(this._stateApi, this._syncApi, this._auth);

  final TransactionSyncStateApi _stateApi;
  final TransactionSyncApi _syncApi;
  final WebhookAuthRepository _auth;

  @override
  Future<TransactionSyncOutcome> syncPending(String storeId) async {
    final pending = await _stateApi.fetchPending(storeId);
    if (pending.sales.isEmpty && pending.refunds.isEmpty) {
      return (syncedSales: 0, syncedRefunds: 0);
    }

    await _auth.ensureToken(storeId);

    final result = await _syncApi.pushBatch(storeId: storeId, sales: pending.sales, refunds: pending.refunds);

    await _stateApi.markSynced(saleIds: result.acceptedSaleIds, refundIds: result.acceptedRefundIds);

    return (syncedSales: result.acceptedSaleIds.length, syncedRefunds: result.acceptedRefundIds.length);
  }

  @override
  Future<PendingTransactionCounts> countPending(String storeId) => _stateApi.fetchPendingCount(storeId);

  @override
  Future<bool> hasAnyTransactions() => _stateApi.hasTransactions();

  @override
  Future<void> transferAll(String storeId) => _stateApi.transfer(storeId);
}
