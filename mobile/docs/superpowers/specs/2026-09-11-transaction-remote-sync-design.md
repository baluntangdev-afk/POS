# Transaction remote sync — design

**Date:** 2026-09-11
**Scope:** `mobile/` only (Flutter merchant POS app)

## Problem

The POS is fully local (Drift/SQLite) — sales, refunds, and payments never leave
the device. A back-office web app is planned to let merchants view transactions
across their store(s), so every completed sale and refund needs to reach a
remote server, working the same whether the device is online or has been
offline for days.

## Non-goals

This is deliberately the simplest version that satisfies "send transaction data
to the remote server":

- **One-way only.** The device pushes transactions up. The back office is a
  viewer. Nothing is pulled back down (no remote void, no annotations/flags).
  If that's needed later, it's a separate follow-up design — it is not free to
  bolt on later, but it's also not being paid for now.
- **No outbox table, no UUIDs, no idempotency-key scheme.** One device per
  store was confirmed, so local autoincrement ids are already unique per
  store; the store's existing `store_id` plus the local table name and row id
  is enough to identify a row remotely.
- **No conflict resolution.** There's nothing to reconcile — the device is the
  only writer.
- **X/Z readings, cashier accounting, and order_events are out of scope.**
  Only `sales` (+ items/modifiers/payments) and `refunds` (+ refund items).

## Design

### 1. Schema — migration v15 (`lib/core/database/app_database.dart`)

Two new nullable columns, no new tables:

```dart
IntColumn get id => integer().autoIncrement()(); // existing, unchanged
DateTimeColumn get syncedAt => dateTime().nullable()(); // new
```

added to `SalesTable` and `RefundsTable`
(`lib/core/database/tables/sales_table.dart`,
`lib/core/database/tables/refunds_table.dart`).

`schemaVersion` becomes `15`; add:

```dart
if (from < 15) {
  if (!await _hasColumn('sales', 'synced_at')) {
    await m.addColumn(salesTable, salesTable.syncedAt);
  }
  if (!await _hasColumn('refunds', 'synced_at')) {
    await m.addColumn(refundsTable, refundsTable.syncedAt);
  }
}
```

Every row that exists before this migration lands with `synced_at = NULL`,
which is what makes historical backfill automatic — see "Backfill" below.

### 2. DAO — `lib/core/database/daos/sales_dao.dart`

New read methods, following the existing raw-map export style
(`getTransactionsForExport`, `getSaleItemsForExport`):

```dart
Future<List<int>> getUnsyncedSaleIds({int limit = 25});
Future<List<int>> getUnsyncedRefundIds({int limit = 25});

/// Full aggregate for one sale: sale fields + items (with their modifiers
/// nested) + payments. Everything the back office needs to reconstruct the
/// transaction, not just what the transactions list shows.
Future<Map<String, Object?>> getSaleSyncPayload(int saleId);

/// Sale fields + refund fields + refund items.
Future<Map<String, Object?>> getRefundSyncPayload(int refundId);

Future<void> markSalesSynced(List<int> ids);
Future<void> markRefundsSynced(List<int> ids);
```

`getSaleSyncPayload` shape:

```jsonc
{
  "local_id": 4821,
  "so_number": "SO-001-2026-0143",
  "cashier_name": "Jane Cruz",
  "created_at": "2026-09-11T08:03:11.000Z",
  "type": "dine_in",
  "status": "completed",       // completed | voided | refunded
  "total": 350.0,
  "discount": 0.0,
  "void_reason": null,
  "voided_at": null,
  "items": [
    {
      "product_name": "Iced Latte",
      "variant_name": "16oz",
      "qty": 2,
      "unit_price": 150.0,
      "discount_type": null,
      "discount_amount": null,
      "vat_exempt_amount": null,
      "modifiers": [
        { "name": "Milk: Oat Milk", "additional_price": 25.0 }
      ]
    }
  ],
  "payments": [
    { "method": "cash", "amount": 350.0, "cash_received": 400.0, "reference": null }
  ]
}
```

`getRefundSyncPayload` shape:

```jsonc
{
  "local_id": 77,
  "refund_number": "RF-000077",
  "sale_local_id": 4821,
  "sale_so_number": "SO-001-2026-0143",
  "reason": "Customer changed order",
  "method": "Cash Refund",
  "total": 150.0,
  "created_at": "2026-09-11T09:10:02.000Z",
  "items": [
    { "sale_item_index": 0, "product_name": "Iced Latte", "qty": 1, "amount": 150.0 }
  ]
}
```

`product_name`/`variant_name` are resolved via the existing
`productsTable` join (same pattern as `getSaleItemsForExport`), so a
deleted/renamed product afterward doesn't retroactively change what was
already sent — resolve names at read time, same as receipts do today.

`voidSale(...)` gets one addition: if the sale being voided already has a
non-null `synced_at`, reset it to `null` in the same update so the voided
status gets re-picked-up and re-sent on the next sync run. No other write
path changes.

### 3. API — `lib/data/backend_api/sources/transaction_sync_api.dart`

Reuses `dpoSocketApiClientProvider` — the existing Dio client already
carries the device's bearer token via `WebhookTokenInterceptor` (merchant-
scoped, auto-refreshes on 401), so no new auth work is needed.

#### What the app sends — `POST /merchant/transactions/sync`

Full request body (the `Authorization: Bearer <token>` header is added
automatically by the existing interceptor, not by this code):

```jsonc
{
  "store_id": "store_c9f1a2",
  "sales": [
    {
      "local_id": 4821,
      "so_number": "SO-001-2026-0143",
      "cashier_name": "Jane Cruz",
      "created_at": "2026-09-11T08:03:11.000Z",
      "type": "dine_in",
      "status": "completed",
      "total": 350.0,
      "discount": 0.0,
      "void_reason": null,
      "voided_at": null,
      "items": [
        {
          "product_name": "Iced Latte",
          "variant_name": "16oz",
          "qty": 2,
          "unit_price": 150.0,
          "discount_type": null,
          "discount_amount": null,
          "vat_exempt_amount": null,
          "modifiers": [
            { "name": "Milk: Oat Milk", "additional_price": 25.0 }
          ]
        }
      ],
      "payments": [
        { "method": "cash", "amount": 350.0, "cash_received": 400.0, "reference": null }
      ]
    }
    // ...up to 25 sale objects per request, shape as in "getSaleSyncPayload shape" above
  ],
  "refunds": [
    {
      "local_id": 77,
      "refund_number": "RF-000077",
      "sale_local_id": 4821,
      "sale_so_number": "SO-001-2026-0143",
      "reason": "Customer changed order",
      "method": "Cash Refund",
      "total": 150.0,
      "created_at": "2026-09-11T09:10:02.000Z",
      "items": [
        { "sale_item_index": 0, "product_name": "Iced Latte", "qty": 1, "amount": 150.0 }
      ]
    }
    // ...up to 25 refund objects per request, shape as in "getRefundSyncPayload shape" above
  ]
}
```

Either array can be empty (a run with only new sales sends `"refunds": []`)
but the service never sends both empty — see `syncPending` below, it returns
before calling the API at all when there's nothing pending.

#### What the app expects back

```jsonc
{
  "accepted_sale_ids": [4821],
  "accepted_refund_ids": [77]
}
```

- `accepted_sale_ids` / `accepted_refund_ids` are the `local_id`s (from the
  request, not any server-generated id) that the server durably stored.
  Anything sent but **not** listed in the response — whether the server
  rejected it or the whole request errored — simply stays `synced_at = NULL`
  locally and is resent, unchanged, on the next sync tick. The client does
  not need a per-row rejection reason for this design; the retry is blind.
- A non-2xx HTTP response (network error, 4xx, 5xx) is treated the same as
  "nothing was accepted" — no ids get marked synced, the whole batch is
  retried next tick.
- The server does not need to return the full stored transaction back, only
  which ids it accepted.

```dart
final transactionSyncApiProvider = Provider<TransactionSyncApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return TransactionSyncApi(httpClient);
});

class TransactionSyncApi with ApiCall {
  const TransactionSyncApi(this._httpClient);
  final Dio _httpClient;

  /// POST /merchant/transactions/sync
  /// Body: { store_id, sales: [...], refunds: [...] }
  /// Response: { accepted_sale_ids: [...], accepted_refund_ids: [...] }
  Future<TransactionSyncResultDto> pushBatch({
    required String storeId,
    required List<Map<String, Object?>> sales,
    required List<Map<String, Object?>> refunds,
  }) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/merchant/transactions/sync',
      data: {'store_id': storeId, 'sales': sales, 'refunds': refunds},
    );
    return TransactionSyncResultDto.fromJson(jsonEncode(response.data));
  });
}
```

`TransactionSyncResultDto` (new `dart_mappable` schema in
`lib/data/backend_api/schemas/`) just carries back which local ids the
server actually accepted, so a partial failure (e.g. one malformed row)
doesn't stop the rest of the batch from being marked synced.

> This endpoint doesn't exist yet — it's a dependency on the back-office
> backend, not something built here. The shape above is what the mobile
> side needs; treat it as the contract to confirm with whoever builds that
> endpoint.

### 4. Sync service — `lib/core/services/transaction_sync/transaction_sync_service.dart`

```dart
abstract final class TransactionSyncService {
  static Future<void> syncPending(AppDatabase db, TransactionSyncApi api, String storeId) async {
    final saleIds = await db.salesDao.getUnsyncedSaleIds();
    final refundIds = await db.salesDao.getUnsyncedRefundIds();
    if (saleIds.isEmpty && refundIds.isEmpty) return;

    final sales = [for (final id in saleIds) await db.salesDao.getSaleSyncPayload(id)];
    final refunds = [for (final id in refundIds) await db.salesDao.getRefundSyncPayload(id)];

    final result = await api.pushBatch(storeId: storeId, sales: sales, refunds: refunds);

    await db.salesDao.markSalesSynced(result.acceptedSaleIds);
    await db.salesDao.markRefundsSynced(result.acceptedRefundIds);
  }
}
```

Batch size capped at 25 per table per run (via the `limit` param above) —
on first run against a store with years of history, this just means more
ticks, not a giant first request. A network/HTTP failure for the whole
batch leaves every row's `synced_at` untouched, so it's naturally retried
next tick with no special-casing.

### 5. Scheduling

Mirrors the existing `backup_worker.dart` pattern exactly:

- **New** `lib/core/workers/transaction_sync_worker.dart` — a `workmanager`
  periodic task (`kTransactionSyncTaskName`), registered every 15 minutes
  with a `NetworkType.connected` constraint (so a run started while offline
  is skipped by WorkManager itself, no manual connectivity check needed).
  Wired up in `main.dart` next to `schedulePeriodicBackup()`.
- **On reconnect:** a `ref.listen(isOnlineProvider, ...)` in the same place
  the app already watches connectivity, firing one immediate
  `TransactionSyncService.syncPending(...)` call on a false→true transition,
  so a store doesn't wait up to 15 minutes after its connection comes back.

Both paths call the same `TransactionSyncService.syncPending`, so there's
exactly one place sync logic lives.

### 6. Store identity

`storeId` comes from the existing `storeInfoDao` (`store_info.store_id`,
already populated during device registration — see
`merchant_devices_api.dart`). No new identity concept needed.

## Backfill

Not a separate feature. Every sale/refund that existed before this ships has
`synced_at = NULL` after the migration, which is indistinguishable from a
brand-new unsynced row — the very first scheduled/reconnect sync run just
starts working through the full backlog, batch by batch, using the exact
same code path as ongoing day-to-day sync.

## Error handling

- A batch HTTP failure (network error, 5xx) leaves all rows in that batch
  unsynced; retried on the next tick. No backoff/retry-count bookkeeping —
  the periodic schedule *is* the retry.
- A partial failure (server rejects one row, accepts the rest) only marks
  the accepted ids synced; the rejected row stays `synced_at = NULL` and is
  resent next tick as-is. If it's rejected again and again, that's surfaced
  by it simply never leaving the "unsynced" state — no UI is being added for
  this now, since it's not part of the requested scope, but
  `getUnsyncedSaleIds()`/`getUnsyncedRefundIds()` are the hook a future
  "sync status" indicator would use.
- Sync is purely background and additive: it never blocks or slows down
  completing a sale, voiding one, or recording a refund.

## Verification

From `mobile/`:

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

No new test files (per project convention); `dart analyze` must be clean.
Manual check: complete a sale and a refund while offline, confirm they sit
with `synced_at IS NULL`, then reconnect and confirm the next sync tick (or
the app's reconnect listener) sends them and sets `synced_at`.

## Files touched

| File | Change |
|---|---|
| `lib/core/database/tables/sales_table.dart` | add `syncedAt` |
| `lib/core/database/tables/refunds_table.dart` | add `syncedAt` |
| `lib/core/database/app_database.dart` | `schemaVersion` → 15, migration step |
| `lib/core/database/daos/sales_dao.dart` | new read/mark-synced methods; `voidSale` resets `syncedAt` |
| `lib/data/backend_api/schemas/transaction_sync_result_dto.dart` | **new** |
| `lib/data/backend_api/schemas/transaction_sync_result_dto.mapper.dart` | generated |
| `lib/data/backend_api/sources/transaction_sync_api.dart` | **new** |
| `lib/core/services/transaction_sync/transaction_sync_service.dart` | **new** |
| `lib/core/workers/transaction_sync_worker.dart` | **new** |
| `lib/main.dart` | register periodic task + reconnect listener |

## Open questions for the backend side (not built here)

- Exact path/shape of `POST /merchant/transactions/sync` — the request/
  response shape above is what the mobile client needs; needs sign-off from
  whoever implements the back-office endpoint.
- Whether it lives on the same service as `dpoSocketApiClientProvider`
  (assumed here, since that's the only backend the app already talks to and
  already has a `merchant`/`store_id` concept) or a different one — if
  different, `transaction_sync_api.dart` just points at a new Dio client
  instead of the existing one; nothing else in this design changes.
