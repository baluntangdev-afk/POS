import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../orders/repositories/webhook_auth_repository.dart';
import '../../orders/use_cases/webhook_auth_error.dart';
import '../repositories/transaction_sync_repository.dart';

typedef SyncAllProgress = ({int currentBatch, int totalBatches});

const _batchSize = 15;

/// Drains every pending sale/refund batch-by-batch, publishing
/// [SyncAllProgress] as it goes so the app root can show a live indicator
/// wherever the run was triggered from.
class TransactionSyncProgressNotifier extends Notifier<SyncAllProgress?> {
  @override
  SyncAllProgress? build() => null;

  // Guards re-entrancy independently of [state]. `state` isn't set until
  // after the first pending-count request resolves, which leaves a window
  // where a second trigger — login, reconnect edge, periodic tick, or a
  // just-committed sale — can also see `state == null` and start its own
  // concurrent drain. Flipping this flag synchronously, before any await,
  // closes that window: only the first caller ever proceeds.
  bool _isRunning = false;

  /// Resolves the current Kiosk ID and drains its pending transactions.
  /// Skipped for an unverified merchant (an unknown Kiosk ID) rather than
  /// letting it fail quietly inside the sync's own token mint. Quiet on
  /// failure — the next trigger retries.
  Future<void> drainPending() async {
    if (_isRunning) return;
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      final storeId = terminal.kioskId.trim();
      if (storeId.isEmpty) return;
      if (!await _isVerified(storeId)) return;
      await syncAll(storeId: storeId);
    } catch (error, stackTrace) {
      debugPrint('[TransactionSync] drain skipped: $error\n$stackTrace');
    }
  }

  Future<TransactionSyncOutcome> syncAll({required String storeId}) async {
    if (_isRunning) return (syncedSales: 0, syncedRefunds: 0);
    _isRunning = true;

    final repository = ref.read(transactionSyncRepositoryProvider);
    var total = (syncedSales: 0, syncedRefunds: 0);
    try {
      var batch = 0;
      while (true) {
        final pending = await repository.countPending(storeId);
        if (pending.sales == 0 && pending.refunds == 0) break;

        batch++;
        final remaining = pending.sales > pending.refunds ? pending.sales : pending.refunds;
        state = (currentBatch: batch, totalBatches: batch + ((remaining - 1) ~/ _batchSize));

        final outcome = await repository.syncPending(storeId);
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

  Future<bool> _isVerified(String storeId) async {
    try {
      await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
      return true;
    } on WebhookAuthException {
      return false;
    }
  }
}

final transactionSyncProgressProvider = NotifierProvider<TransactionSyncProgressNotifier, SyncAllProgress?>(
  TransactionSyncProgressNotifier.new,
);
