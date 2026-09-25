# Kiosk transaction sync UI — design

**Date:** 2026-09-25
**Scope:** `kiosk/` + `be/` (sales-orders list DTO, transaction-sync module)
**Parity target:** mobile `lib/features/transactions/view/transactions_screen.dart`
and `docs/superpowers/specs/2026-09-11-transaction-remote-sync-design.md`

## Problem

The kiosk already pushes sales/refunds to the orders service
(`POST /merchant/transactions/sync`) on login, reconnect, after each sale, and
every 15 minutes, via our backend's `/api/v1/transaction-sync/*` bookkeeping
endpoints. What it lacks compared to mobile is the user-facing side:

1. No per-transaction "Synced / Not yet synced" indicator.
2. No manual **Sync All** with progress and a result message.
3. No **Unsync Transactions** (re-queue everything for re-upload).
4. No catch-up sync when the Transactions screen is opened.

Sync plumbing, payload shape, triggers, batching and the Kiosk ID
Transfer/Verified-merchant prompts are unchanged.

## Design

### 1. Synced flag on the transactions list

**Backend**
- `SalesOrderWithItemsResponseDto` gains `syncedAt: Date | null`.
- `SalesOrderWithItemsMapper.toResponse` maps `salesOrder.syncedAt ?? null`.
- Both `select` blocks in `sales-orders.service.ts` (paged list and
  `findOneWithItems`) add `syncedAt: true`.

**Kiosk**
- `SalesOrderWithItemsResponseDto` (Dart) gains `DateTime? syncedAt`.
- `Receipt` gains `DateTime? syncedAt` and `bool get isSynced => syncedAt != null`;
  `receipt_repository._receiptFromSalesOrderWithItemsDto` maps it.
- `build_runner` regenerates mappers.

**UI:** a small cloud icon next to the invoice number in `_TransactionRow`
(and `_TransactionCard`): `Icons.cloud_done_rounded` in success green when
synced, `Icons.cloud_off_rounded` in `POSColors.textTertiary` otherwise,
wrapped in a `Tooltip` ("Synced" / "Not yet synced").

### 2. Floating action buttons (same as mobile)

`TransactionsScreen` passes a `floatingActionButton` to `WindowsScaffold`: a
right-aligned `Column` of two `FloatingActionButton.extended`s, like mobile.

- **Sync All** (primary teal, white text). While
  `transactionSyncProgressProvider` is non-null it is disabled and shows a
  spinner + `Syncing {current}/{total}…`.
- **Unsync Transactions** (white, teal text), rendered **only for
  admin/supervisor** (`auth.isAdminOrSupervisor`), since it forces a full
  history re-upload. Shows a spinner + `Unsyncing…` while running.

Sizes use `context.responsive.value(...)`.

**Sync All flow** — new `TransactionSyncProgressNotifier.syncNow()`:
resolves the Kiosk ID via `getMyTerminal()`, throws
`TransactionSyncNotConfiguredException` when empty, calls
`webhookAuthRepository.ensureToken` (lets `WebhookAuthException` propagate),
then `syncAll(storeId)`. Unlike `drainPending()` it does not swallow errors.
The screen shows a snackbar:
- empty Kiosk ID → "Set up the Kiosk ID before syncing."
- auth failure → the `WebhookAuthException.message`
- other failure → the error's `.message`
- success → "Everything is already synced." / "Synced N transaction(s)."
then refreshes the current page.

**Unsync flow:** confirmation dialog (`showMessageDialog`, warning type,
"Unsync Transactions" / "This marks all synced transactions on this device
as not synced. They will be re-uploaded on the next sync. Continue?"), then
`transactionSyncRepository.unsyncAll()`, snackbar "All transactions marked as
unsynced.", page refresh. It does **not** auto-trigger a sync (mobile doesn't).

**Mount-time catch-up:** on first build the screen quietly calls
`drainPending()`; when it syncs anything, the page is refreshed. Also, any
time `transactionSyncProgressProvider` goes from non-null → null, the screen
refreshes the current page so icons reflect background runs.

Refreshing re-invokes `getResults` with the screen's current
page/limit/search/date/sort, so it's done through a small local callback
rather than a new notifier method.

### 3. Backend unsync endpoint

`POST /api/v1/transaction-sync/unsync` — `AdminOrSupervisorGuard`, `204`.
New `UnsyncTransactionsService` sets `synced_at = NULL` on every sales order
and refund in one transaction, leaving `store_id` untouched (mobile's
`unsyncAllKeepingStoreId`). Wired through `TransactionSyncService` and the
module providers.

**Kiosk:** `TransactionSyncStateApi.unsync()` →
`TransactionSyncRepository.unsyncAll()`.

## Error handling

- Sync All failures only surface as a snackbar; rows stay unsynced and the
  existing background triggers retry.
- Unsync failure → error snackbar; nothing partially applied (single DB
  transaction).
- Non-admin calling `/unsync` gets `403` (button is hidden anyway).

## Verification

- `kiosk/`: `dart run build_runner build --delete-conflicting-outputs`, `dart analyze`.
- `be/`: `npx tsc --noEmit`, eslint on changed files only.
- No new tests (project convention).

## Files touched

| File | Change |
|---|---|
| `be/src/sales-orders/dto/sales-order-with-items-response.dto.ts` | `syncedAt` |
| `be/src/sales-orders/mapper/sales-order-with-items.mapper.ts` | map `syncedAt` |
| `be/src/sales-orders/sales-orders.service.ts` | select `syncedAt` (×2) |
| `be/src/transaction-sync/services/unsync-transactions.service.ts` | **new** |
| `be/src/transaction-sync/transaction-sync.{controller,service,module}.ts` | `/unsync` |
| `kiosk/lib/data/backend_api/schemas/sales_order_with_items_response_dto.dart` | `syncedAt` |
| `kiosk/lib/data/backend_api/sources/transaction_sync_state_api.dart` | `unsync()` |
| `kiosk/lib/features/sales/entities/receipt.dart` | `syncedAt`, `isSynced` |
| `kiosk/lib/features/sales/repositories/receipt_repository.dart` | map `syncedAt` |
| `kiosk/lib/features/transaction_sync/repositories/transaction_sync_repository.dart` | `unsyncAll()` |
| `kiosk/lib/features/transaction_sync/state/transaction_sync_progress_notifier.dart` | `syncNow()` |
| `kiosk/lib/features/sales/view/transactions_screen.dart` | FABs, sync icon, refresh |
