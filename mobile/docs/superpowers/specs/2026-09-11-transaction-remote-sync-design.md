# Transaction remote sync — design

**Date:** 2026-09-11 (backend contract finalized 2026-09-15; auth model reversed 2026-09-16)
**Scope:** `mobile/` only (Flutter merchant POS app)
**Companion:** `webhook-receiver/backend/docs/specs/2026-09-15-pos-transactions-sync-design.md`
(the backend side — the endpoint this design calls is built there, not here)

> **2026-09-16 update:** the original design (below) deliberately shipped
> `POST /merchant/transactions/sync` with **no auth**, reasoning that a store
> must be able to sync from the moment it's installed, before any operator
> action. That premise is void: merchant/store-id provisioning on the backend
> already requires an operator to create the `merchants` row first (see
> `POST /auth/token`'s `merchant_not_registered` gate) — the exact same
> prerequisite `POST /devices/register` already has. So this sync endpoint is
> no more bootstrap-constrained than a feature that already ships. Sections
> below are updated in place to require the same bearer-token flow every
> other device-facing endpoint uses; the change is confined to the "API"
> section, `TransactionSyncService`, error handling, and the "Backend
> contract" section at the bottom — schema, DAO, scheduling, and backfill are
> unchanged.

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
// Both `ORDER BY id ASC` — a large backlog (see "Backfill") drains
// oldest-first, so an interrupted run leaves a monotonically advancing
// high-water mark instead of gaps scattered through history.
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

**(2026-09-16: reversed from "no auth" — see the update note at the top of
this file.)** `POST /merchant/transactions/sync` now requires the same
bearer-token auth as `POST /devices/register` and `GET /merchant/orders`:
`Authorization: Bearer <token>`, a JWT minted by `POST /auth/token` and
carrying a `merchant_id` claim the backend trusts over anything in the
request body.

Reuses `dpoSocketApiClientProvider` (the existing Dio client) exactly as the
other authenticated calls do. `WebhookTokenInterceptor.onRequest` attaches
the cached bearer token to every request on this client automatically; its
`onError` path re-mints on a `401` and retries once. That's sufficient for
steady-state (a device that's already opened the live-orders feed, or saved
its Store ID, already has a cached token) but **not** for a device's very
first sync tick if it has never made an authenticated call before — the
interceptor only *attaches* a cached token, it doesn't mint one from
nothing. So `TransactionSyncService.syncPending` (below) explicitly calls
`ensureToken(storeId)` before every `pushBatch`, the same pattern
`orders_feed_notifier.dart` already uses before its own calls.

#### What the app sends — `POST /merchant/transactions/sync`

Full request body (the `Authorization: Bearer <token>` header is added
automatically by the existing interceptor, not by this code). `store_id` is
still sent — the backend validates it against the token's `merchant_id`
claim rather than trusting it outright, see the companion backend spec — so
this stays as an explicit, checked field rather than being dropped from the
payload:

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
  retried next tick. This now includes the auth-specific responses
  `401 missing_bearer_token`, `401 invalid_or_expired_token`, and
  `403 merchant_id_mismatch` — none of them get special handling; they fall
  through the same blind-retry path as a network error or a `500`. A device
  whose merchant hasn't been provisioned yet (`merchant_not_registered` /
  `merchant_inactive`, surfaced when `ensureToken` itself fails — see below)
  is handled the same way: the tick is skipped, nothing is marked synced,
  and the next tick tries again once provisioning completes.
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
  static Future<void> syncPending(
    AppDatabase db,
    TransactionSyncApi api,
    WebhookAuthRepository auth,
    String storeId,
  ) async {
    final saleIds = await db.salesDao.getUnsyncedSaleIds();
    final refundIds = await db.salesDao.getUnsyncedRefundIds();
    if (saleIds.isEmpty && refundIds.isEmpty) return;

    // Mint/refresh the bearer token first — see "API" above for why this
    // can't rely solely on the interceptor's passive attach-if-cached
    // behavior. A failure here (merchant not yet provisioned, wrong
    // webhook_secret, etc.) throws and the whole tick is skipped; every
    // row stays unsynced and is retried next tick, same as an HTTP failure
    // from pushBatch itself.
    await auth.ensureToken(storeId);

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
batch — including an auth failure from either `ensureToken` or `pushBatch`
— leaves every row's `synced_at` untouched, so it's naturally retried next
tick with no special-casing.

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
starts working through the full backlog, batch by batch (oldest-first, per
the `ORDER BY id ASC` note in "DAO" above), using the exact same code path
as ongoing day-to-day sync.

Because sync is now auth-gated (see the 2026-09-16 update at the top of this
file), a device installed — or with years of local history — before its
store's `merchant_id` is provisioned on the backend simply accumulates
unsynced rows harmlessly: every tick's `ensureToken` call fails, the tick is
skipped, nothing changes. There is no dead-letter state and no data loss —
the moment an operator finishes provisioning the merchant, the very next
tick (scheduled or reconnect-triggered) authenticates successfully and
sweeps the entire backlog, old and new rows alike, through the same
25-per-batch loop. No manual "resync" action is needed.

## Error handling

- A batch HTTP failure (network error, 5xx) leaves all rows in that batch
  unsynced; retried on the next tick. No backoff/retry-count bookkeeping —
  the periodic schedule *is* the retry.
- An auth failure — `ensureToken` throwing (`merchant_not_registered`,
  `merchant_inactive`, wrong `webhook_secret`) or `pushBatch` returning
  `401`/`403 merchant_id_mismatch` — is handled identically: the tick ends
  with nothing marked synced, no UI is shown, and the next tick tries again.
  This is a deliberate departure from `live_orders`, which surfaces auth
  failures to the user via `webhookAuthStatusProvider` — transaction sync
  stays a silent background job per its own non-goals, so a store owner
  isn't shown a scary error for something an operator needs to fix on the
  backend, not something the cashier can act on.
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

## Backend contract (resolved 2026-09-15; auth model reversed 2026-09-16)

Previously open questions, now settled — see the companion backend spec for
full detail:

- **Path/shape confirmed unchanged.** `POST /merchant/transactions/sync` on
  the same `dpoSocketApiClientProvider` backend, request/response exactly as
  specified above.
- **Bearer auth required (2026-09-16, reversing the 09-15 decision).** The
  endpoint is now gated by `requireAuthToken`, same as `GET /merchant/orders`
  and `POST /devices/register`. `merchant_id` is taken from the verified
  JWT claim; a body `store_id` that disagrees with it is rejected with
  `403 merchant_id_mismatch`. This does change this file's design in three
  places: the "API" section (`ensureToken` before every call), the
  `TransactionSyncService` code (new `WebhookAuthRepository` parameter), and
  "Error handling" (auth failures added to the blind-retry list). Schema,
  DAO shape, scheduling, and batching are unaffected.
- **`store_id` is validated, not trusted outright.** A store still can't sync
  before its merchant is provisioned — but that was already true of every
  other backend-facing feature this app has (device registration, live
  orders), so it's not a new constraint being introduced, just this
  endpoint catching up to the same bar. No mobile change needed for the
  field itself (still named `store_id`, still sourced from `storeInfoDao`,
  per "Store identity" above) — only the auth wiring around it changed.
