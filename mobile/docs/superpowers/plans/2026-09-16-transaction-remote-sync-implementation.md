# Transaction Remote Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Project convention override:** this repo's mobile/ code does not get new test files added for implementation tasks (see `docs/superpowers/specs/2026-09-11-transaction-remote-sync-design.md`'s own "Verification" section). Steps below verify with `dart analyze` + `dart run build_runner build`, not new unit tests.

**Goal:** Push completed sales and refunds from the local Drift DB to the back-office backend (`POST /merchant/transactions/sync`), automatically, in small batches, both on a schedule and immediately on reconnect — including transparent backfill of every pre-existing row.

**Architecture:** Two new nullable `synced_at` columns (schema v15) mark what's already been pushed. A DAO layer reads bounded batches of unsynced rows as plain `Map<String, Object?>` payloads (mirroring the existing CSV-export query style), a thin API source posts them with the existing authenticated Dio client, and a static `TransactionSyncService.syncPending` orchestrates one batch attempt end-to-end. Two triggers call that same method: a 15-minute WorkManager periodic task and a connectivity-reconnect listener — no new trigger surface, no manual "sync now" button (see rationale in the chat response, not repeated here).

**Tech Stack:** Drift/SQLite, `workmanager` (already used by `backup_worker.dart`), Riverpod (`hooks_riverpod`), Dio, `dart_mappable`.

**Key existing-codebase facts this plan depends on** (verified by reading the files, not assumed from the design doc):
- `schemaVersion` is currently `14` (`lib/core/database/app_database.dart:61`).
- `workmanager`'s `Workmanager().initialize(callbackDispatcher)` registers **one single** top-level dispatcher for the *entire app* — Android's WorkManager always invokes that one function for every registered task, distinguishing them by the `task` string. `backup_worker.dart` already calls `Workmanager().initialize(backupCallbackDispatcher)`. **A second, independent `initialize()` call for a transaction-sync-only dispatcher would silently break backup scheduling** (whichever `initialize()` call happens last wins, orphaning the other task name). So Task 6 below extends `backupCallbackDispatcher` with a second branch instead of registering a second dispatcher — this is a deliberate deviation from a literal reading of the design doc's "new worker file" framing, needed to avoid a real bug.
- `WebhookAuthRepositoryImpl`, `AuthApi`, `WebhookAuthStorage`, `TransactionSyncApi` are all plain constructor-injected classes (no Riverpod-only state), so they can be read out of a throwaway `ProviderContainer` inside the background isolate — reusing the exact same wiring as the running app (`dpoSocketApiClientProvider` → `WebhookTokenInterceptor` → token refresh) instead of hand-duplicating it.

---

### Task 1: Schema migration v15

**Files:**
- Modify: `lib/core/database/tables/sales_table.dart`
- Modify: `lib/core/database/tables/refunds_table.dart`
- Modify: `lib/core/database/app_database.dart:61` (schemaVersion), `app_database.dart` migration block (after the `if (from < 14)` block, ~line 271)

- [ ] **Step 1: Add the column to both tables**

`lib/core/database/tables/sales_table.dart`:
```dart
  DateTimeColumn get voidedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
```

`lib/core/database/tables/refunds_table.dart`:
```dart
  TextColumn get method => text().withDefault(const Constant('Cash Refund'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
```

- [ ] **Step 2: Bump schemaVersion and add the migration step**

`lib/core/database/app_database.dart:61`:
```dart
  int get schemaVersion => 15;
```

Insert right after the existing `if (from < 14) { ... }` block (before the closing `},` of `onUpgrade`):
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

- [ ] **Step 3: Regenerate and verify**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then: `dart analyze`
Expected: no errors. `app_database.g.dart` now includes `syncedAt` on both generated data classes.

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/tables/sales_table.dart lib/core/database/tables/refunds_table.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart
git commit -m "feat: add synced_at columns for transaction remote sync (schema v15)"
```

---

### Task 2: DAO — sync read/write methods on `SalesDao`

**Files:**
- Modify: `lib/core/database/daos/sales_dao.dart`

- [ ] **Step 1: Add the unsynced-id queries and mark-synced writers**

Add near the other `get...ForExport` methods (after `getTransactionsForExport`, ~line 1231):

```dart
  Future<List<int>> getUnsyncedSaleIds({int limit = 15}) async {
    final rows = await (select(salesTable)
          ..where((t) => t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
    return rows.map((r) => r.id).toList();
  }

  Future<List<int>> getUnsyncedRefundIds({int limit = 15}) async {
    final rows = await (select(refundsTable)
          ..where((t) => t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
    return rows.map((r) => r.id).toList();
  }

  Future<void> markSalesSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(salesTable)..where((t) => t.id.isIn(ids)))
        .write(SalesTableCompanion(syncedAt: Value(DateTime.now())));
  }

  Future<void> markRefundsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(refundsTable)..where((t) => t.id.isIn(ids)))
        .write(RefundsTableCompanion(syncedAt: Value(DateTime.now())));
  }
```

- [ ] **Step 2: Add `getSaleSyncPayload`**

Same block, following the existing `getReceiptById` join pattern (line 227) but returning a plain map, per the design doc's payload shape:

```dart
  Future<Map<String, Object?>> getSaleSyncPayload(int saleId) async {
    final saleRow = await (select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ])
          ..where(salesTable.id.equals(saleId)))
        .getSingle();
    final sale = saleRow.readTable(salesTable);
    final user = saleRow.readTableOrNull(usersTable);

    final itemRows = await (select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ])
          ..where(saleItemsTable.saleId.equals(saleId))
          ..orderBy([OrderingTerm.asc(saleItemsTable.id)]))
        .get();

    final items = <Map<String, Object?>>[];
    for (final row in itemRows) {
      final item = row.readTable(saleItemsTable);
      final product = row.readTableOrNull(productsTable);
      final mods = await (select(saleItemModifiersTable)
            ..where((t) => t.itemId.equals(item.id)))
          .get();
      items.add({
        'product_name': product?.name ?? 'Unknown Product',
        'variant_name': item.variantName,
        'qty': item.qty,
        'unit_price': item.unitPrice,
        'discount_type': item.discountType,
        'discount_amount': item.discountAmount,
        'vat_exempt_amount': item.vatExemptAmount,
        'modifiers': mods
            .map((m) => {
                  'name': m.modifierName,
                  'additional_price': m.additionalPrice,
                })
            .toList(),
      });
    }

    final payments =
        await (select(paymentsTable)..where((t) => t.saleId.equals(saleId))).get();

    return {
      'local_id': sale.id,
      'so_number': sale.soNumber,
      'cashier_name': user?.name ?? 'Unknown',
      'created_at': sale.createdAt.toUtc().toIso8601String(),
      'type': sale.type,
      'status': sale.status,
      'total': sale.total,
      'discount': sale.discount,
      'void_reason': sale.voidReason,
      'voided_at': sale.voidedAt?.toUtc().toIso8601String(),
      'items': items,
      'payments': payments
          .map((p) => {
                'method': p.method,
                'amount': p.amount,
                'cash_received': p.cashReceived,
                'reference': p.reference,
              })
          .toList(),
    };
  }
```

- [ ] **Step 3: Add `getRefundSyncPayload`**

`sale_item_index` is the refunded item's position (0-based) within that sale's own `items` array above — the sale payload never exposes local `sale_item` row ids, so the backend correlates a refund line back to a sale line by position, not by id:

```dart
  Future<Map<String, Object?>> getRefundSyncPayload(int refundId) async {
    final refund =
        await (select(refundsTable)..where((t) => t.id.equals(refundId))).getSingle();
    final sale =
        await (select(salesTable)..where((t) => t.id.equals(refund.saleId))).getSingle();

    final itemRows = await (select(saleItemsTable).join([
      leftOuterJoin(productsTable, productsTable.id.equalsExp(saleItemsTable.productId)),
    ])
          ..where(saleItemsTable.saleId.equals(refund.saleId))
          ..orderBy([OrderingTerm.asc(saleItemsTable.id)]))
        .get();

    final indexBySaleItemId = <int, int>{};
    final productNameBySaleItemId = <int, String>{};
    for (var i = 0; i < itemRows.length; i++) {
      final item = itemRows[i].readTable(saleItemsTable);
      final product = itemRows[i].readTableOrNull(productsTable);
      indexBySaleItemId[item.id] = i;
      productNameBySaleItemId[item.id] = product?.name ?? 'Unknown Product';
    }

    final refundItems = await (select(refundItemsTable)
          ..where((t) => t.refundId.equals(refundId)))
        .get();

    return {
      'local_id': refund.id,
      'refund_number': refund.refundNumber,
      'sale_local_id': sale.id,
      'sale_so_number': sale.soNumber,
      'reason': refund.reason,
      'method': refund.method,
      'total': refund.total,
      'created_at': refund.createdAt.toUtc().toIso8601String(),
      'items': refundItems
          .map((ri) => {
                'sale_item_index': indexBySaleItemId[ri.saleItemId] ?? 0,
                'product_name':
                    productNameBySaleItemId[ri.saleItemId] ?? 'Unknown Product',
                'qty': ri.qty,
                'amount': ri.amount,
              })
          .toList(),
    };
  }
```

- [ ] **Step 4: Reset `synced_at` on void**

Modify the existing `voidSale` (line 419):

```dart
  Future<int> voidSale(int saleId, {String reason = 'Voided by cashier'}) =>
      (update(salesTable)..where((t) => t.id.equals(saleId))).write(
        SalesTableCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
          voidedAt: Value(DateTime.now()),
          syncedAt: const Value(null),
        ),
      );
```

(Unconditional — setting an already-`null` `synced_at` back to `null` is a no-op, so there's no need to check the current value first.)

- [ ] **Step 5: Verify**

Run: `dart analyze`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/daos/sales_dao.dart
git commit -m "feat: add transaction sync read/write methods to SalesDao"
```

---

### Task 3: Response DTO

**Files:**
- Create: `lib/data/backend_api/schemas/transaction_sync_result_dto.dart`
- Generated: `lib/data/backend_api/schemas/transaction_sync_result_dto.mapper.dart`

- [ ] **Step 1: Write the DTO**, matching the style of `lib/data/backend_api/schemas/webhook_token_dto.dart`:

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'transaction_sync_result_dto.mapper.dart';

/// Response of `POST /merchant/transactions/sync`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class TransactionSyncResultDto with TransactionSyncResultDtoMappable {
  const TransactionSyncResultDto({
    required this.acceptedSaleIds,
    required this.acceptedRefundIds,
  });

  /// `local_id`s from the request the server durably stored. Anything sent
  /// but not listed here — rejected or lost to a whole-request failure —
  /// stays unsynced and is retried next tick.
  final List<int> acceptedSaleIds;
  final List<int> acceptedRefundIds;

  static const fromJson = TransactionSyncResultDtoMapper.fromJson;
}
```

- [ ] **Step 2: Generate and verify**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then: `dart analyze`
Expected: `transaction_sync_result_dto.mapper.dart` is generated; no analyzer errors.

- [ ] **Step 3: Commit**

```bash
git add lib/data/backend_api/schemas/transaction_sync_result_dto.dart lib/data/backend_api/schemas/transaction_sync_result_dto.mapper.dart
git commit -m "feat: add TransactionSyncResultDto"
```

---

### Task 4: API source

**Files:**
- Create: `lib/data/backend_api/sources/transaction_sync_api.dart`

- [ ] **Step 1: Write the API source**, matching `lib/data/backend_api/sources/merchant_devices_api.dart`'s shape (authenticated `dpoSocketApiClientProvider`, `ApiCall.guard`):

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/transaction_sync_result_dto.dart';

final transactionSyncApiProvider = Provider<TransactionSyncApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return TransactionSyncApi(httpClient);
});

class TransactionSyncApi with ApiCall {
  const TransactionSyncApi(this._httpClient);

  final Dio _httpClient;

  /// `POST /merchant/transactions/sync`. `Authorization: Bearer <token>` is
  /// attached automatically by `WebhookTokenInterceptor` on this client —
  /// callers must call `WebhookAuthRepository.ensureToken(storeId)` first
  /// (see `TransactionSyncService.syncPending`), since the interceptor only
  /// attaches an already-cached token, it doesn't mint one from nothing.
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

- [ ] **Step 2: Verify**

Run: `dart analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/data/backend_api/sources/transaction_sync_api.dart
git commit -m "feat: add TransactionSyncApi"
```

---

### Task 5: Sync service

**Files:**
- Create: `lib/core/services/transaction_sync/transaction_sync_service.dart`

- [ ] **Step 1: Write the service**

```dart
import '../../database/app_database.dart';
import '../../../data/backend_api/sources/transaction_sync_api.dart';
import '../../../features/live_orders/repositories/webhook_auth_repository.dart';

/// One attempt to push everything currently unsynced, capped at
/// [SalesDao.getUnsyncedSaleIds]/[getUnsyncedRefundIds]'s default 15-per-table
/// limit. Called by both the periodic worker and the reconnect listener —
/// this is the only place sync logic lives.
///
/// Throws on any failure (auth or network) so the caller decides how to
/// react; per the design doc this is always "do nothing, let the next tick
/// retry" — no row is marked synced unless the server actually accepted it.
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

    await db.salesDao.markSalesSynced(result.acceptedSaleIds);
    await db.salesDao.markRefundsSynced(result.acceptedRefundIds);
  }
}
```

- [ ] **Step 2: Verify**

Run: `dart analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/transaction_sync/transaction_sync_service.dart
git commit -m "feat: add TransactionSyncService.syncPending"
```

---

### Task 6: Periodic worker (unified with the existing backup dispatcher)

**Files:**
- Create: `lib/core/workers/transaction_sync_worker.dart`
- Modify: `lib/core/workers/backup_worker.dart` (add the second task branch — see the "Key existing-codebase facts" note at the top of this plan for why this can't be a second independent dispatcher)

- [ ] **Step 1: Write the new worker file** — task name constant + the actual tick logic + the registration function. No `Workmanager().initialize()` call here; `backupCallbackDispatcher` (modified in Step 2) is the one and only registered dispatcher for the whole app.

```dart
import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../config/environment/app_env.dart';
import '../../config/environment/env.dart';
import '../../data/backend_api/sources/transaction_sync_api.dart';
import '../../features/live_orders/repositories/webhook_auth_repository.dart';
import '../database/app_database.dart';
import '../services/transaction_sync/transaction_sync_service.dart';

const String kTransactionSyncTaskName = 'periodic_transaction_sync';

/// Upper bound on the random delay applied before every sync attempt
/// (periodic tick and reconnect trigger alike), so devices whose 15-minute
/// ticks happen to align — or that all reconnect after a shared outage —
/// don't all hit the sync endpoint in the same instant.
const _syncJitterMax = Duration(seconds: 15);

/// Runs one sync attempt against [db]. A throwaway [ProviderContainer] gives
/// access to the real `transactionSyncApiProvider`/`webhookAuthRepositoryProvider`
/// wiring (Dio client, auth interceptor, token storage) without hand-duplicating
/// it — only `appEnvProvider` needs overriding here, `databaseProvider` isn't on
/// that provider chain since [db] is passed straight into the service call.
Future<void> runTransactionSyncTick(AppDatabase db) async {
  final storeInfo = await db.storeInfoDao.getStoreInfo();
  final storeId = storeInfo?.storeId ?? '';
  if (storeId.isEmpty) return;

  await Future.delayed(Duration(seconds: Random().nextInt(_syncJitterMax.inSeconds)));

  final container = ProviderContainer(
    overrides: [appEnvProvider.overrideWithValue(Env())],
  );
  try {
    await TransactionSyncService.syncPending(
      db,
      container.read(transactionSyncApiProvider),
      container.read(webhookAuthRepositoryProvider),
      storeId,
    );
  } finally {
    container.dispose();
  }
}

/// Safe to call on every app startup — `ExistingPeriodicWorkPolicy.keep`
/// leaves an already-registered job alone. Does NOT call
/// `Workmanager().initialize()` — that happens once, in `schedulePeriodicBackup()`,
/// against the single shared `backupCallbackDispatcher`.
Future<void> schedulePeriodicTransactionSync() async {
  await Workmanager().registerPeriodicTask(
    kTransactionSyncTaskName,
    kTransactionSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
```

- [ ] **Step 2: Extend `backupCallbackDispatcher` to also route the new task**

`lib/core/workers/backup_worker.dart` — replace the body with a branch on `task`:

```dart
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../services/backup/backup_service.dart';
import 'transaction_sync_worker.dart';

const String kBackupTaskName = 'periodic_pos_backup';

@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final db = AppDatabase();
      if (task == kBackupTaskName) {
        await BackupService.createBackupIfChanged(db);
      } else if (task == kTransactionSyncTaskName) {
        await runTransactionSyncTick(db);
      }
      await db.close();
    } catch (_) {
      // A background job failing silently is fine here — the backup safety
      // net (main.dart) and the transaction-sync reconnect listener both
      // retry the next time they get a chance.
    }
    return Future.value(true);
  });
}

/// Registers WorkManager (once, for every periodic task the app has) and
/// schedules the backup job to run roughly every 3 hours.
Future<void> schedulePeriodicBackup() async {
  await Workmanager().initialize(backupCallbackDispatcher);

  await Workmanager().registerPeriodicTask(
    kBackupTaskName,
    kBackupTaskName,
    frequency: const Duration(hours: 3),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
```

- [ ] **Step 3: Verify**

Run: `dart analyze`
Expected: no errors, no unused-import warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/core/workers/transaction_sync_worker.dart lib/core/workers/backup_worker.dart
git commit -m "feat: add periodic transaction-sync WorkManager task"
```

---

### Task 7: Wire into `main.dart` — register the periodic task + reconnect listener

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Register the periodic task at startup**, right after `schedulePeriodicBackup()`:

```dart
  await schedulePeriodicBackup();
  await schedulePeriodicTransactionSync();
  unawaited(_runStartupBackupSafetyNet(db));
```

Add the import:
```dart
import 'core/workers/transaction_sync_worker.dart';
```

- [ ] **Step 2: Add the reconnect listener in `_App.build`**, alongside the existing `ref.listen(webhookAuthStatusProvider, ...)` / `ref.listen(deviceTokenStatusProvider, ...)` calls. A small random jitter (0–15s) is added before firing — with one device per store this changes nothing for a single store, but if the backend or a shared network link drops and every store's device reconnects in the same instant, this spreads the resulting wave of sync requests out instead of all of them landing on the server in the same second:

```dart
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOnline = previous?.value ?? false;
      final isOnline = next.value ?? false;
      if (wasOnline || !isOnline) return;
      unawaited(_syncTransactionsNow(ref));
    });
```

Add the handler function (near `_runStartupBackupSafetyNet`):

```dart
/// Fires one immediate sync attempt on a false→true connectivity edge, so a
/// store doesn't wait out the WorkManager 15-minute floor after reconnecting.
/// The random delay spreads out the case where many stores' devices regain
/// connectivity in the same instant (e.g. after a shared outage), instead of
/// every device's retry landing on the sync endpoint in the same second.
/// Silent on failure by design — see the sync design doc's error handling.
Future<void> _syncTransactionsNow(WidgetRef ref) async {
  await Future.delayed(Duration(seconds: Random().nextInt(15)));
  try {
    final storeId = ref.read(storeInfoProvider).value?.storeId ?? '';
    if (storeId.isEmpty) return;
    await TransactionSyncService.syncPending(
      ref.read(databaseProvider),
      ref.read(transactionSyncApiProvider),
      ref.read(webhookAuthRepositoryProvider),
      storeId,
    );
  } catch (_) {
    // Retried on the next scheduled tick or the next reconnect edge.
  }
}
```

Add the imports:
```dart
import 'dart:math';

import 'core/connectivity/connectivity_status_provider.dart';
import 'core/services/transaction_sync/transaction_sync_service.dart';
import 'data/backend_api/sources/transaction_sync_api.dart';
import 'features/live_orders/repositories/webhook_auth_repository.dart';
import 'features/settings/state/store_info_notifier.dart';
```

- [ ] **Step 3: Verify**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then: `dart analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: schedule transaction sync and trigger it on reconnect"
```

---

### Task 8: Manual verification (no automated tests — project convention)

- [ ] **Step 1:** `dart run build_runner build --delete-conflicting-outputs` then `dart analyze` — must be clean end to end.
- [ ] **Step 2:** Fresh install or existing dev DB at v14: launch the app, confirm it migrates to v15 without error (`PRAGMA user_version` reads 15; no crash on `sales`/`refunds` reads).
- [ ] **Step 3:** With network off, complete a sale and a refund. Inspect the DB (`sales.synced_at` / `refunds.synced_at`) — both must be `NULL`.
- [ ] **Step 4:** Re-enable network. Confirm the reconnect listener fires within ~15s (the jitter window) and, once the backend endpoint exists, `synced_at` gets set on both rows. Until that backend endpoint ships, confirm instead that `ensureToken`/`pushBatch` fail cleanly and `synced_at` stays `NULL` with no crash and no visible error toast.
- [ ] **Step 5:** Void a previously-synced sale (fake a non-null `synced_at` via a manual DB edit if the backend isn't live yet) and confirm `voidSale` resets it to `NULL`.
- [ ] **Step 6:** Confirm the existing 3-hourly backup job still runs (check `BackupStorageService.lastBackupAt()` advances) — this validates the unified dispatcher in Task 6 didn't regress the pre-existing worker.

---

## Self-review notes

- **Spec coverage:** schema (Task 1), DAO (Task 2), DTO (Task 3), API (Task 4), service (Task 5), scheduling incl. reconnect (Task 6–7), backfill (no dedicated task — it's the natural consequence of Task 1's `NULL` default + Task 2/5's oldest-first queries, called out in Task 8 Step 2–3), store identity (already sourced from `storeInfoDao` via `store_info_notifier.dart`, used as-is in Tasks 6–7), error handling (built into `syncPending`'s throw-and-let-caller-swallow shape, Task 5/6/7). Verified against every section of `docs/superpowers/specs/2026-09-11-transaction-remote-sync-design.md`.
- **Deviation from the design doc, and why:** the design doc's "Files touched" table implies `transaction_sync_worker.dart` calls `Workmanager().initialize()` itself, parallel to `backup_worker.dart`. Reading the actual `workmanager` package usage in this repo showed that's a single global registration — Task 6 unifies the two dispatchers instead, to avoid silently breaking the existing backup job.
- **Manual sync trigger:** deliberately not built — see the chat answer for the reasoning; nothing here blocks adding one later (it's a one-line call to `TransactionSyncService.syncPending` from wherever a "Sync Now" button would live).
