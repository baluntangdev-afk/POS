import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../orders/repositories/webhook_auth_repository.dart';
import '../../orders/use_cases/webhook_auth_error.dart';
import '../repositories/transaction_sync_repository.dart';

/// A manual sync was requested before this terminal was given a Kiosk ID.
class TransactionSyncNotConfiguredException implements Exception {
  const TransactionSyncNotConfiguredException();

  String get message => 'Set up the Kiosk ID before syncing.';

  @override
  String toString() => 'TransactionSyncNotConfiguredException()';
}

/// [cancelling] is set once [TransactionSyncProgressNotifier.cancel] was
/// called and the run is finishing its in-flight batch.
typedef SyncAllProgress = ({int currentBatch, int totalBatches, bool cancelling});

/// What a sync run pushed; [cancelled] when it was stopped before draining
/// everything.
typedef SyncAllOutcome = ({int syncedSales, int syncedRefunds, bool cancelled});

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

  bool _cancelRequested = false;

  /// Stops the running sync once its in-flight batch completes. The batch
  /// itself isn't aborted: records the orders service already accepted must
  /// still be marked synced, or they'd be re-sent next run. Whatever is left
  /// stays pending for the next trigger.
  void cancel() {
    final current = state;
    if (!_isRunning || current == null || current.cancelling) return;
    _cancelRequested = true;
    state = (currentBatch: current.currentBatch, totalBatches: current.totalBatches, cancelling: true);
  }

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

  /// The Transactions screen's manual "Sync All": same as [drainPending], but
  /// failures propagate so the caller can tell the user what went wrong.
  ///
  /// Throws [TransactionSyncNotConfiguredException] when this terminal has no
  /// Kiosk ID, and [WebhookAuthException] when the orders service rejects it.
  Future<SyncAllOutcome> syncNow() async {
    if (_isRunning) return (syncedSales: 0, syncedRefunds: 0, cancelled: false);
    final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
    final storeId = terminal.kioskId.trim();
    if (storeId.isEmpty) throw const TransactionSyncNotConfiguredException();
    await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
    return syncAll(storeId: storeId);
  }

  Future<SyncAllOutcome> syncAll({required String storeId}) async {
    if (_isRunning) return (syncedSales: 0, syncedRefunds: 0, cancelled: false);
    _isRunning = true;
    _cancelRequested = false;

    final repository = ref.read(transactionSyncRepositoryProvider);
    var total = (syncedSales: 0, syncedRefunds: 0);
    try {
      var batch = 0;
      while (!_cancelRequested) {
        final pending = await repository.countPending(storeId);
        if (pending.sales == 0 && pending.refunds == 0) break;
        if (_cancelRequested) break;

        batch++;
        final remaining = pending.sales > pending.refunds ? pending.sales : pending.refunds;
        state = (currentBatch: batch, totalBatches: batch + ((remaining - 1) ~/ _batchSize), cancelling: false);

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
    final cancelled = _cancelRequested;
    _cancelRequested = false;
    return (syncedSales: total.syncedSales, syncedRefunds: total.syncedRefunds, cancelled: cancelled);
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
