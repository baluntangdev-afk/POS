# POS Kiosk — Lag & Reliability Investigation: Findings & Fix Plan

> **Scope:** Flutter kiosk app (`kiosk/`) + NestJS backend (`be/`), sales confirm pipeline,
> transaction history listing, and receipt History archiving.
> **Method:** static code investigation (no runtime profiling). All line numbers verified
> against the current working tree.

---

## 1. Executive Summary

The "sale is slow / sale is missing / sale is duplicated" complaints trace back to one
structural problem: **the checkout flow is a multi-call HTTP saga with no idempotency, no
client-side record of server state, and error handling that lies to the operator.**

| # | Finding | Impact | Severity |
|---|---------|--------|----------|
| F1 | Timeout/failure after the server already committed shows an **error dialog** — cashier believes the sale failed, re-rings → duplicates | Data integrity, double-charge | **Critical** |
| F2 | Backend `POST /sales-orders` is an **upsert that appends the full cart** to any existing PENDING order — a blind retry duplicates every line item | Data integrity | **Critical** |
| F3 | The **Confirm button shows no progress state** during the multi-second confirm chain (`isEnabled` logic makes the spinner branch unreachable) | Perceived lag | **High** |
| F4 | Post-commit enrichment (`getUserById`, `payments.getAll`) can **throw after the sale is committed**; `.data.first` throws `StateError` on empty | False failure → duplicates | **High** |
| F5 | Transactions screen **defaults to today-only** — yesterday's sales "disappear" until the filter pill is cleared | "Missing" transactions | **High** |
| F6 | Non-admin/non-supervisor users are **scoped to `createdBy = self`** server-side with no UI hint — online/webhook and other cashiers' sales never appear | "Missing" transactions | **Medium** |
| F7 | Receipt PDF is archived to `History\` **only if printing succeeds** — no printer / print error = no audit copy, silently swallowed | Audit gap | **Medium** |
| F8 | Transaction list does **N+1 `getUserById` lookups** + a terminal fetch per page, and blanks to full-screen loading on every page/search change | List lag | **Medium** |

**Recommended order of attack:** make the confirm pipeline idempotent and truthful first
(C1–C4), then fix the "missing" perception (H1–H3), then History + list performance (M1–M3).

---

## 2. Findings

### 2.1 Confirmed transactions "missing" or appearing to fail

#### F1 — Timeout-after-commit reports failure for a committed sale (Critical)

The confirm flow is a three-call chain, and the first call is the only one that matters:

```dart
// kiosk/lib/features/sales/state/ordering_notifier.dart:293-304
Future<void> confirmSale() async {
  ...
  final receipt = await finalizeSale(sale, store: store, cashier: cashier);
  return state.requireValue.copyWith(receipt: receipt);
}
```

```dart
// kiosk/lib/features/sales/use_cases/finalize_sale.dart:30-36
Future<Receipt> call(Sale sale, {required Store store, required Cashier cashier}) async {
  ...
  final actualSale = await _saleRepository.save(sale);   // ① POST /sales-orders (create/upsert)
  final draftReceipt = _receiptFromSale(actualSale, ...);
  return _receiptRepository.save(draftReceipt);          // ② PATCH .../confirm (+ ③ enrichment)
}
```

- `POST /sales-orders` creates **or appends** the order — server work is already durable
  after ① returns.
- `PATCH /:id/confirm` commits status + payment in a transaction
  (`be/src/sales-orders/services/confirm-sales-order.service.ts:33-36`) **before** the
  response is serialized.
- Timeouts are a flat **1 minute** for connect and receive
  (`kiosk/lib/network/http_client.dart:12-13`).

If the request times out, the connection drops, or any call **after** commit fails, the
client shows an error dialog — for a sale that exists in the database:

```dart
// kiosk/lib/features/sales/view/payment_screen.dart:621-627
ref.listen(orderingProvider.select((it) => it.whenData((data) => data.receipt)), (_, next) {
  ...
  } else if (next case AsyncError(:final error)) {
    showNetworkErrorDialog(context, error: error);   // no onRetry, no "check if it landed"
  }
});
```

Riverpod 3.1 preserves the previous state value during `AsyncError` (`copyWithPrevious`),
so `hasPayment` stays `true` after the failure and the Confirm button **re-enables**
(`payment_screen.dart:629`) — the cashier can tap again, re-running the whole chain from
scratch against a server that may already have the sale (see F2).

**No recovery path exists:** the client never re-reads `GET /api/v1/sales-orders/current`
(backend offers it at `sales-orders.controller.ts:62-67`, kiosk never calls it), and the
backend order id returned by ① is never written back into `OrderingData`
(`ordering_notifier.dart:304` only does `copyWith(receipt: ...)`).

#### F4 — Success can be converted into false failure *after* commit (High)

```dart
// kiosk/lib/features/sales/repositories/receipt_repository.dart:79-96
Future<Receipt> save(Receipt receipt) async {
  final confirmResponseDto = await _salesOrdersApi.confirm(...);   // ← commit happens here
  _syncSignal?.notify();

  final (userDto, paginatedPaymentDto) = await (                   // ← enrichment, can throw
    _usersApi.getUserById(confirmResponseDto.createdBy),
    _paymentsApi.getAll(PaymentQueryDto(soNumber: ...)),
  ).wait;

  return _receiptFromSalesOrderWithItemsDto(
    ...
    payment: _paymentFromPaymentResponseDto(paginatedPaymentDto.data.first), // StateError if empty
  );
}
```

Any failure in the enrichment pair (or `.data.first` on an empty payment list) throws
**after** the sale is committed — the UI reports an error for a confirmed sale. `getById`
guards this with `data.firstOrNull` (`receipt_repository.dart:114`); `save` does not.

Compounding this, the receipt screen auto-fetches by id on entry and pops to the menu on
failure (`kiosk/lib/features/sales/view/receipt_screen.dart:59-68`), so a transient error
after a successful confirm dumps the cashier back to the catalog with no receipt — again
looking like a failed sale.

#### F5 — Today-only default filter (High)

```dart
// kiosk/lib/features/sales/view/transactions_screen.dart:46
final soDate = useState<DateTime?>(DateTime.now());   // defaults to TODAY
```

- Any sale outside today's window is invisible until the pill's clear (✕) is tapped —
  the most common "transactions are missing" report.
- The backend reinforces it: `soDate` is transformed with `startOf('day')`
  (`be/src/sales-orders/dto/sales-order-query.dto.ts:58`, applied at
  `sales-orders.service.ts:61-63`), so the query is strictly day-bounded.
- `soDate` on the order is stamped **at create time**, not confirm time
  (`be/src/sales-orders/services/create-sales-order.service.ts:36-40`) — an order created
  23:59 and confirmed 00:01 belongs to "yesterday" and is hidden by today's default the
  moment the cashier looks for it.
- The date pill state resets whenever the screen rebuilds, so the default quietly
  re-applies between visits.

#### F6 — Cashier scoping hides other people's sales (Medium)

```ts
// be/src/sales-orders/sales-orders.service.ts:74-79
} else if (!isAdminOrSupervisor) {
  baseWhere.createdBy = { id: currentUser.id };
}
```

Non-admin/non-supervisor sessions only ever receive **their own** sales. Online/webhook
orders (created under a system user) and other cashiers' sales never appear. The kiosk UI
shows no hint that the list is scoped, so the operator reads it as data loss.

### 2.2 `History\` folder — receipt archiving (F7)

```dart
// kiosk/lib/features/sales/state/receipt_notifier.dart:33-45
Future<void> print() async {
  ...
  await printerTransport.sendData(data);                 // ← must succeed first
  await _saveToHistory(receipt: ..., serialNumber: ...);  // ← only then archive
}
```

- Archiving runs **only after a successful print**. No printer configured, printer error,
  or `kIsWeb` / non-Windows early return (`receipt_notifier.dart:35`) → **no PDF is ever
  written**.
- Archive failures themselves are swallowed silently (`receipt_notifier.dart:57-59`), so a
  full-disk or permissions problem leaves no trace.
- Path: `<exe dir>\History\<year>\<month>\receipt_<SO>.pdf`
  (`kiosk/lib/services/history/history_archive_service.dart:20-36`) — production location
  `C:\POSKiosk\History\2026\10\...`.
- The same print-then-archive coupling exists in the reporting notifiers:
  `z_reading_notifier.dart:56-68`, `cashier_x_reading_notifier.dart:~60-75`,
  `cashier_daily_report_notifier.dart:~60-70`.
- The manual Reprint button surfaces print errors (`receipt_screen.dart:1044-1048`), but
  if the only print attempt failed nothing was archived — reprinting is the only way to
  retroactively create the History file.

### 2.3 Backend update behavior (F2 + supporting)

#### F2 — `POST /sales-orders` upserts by "latest PENDING order" (Critical)

```ts
// be/src/sales-orders/sales-orders.service.ts:320-331
async upsert(dto: CreateSalesOrderDto, causer: User): Promise<SalesOrderWithItemsMapper> {
  const so = await this.findCurrentByUser(causer.id);
  if (so) {
    dto.id = so.id;
    await this.appendSalesOrderItemService.execute(dto, causer);   // ← appends FULL cart again
    return this.findOneWithItems(so.id);
  } else {
    const savedSoId = await this.createSalesOrderService.execute(dto, causer);
    return this.findOneWithItems(savedSoId);
  }
}
```

- The kiosk always sends the **entire cart** on create (`sale_repository.dart:32-36` →
  `POST /api/v1/sales-orders`, `sales_orders_api.dart:24-31`). A retry after a failed
  confirm finds the still-PENDING order and **appends a second copy of every line item**
  (`append-sales-order-item.service.ts:29-66`).
- If the PENDING order was already confirmed (timeout-after-commit), `findCurrentByUser`
  returns nothing and the retry **creates a brand-new duplicate transaction**.
- `findCurrentByUser` (`sales-orders.service.ts:297-305`) has **no age guard** — a PENDING
  draft abandoned days ago is still the merge target for the next sale of that user,
  blending stale items into a new sale.

#### Confirm endpoint is not idempotent

```ts
// be/src/sales-orders/services/confirm-sales-order.service.ts:21-41
async execute(soId, confirmSalesOrderDto, causer) {
  const salesOrder = this.salesOrderRepository.create({ id: soId, status: CONFIRMED, ... });
  const payment = PaymentDetailsToPaymentMapper.toEntity(soId, ...);  // NEW payment row
  await ...transaction(async (em) => { await em.save(salesOrder); await em.save(payment); });
  this.eventEmitter.emit(ORDER_CONFIRMED, ...);   // fired AFTER commit (good)
  return soId;
}
```

- **No status guard** — re-confirming an already-CONFIRMED order runs the transaction
  again and inserts a **duplicate payment row** (the mapper always news up an entity:
  `be/src/payments/mapper/payment-details-to-payment.mapper.ts:13-25`).
- Commit happens inside the transaction; the controller then re-reads the full graph for
  the response (`sales-orders.controller.ts:150-151` `findOneWithItems`) — response
  serialization can be slow/fail **after** commit, widening the F1 window.
- `ORDER_CONFIRMED` listeners run inline sync work before their first await:
  `inventory-counts.service.ts:35,66,88,120,135`, `erp-order-push.service.ts:42`,
  `erp-local-stock.service.ts:29`.

---

## 3. Root Causes — Kiosk vs Backend

| # | Root cause | Side | Explains |
|---|-----------|------|----------|
| R1 | **No idempotency anywhere in checkout** — no client-generated request id, no status guard on confirm, no resume of an in-flight sale | Both | F1, F2, F4, duplicate payments |
| R2 | **Client doesn't persist server state** — backend SO id from create is discarded; `OrderingData` only ever gets `receipt` | Kiosk | F1 (no recovery), F2 (blind re-POST) |
| R3 | **Error dialog is terminal & unconditional** — any post-commit failure renders as "failed", no `onRetry`, no reconciliation query | Kiosk | F1, F4, phantom re-rings |
| R4 | **UI reports no progress through a multi-second pipeline** — `isEnabled = !isLoading && hasPayment` makes the designed spinner branch unreachable | Kiosk | F3 (perceived lag) |
| R5 | **"Current order" lookup merges by user + PENDING only, forever** | Backend | F2, stale-draft merges |
| R6 | **List semantics default to narrow (today-only) and are silently scoped (self-only)** with no UI affordance | Kiosk + Backend | F5, F6 |
| R7 | **Archiving coupled to print success; failures swallowed** | Kiosk | F7 |
| R8 | **Response payloads force N+1 client enrichment + full-graph re-reads** | Both | F8, longer F1 window |

---

## 4. Prioritized Fix Plan

### Critical

**C1 — Idempotent confirm (backend)**
`be/src/sales-orders/services/confirm-sales-order.service.ts:21-41`
Guard before the transaction:

```ts
const existing = await this.salesOrderRepository.findOne({ where: { id: soId } });
if (existing?.status === SalesOrderStatus.CONFIRMED) return soId;  // replay → no-op
```

Also skip inserting a payment row if one already exists for `soId`
(`payment-details-to-payment.mapper.ts:13-25` always news up an entity).
*Makes any client retry of `PATCH /:id/confirm` safe.*

**C2 — Idempotent create: client request id (both sides)**
- Kiosk: generate a UUIDv7 per checkout attempt (already have `UuidV7.generate()`,
  `finalize_sale.dart:6` import) and send it in `CreateSalesOrderDto`
  (`kiosk/lib/data/backend_api/schemas/…`, sent from `sale_repository.dart:32-36`).
- Backend: add nullable `clientRequestId` column (migration) + `dto` field; in
  `upsert` (`sales-orders.service.ts:320-331`), look up by `(createdBy, clientRequestId)`
  **first**; if found, return it as-is instead of appending:

```ts
// sales-orders.service.ts upsert — first line of defense
const replay = await this.salesOrderRepository.findOne({
  where: { createdBy: { id: causer.id }, clientRequestId: dto.clientRequestId },
});
if (replay) return this.findOneWithItems(replay.id);   // retry → same order, no append
```

*Makes blind `POST /sales-orders` retries safe; also neutralises Case A duplicates.*

**C3 — Persist server state in the client + resume instead of restart**
`ordering_notifier.dart:293-304`, `finalize_sale.dart:30-36`
- Have `SaleRepositoryImpl.save` result written back into `OrderingData` (e.g.
  `copyWith(sale: actualSale, receipt: receipt)` — currently only `receipt` is stored,
  `ordering_notifier.dart:304`), so the backend SO id survives an error.
- On retry: if `sale.id` is already a backend id (set by `save`), **skip the create call**
  and go straight to `PATCH /:id/confirm`.

```dart
// finalize_sale.dart:30-36 — resume-aware shape
final actualSale = sale.backendId != null ? sale : await _saleRepository.save(sale);
final draftReceipt = _receiptFromSale(actualSale, store: store, cashier: cashier);
return _receiptRepository.save(draftReceipt);
```

(Requires threading the updated sale back out — `FinalizeSale` currently returns only
`Receipt`; return a `(Sale, Receipt)` record or store id on `OrderingData`.)

**C4 — Post-commit enrichment must not fail the sale**
`receipt_repository.dart:79-96`
- Wrap the enrichment pair in try/catch: on failure, build the receipt from the confirm
  response alone (fallback cashier from `confirmResponseDto.createdBy`, payment from a
  fallback `ZeroPayment`-style default or a second tolerant fetch).
- Replace `paginatedPaymentDto.data.first` with `firstOrNull ??` fallback (match
  `getById` at line 114).
- Never throw after line 81 (`confirm`) has returned successfully.

```dart
// receipt_repository.dart — after confirm, enrichment is best-effort
var cashier = Cashier.unknown();
var payment = receipt.payment ?? ZeroPayment();
try {
  final (userDto, payments) = await (...).wait;
  cashier = _cashierFromUserDto(userDto);
  payment = _paymentFromPaymentResponseDto(payments.data.firstOrNull) ?? payment;
} catch (_) { /* keep fallbacks; the sale is already committed */ }
```

### High

**H1 — Show real progress on the Confirm button (perceived lag)**
`payment_screen.dart:615-706`
`isEnabled = !isLoading && hasPayment` (line 629) means the branch at 676-695
(spinner + "Processing...") is unreachable while loading — lines 633-651 render a static
gray button instead. Fix:

```dart
final isEnabled = hasPayment;              // allow loading state to render
if (!isEnabled) { /* existing disabled branch (633-651) */ }
// enabled branch: onTap: isLoading ? null : confirm;  // spinner already wired at 676-695
```

Also raise `http_client.dart:12-13` only for the confirm call if needed (see L3), but
progress feedback matters more than raw speed.

**H2 — Error dialog gets an honest Retry path (after C1–C4)**
`payment_screen.dart:621-627`, `network_error_dialog.dart:11-16`
`showNetworkErrorDialog(context, error: error)` already supports `onRetry`; pass
`onRetry: () => ref.read(orderingProvider.notifier).confirmSale()` — safe only once
C1–C3 make the pipeline idempotent/resumable. Without C1–C3, a retry button *increases*
duplicates, so this lands strictly after them.

**H3 — Stop defaulting History to today-only**
`transactions_screen.dart:46`
- Default `soDate` to `null` (all dates), or add an explicit `Today` toggle that starts
  **off**; keep the pill for narrowing.
- Re-evaluate the date when the tab regains focus instead of keeping a stale
  `useState` across midnight (`create-sales-order.service.ts:36-40` stamps `soDate` at
  create, so a 23:59 sale hides at 00:01 under a today default).
- Consider filtering by confirm time for CONFIRMED rows (decision needed — see Risks).

**H4 — Surface cashier scoping in the UI**
`sales-orders.service.ts:74-79`
When the current user is not admin/supervisor, show a subtitle/badge on the
Transactions screen: *"Showing only your sales"* (user role is already available from
auth state). No backend change required for the fix; changing scope semantics is a
business decision.

### Medium

**M1 — Archive to `History\` independently of print success**
`receipt_notifier.dart:33-60`
- Move `_saveToHistory` **before** `printerTransport.sendData` (or into `build()`/on
  first load of the receipt), so a print failure never loses the audit copy:

```dart
// receipt_notifier.dart — archive first, print second
await _saveToHistory(receipt: state.requireValue, serialNumber: serialNumber);
await printerTransport.sendData(data);
```

- Replace the silent `catch (_)` (lines 57-59) with at least `debugPrint` /
  crash-report so archive failures are observable.
- Apply the same pattern to `z_reading_notifier.dart:56-68`,
  `cashier_x_reading_notifier.dart:~60-75`, `cashier_daily_report_notifier.dart:~60-70`.

**M2 — Receipt screen must not bounce to menu on a load failure after confirm**
`receipt_screen.dart:59-68`
Retry `getById` with backoff (2-3 attempts) before popping; ideally the receipt is
already in `OrderingData` from the confirm flow — render that as the initial value and
use `getById` only to refresh (refund/void state).

**M3 — Cut transaction-list latency**
- Backend: include cashier name in `findAll`/`findOneWithItems` responses — the mapper
  exposes only `createdBy: salesOrder.createdBy.id`
  (`sales-order-with-items.mapper.ts:25`) even though `createdBy: true` is already
  loaded (`sales-orders.service.ts:144`). Add `createdByFirstName/LastName` (or a nested
  `createdBy: { id, firstName, lastName }`) to the response DTO.
- Kiosk: drop the N+1 fan-out in `receipt_repository.dart:153-162` and use the returned
  names; also skip `getMyTerminal()` on every page (line 143) by caching it per session.
- Kiosk: stop blanking the list on refetch — `transactions_notifier.dart:26-27` sets
  `state = const AsyncLoading()` on every page/search change; keep previous rows
  (`copyWithPrevious` / show a small inline spinner) instead of the full-screen loader
  (`transactions_screen.dart:1401`).

### Low

**L1 — Hide PENDING drafts from the kiosk History list**
Abandoned PENDING orders (Case A leftovers, no age guard — `sales-orders.service.ts:297-305`)
appear as transactions. Either filter `status=CONFIRMED` in the kiosk query
(`TransactionQueryDto`), or add `updatedAt` age guard to `findCurrentByUser` so stale
drafts stop merging *and* stop listing.

**L2 — Backend confirm response weight**
`sales-orders.controller.ts:150-151` re-reads the full graph after commit. A slim
`{ id, soNumber, status, finalTotalAmount, paymentDetails }` response for `PATCH /:id/confirm`
shrinks the post-commit failure window (F1). Kiosk's `SalesOrderWithItemsDto` mapping
would need a lightweight variant.

**L3 — Per-request timeout for checkout**
`http_client.dart:9-14` — flat 1-minute timeouts everywhere. For the create/confirm
calls consider a longer `receiveTimeout` (2 min) *only if* H1 progress feedback ships
first; otherwise the fix order is C1–C4 (idempotency) → then timeouts.

**L4 — `ORDER_CONFIRMED` listeners: audit inline work**
`inventory-counts.service.ts:35,66,88,120,135`, `erp-order-push.service.ts:42` — verify
none of these do slow synchronous work before their first `await` (they run on the
confirm request path before the response is flushed). Move to `setImmediate`/queue if so.

---

## 5. Implementation Order (phased rollout)

**Phase 0 — Ship immediately (no backend dependency, no behavior risk)**
1. H1 — Confirm-button progress state (`payment_screen.dart:629`).
2. M3 (partial) — keep previous transaction rows on refetch instead of full-screen
   loading (`transactions_notifier.dart:26-27`).
3. M1 (partial) — log archive failures instead of `catch (_)`
   (`receipt_notifier.dart:57-59`).

**Phase 1 — Backend idempotency (deploy backend before any kiosk retry changes)**
4. C1 — confirm status guard + duplicate-payment guard.
5. C2 — `clientRequestId` migration + `upsert` replay lookup.
6. L1 — stale-draft guard on `findCurrentByUser` + PENDING filter for list.
> Backend changes are backward-compatible: old kiosk payloads simply omit
> `clientRequestId` (nullable), and the confirm guard only no-ops on replays.

**Phase 2 — Kiosk resume-aware checkout**
7. C3 — persist backend SO id, skip create on resume.
8. C4 — tolerant post-commit enrichment + `firstOrNull`.
9. H2 — Retry in the error dialog (only now that retry is safe).
10. M2 — receipt screen retry-before-pop.

**Phase 3 — List semantics & transparency**
11. H3 — stop defaulting to today-only.
12. H4 — "showing only your sales" badge.
13. M3 (rest) — cashier names in response DTO, drop N+1, cache terminal.

**Phase 4 — History & payloads**
14. M1 — archive before print (all four notifiers).
15. L2 — slim confirm response.
16. L3 — per-request timeouts.
17. L4 — listener audit.

---

## 6. Testing Checklist

### 6.1 Timeout-after-commit (F1 + C1–C4)
- [ ] **Reproduce first:** add an artificial delay/failure *after* commit — e.g. temporary
      `await new Promise(r => setTimeout(r, 70_000))` after
      `transaction(...)` in `confirm-sales-order.service.ts:36`, or drop the response with
      a proxy (toxiproxy/clumsy) after the backend sends it.
- [ ] **Pre-fix behavior:** kiosk shows "Request Timed Out" error; DB row is
      `CONFIRMED`; payment row exists; cashier retaps Confirm → **duplicate observed**
      (record the exact duplicate shape: new SO vs appended items).
- [ ] **Post-fix:** error dialog offers Retry; tapping it re-runs confirm only (C3);
      response returns success; **still exactly one SO + one payment row**:
      ```sql
      SELECT so_number, status, final_total_amount FROM sales_orders ORDER BY created_at DESC LIMIT 5;
      SELECT sales_order_id, COUNT(*) FROM payments GROUP BY sales_order_id HAVING COUNT(*) > 1;
      ```
- [ ] Replaying `PATCH /:id/confirm` twice via curl → second is a no-op, single payment row.
- [ ] Replaying `POST /api/v1/sales-orders` with same `clientRequestId` → same SO id,
      items **not** appended (sum of item rows unchanged).
- [ ] Retry when the order was *not* yet created (failure at step ①) → creates exactly once.

### 6.2 Today-only filter (F5 + H3)
- [ ] With default state, a sale created yesterday is visible without touching the pill
      (or the Today toggle is clearly off — per chosen H3 design).
- [ ] Clearing/setting the pill still narrows to a single day (backend `startOf('day')`
      at `sales-order-query.dto.ts:58` unchanged).
- [ ] Order created 23:59, confirmed 00:01 → visible under "today" *and/or* "yesterday"
      per chosen semantics (document the expected behavior before coding H3).
- [ ] Switching kiosk system date across midnight → list reflects the new date, no
      stale pill from the previous day.

### 6.3 Cashier scoping (F6 + H4)
- [ ] Cashier A logs in, sells an order → appears in A's History.
- [ ] Cashier B logs in → A's order does **not** appear (backend scope at
      `sales-orders.service.ts:74-79` working); badge text visible.
- [ ] Admin/supervisor → sees all cashiers' orders, no badge.
- [ ] A webhook/online order (created under system/other user) → absent for cashiers,
      present for admin — confirm this matches business expectation; if not, that's a
      scope change ticket, not a UI fix.

### 6.4 Duplicates (F2 + C2/C3)
- [ ] Kill network between step ① and ② (`finalize_sale.dart:33-35`), retry →
      **no doubled line items** (pre-fix: `append-sales-order-item.service.ts:29-66`
      doubles the cart).
- [ ] Abandon a cart mid-checkout (error, restart app), make a new sale next day →
      new sale does **not** merge with the stale PENDING draft (C2 replay key / L1 age
      guard).
- [ ] Double-tap Confirm rapidly → single transaction (button disabled while loading
      after H1, plus C1 server guard).
- [ ] Full happy path → exactly one `sales_orders` row, one `payments` row, item totals
      equal to cart total.

### 6.5 History write (F7 + M1)
- [ ] Complete a sale **with no printer configured / printer offline** →
      `C:\POSKiosk\History\<year>\<month>\receipt_<SO>.pdf` still exists (M1).
- [ ] Complete a sale with printer working → PDF exists, content matches on-screen
      receipt (totals, discounts, VAT lines).
- [ ] Force an archive failure (read-only folder) → failure is logged, sale flow
      unaffected (no error dialog).
- [ ] Z-reading / cashier X-reading / daily report → PDFs archived even if print fails.
- [ ] Reprint from receipt screen does not create a duplicate History file (same
      filename overwrite is fine — verify it's idempotent).

### 6.6 Regression
- [ ] `dart analyze` clean (kiosk), `npm run lint` + `npm run test` clean (backend).
- [ ] Void/refund flows still work against a confirmed order.
- [ ] ERP push / inventory-count events fire exactly once per confirmed order (C1 guard
      must not double-emit; replay path should skip emit too).

---

## 7. Quick Wins (smallest change → largest trust gain)

| # | Change | File | Effort |
|---|--------|------|--------|
| 1 | Re-enable loading branch: `isEnabled = hasPayment` | `payment_screen.dart:629` | ~5 min |
| 2 | `firstOrNull ??` fallback in confirm enrichment (partial C4) | `receipt_repository.dart:94` | ~5 min |
| 3 | Log instead of swallow archive errors | `receipt_notifier.dart:57-59` | ~5 min |
| 4 | Confirm status guard (full C1) | `confirm-sales-order.service.ts:22` | ~30 min |
| 5 | Default `soDate` pill off (`useState<DateTime?>(null)`) | `transactions_screen.dart:46` | ~5 min (verify product intent) |
| 6 | Keep old rows on refetch (`skipLoadingOnReload` / don't set `AsyncLoading`) | `transactions_notifier.dart:26-27` | ~30 min |
| 7 | "Showing only your sales" hint | `transactions_screen.dart` header | ~1 h |

---

## 8. Risks If Not Fixed

| Risk | Consequence | Path |
|------|-------------|------|
| Timeout-after-commit + retap | **Duplicate transactions / double charges**; inflated revenue, wrong Z-readings, refund disputes | F1 → F2 |
| Blind cart re-POST | **Doubled line items** on one SO → wrong totals, wrong VAT, wrong inventory decrement | F2 |
| No progress feedback | Cashier taps repeatedly / force-quits mid-sale → increases every duplicate path above | F3, F4 |
| Enrichment throws post-commit | Sale committed but reported failed → operator re-rings the same customer | F4 |
| Today-only default | "Missing" transactions → support load, wrongful voids/refunds, loss of operator trust | F5 |
| Self-only scope, unmarked | Same-store orders look lost; admins override/double-serve orders | F6 |
| History gated on print success | **No audit PDF** for reprint/chargeback/VAT evidence when printer is down; silent disk failures | F7 |
| N+1 list loads | Slow History screen on weak kiosk hardware → perceived app-wide "lag" | F8 |
| Stale PENDING drafts | Yesterday's abandoned cart silently merged into today's sale → wrong customer total | F2 (age guard) |
| Non-idempotent confirm | Duplicate payment rows corrupt tender reconciliation | F2 / §2.3 |

