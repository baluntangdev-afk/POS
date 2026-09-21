# Sync All progress indicator — design

**Date:** 2026-09-21
**Status:** Approved

## Problem

`TransactionSyncService.syncPending()` pushes at most one batch per call — up to 15
unsynced sales and up to 15 unsynced refunds (`SalesDao.getUnsyncedSaleIds` /
`getUnsyncedRefundIds`, both default `limit: 15`). Three call sites use it today,
none of which loop:

- `TransactionsScreen`'s "Sync Transactions" FAB (`lib/features/transactions/view/transactions_screen.dart`)
- The periodic WorkManager background tick, every 15 minutes (`lib/core/workers/transaction_sync_worker.dart`)
- A foreground trigger on reconnect (`_syncTransactionsNow` in `lib/main.dart`)

If a device accumulates, say, 100 unsynced transactions, fully syncing requires
~7 separate triggers of one of the above, with no visibility into that being
in progress or how much is left.

## Scope

Only the Transactions screen's manual sync button changes behavior: it becomes
a "drain everything" loop instead of a single batch, and shows batch progress
while doing so. The Dashboard gains a passive status pill that reflects that
loop running.

Out of scope (explicitly, per discussion):
- The periodic WorkManager background tick and the reconnect-triggered
  foreground sync are unchanged — they remain single, quiet ≤15-batches.
  Looping them raises separate concerns (WorkManager execution time budget,
  and the fact that a WorkManager tick runs in its own isolate that can't
  update the in-app provider live) that aren't needed to solve the reported
  problem.
- No dedicated `Isolate.spawn`/`compute()` for the sync loop. `driftDatabase()`
  already runs all SQLite work on its own background isolate, and the Dio
  HTTP call is async I/O that doesn't block the UI isolate. The JSON payload
  per batch (≤15 sales + ≤15 refunds) is too small to cause a frame drop.
  Spawning a dedicated isolate would add lifecycle/message-passing complexity
  without fixing anything real.

## Design

### 1. DAO: pending counts

Add to `lib/core/database/daos/sales_dao.dart`, alongside the existing
`getUnsyncedSaleIds` / `getUnsyncedRefundIds` (same filters, but a count
instead of a limited id list — mirrors the existing `getTransactionCount`
pattern):

```dart
Future<int> getUnsyncedSaleCount({required String storeId});
Future<int> getUnsyncedRefundCount({required String storeId});
```

### 2. Progress type

Add to `lib/core/services/transaction_sync/transaction_sync_service.dart`,
alongside the existing `TransactionSyncOutcome`:

```dart
typedef SyncAllProgress = ({int currentBatch, int totalBatches});
```

### 3. Shared progress provider

New file: `lib/core/services/transaction_sync/transaction_sync_progress_provider.dart`.

A `Notifier<SyncAllProgress?>` (`null` = idle) exposed as
`transactionSyncProgressProvider`. It lives in `core/` — like
`connectivity_status_provider.dart` — because it's shared across two features
(Transactions and Dashboard), not owned by either.

```dart
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
        final salesPending = await db.salesDao.getUnsyncedSaleCount(storeId: storeId);
        final refundsPending = await db.salesDao.getUnsyncedRefundCount(storeId: storeId);
        if (salesPending == 0 && refundsPending == 0) break;

        batch++;
        final remaining = salesPending > refundsPending ? salesPending : refundsPending;
        state = (currentBatch: batch, totalBatches: batch + ((remaining - 1) ~/ 15));

        final outcome = await TransactionSyncService.syncPending(db, api, auth, storeId);
        total = (
          syncedSales: total.syncedSales + outcome.syncedSales,
          syncedRefunds: total.syncedRefunds + outcome.syncedRefunds,
        );
        if (outcome.syncedSales == 0 && outcome.syncedRefunds == 0) break; // safety valve
      }
    } finally {
      state = null;
    }
    return total;
  }
}
```

`totalBatches` is recomputed every iteration from the current pending count,
so it self-corrects if new sales land mid-loop (a cashier can keep ringing up
sales while a sync is in progress) rather than showing a stale denominator.

The safety-valve break (stop if a batch synced nothing) prevents an infinite
loop if the server rejects every record in a batch without erroring.

Errors (`WebhookAuthException`, `ApiException`) propagate out of `syncAll` —
the `finally` still clears `state` to `null` so the Dashboard pill disappears,
and whatever synced in earlier iterations of the same run stays synced (each
`syncPending` call commits its own batch transaction independently, same as
today).

### 4. Transactions screen

`lib/features/transactions/view/transactions_screen.dart`:
- FAB label: "Sync Transactions" → "Sync All" (and "Syncing…" →
  "Syncing 3/7…", sourced from `transactionSyncProgressProvider`).
- `handleManualSync` calls
  `ref.read(transactionSyncProgressProvider.notifier).syncAll(...)` instead of
  `TransactionSyncService.syncPending` directly.
- The FAB's `onPressed`/spinner guard switches from the local `isSyncing`
  `useState` to watching `transactionSyncProgressProvider != null`, so the
  button reflects reality even if this screen was navigated away from and
  back to mid-sync.
- Final snackbar text ("Synced N transactions." / "Everything is already
  synced.") unchanged, fed by the accumulated `TransactionSyncOutcome` that
  `syncAll` returns.

### 5. Dashboard

`lib/features/dashboard/view/dashboard_screen.dart`: a small status pill,
visually consistent with the existing `_LiveOrdersStatusPill`, shown near the
header only while `ref.watch(transactionSyncProgressProvider)` is non-null:
"Syncing transactions 3/7". No new button or tile.

## Error handling

Unchanged from today's pattern: `WebhookAuthException` / `ApiException` are
caught in the Transactions screen's button handler and shown as a snackbar.
The shared notifier's `finally` guarantees the Dashboard pill always clears,
success or failure.

## Testing

Per project convention for this app (`mobile/`), no new test files are
authored for this change — verify with `dart analyze` and manual exercise of
the Sync All button and Dashboard pill.
