# Z-Reading — Design Spec

**Date:** 2026-07-15
**Status:** Approved

## Summary

The existing Cashier Report feature (`kiosk/lib/features/cashier_report/`, `be/src/reports/`) has
X-Reading and "Cashier Daily Report," but neither is a true Z-Reading: both are per-cashier,
perpetually-accumulating "since your last close" snapshots with no day boundary and no grand
cumulative total. Real (BIR-style) Z-Reading is a **store-wide**, supervisor-authorized close of
the day's sales that also reports a **never-resetting grand total** and a **sequential Z-counter**
for audit trail purposes.

This spec adds Z-Reading as a third, independent report type — new tables, new endpoints, a new
kiosk tab — without touching the existing X-Reading/Daily Report code paths.

## Decisions (from brainstorming)

- **Scope: store-wide, not per-cashier.** Z-Reading aggregates all cashiers' unclosed transactions
  together (no `created_by` filter), unlike X-Reading/Daily Report. Any cashier can trigger the
  close, but it requires a supervisor/admin PIN (see below) — the report itself isn't tied to one
  cashier's identity the way the existing two are.
- **Independent watermark.** A new `done_z_reading` boolean + `z_reading_id` FK on `sales_orders`,
  parallel to but completely orthogonal to `done_x_reading`/`done_daily_report`. Closing a
  Z-Reading does **not** force-close outstanding X-Readings or Daily Reports — all three watermarks
  accumulate independently over the same underlying orders.
- **"Day" boundary = since last Z-Reading close, not calendar day.** Same "since last close"
  accumulator semantics as X-Reading/Daily Report, just store-wide instead of per-cashier. No
  calendar-day cutoff logic, no timezone/late-night-shift edge cases to handle.
- **Grand cumulative total: computed, not a mutable counter.** `endingBalance` for a new
  Z-Reading = `SUM(periodTotal from every past z_readings.snapshot) + this period's live total`.
  This is bounded by the number of Z-Readings ever closed (small), not by total order history, and
  requires no changes to the order-completion code path (no invasive running-counter row that could
  silently drift). `beginningBalance` for a new close = the previous Z-Reading's `endingBalance`
  (or `0` if this is the first Z-Reading ever).
- **Sequential Z-counter.** Each closed Z-Reading gets an auto-incrementing `z_counter` allocated
  from a dedicated Postgres `SEQUENCE` (safe under concurrent close attempts), printed on the
  report for audit purposes.
- **Unrestricted close frequency.** No once-per-calendar-day enforcement. Z-Reading can be closed
  on demand, same as X-Reading/Daily Report today. Can be tightened later if real fiscal compliance
  requires it.
- **Preview first, PIN on Print — not on page load.** Opening the Z-Reading screen shows the live,
  read-only preview immediately (`GET`, no auth prompt). The supervisor PIN dialog only appears
  when the cashier taps **Print**, immediately before the close call — matching the existing
  X-Reading/Daily-Report UX of "preview is free, closing is gated."
- **Reuse the existing PIN-authorization flow.** `kiosk/lib/features/sales/view/refund_authorization_dialog.dart`
  already implements an authorizer-picker + PIN-pad dialog backed by `userApi.verifyPin`, used for
  refund authorization. Generalize it into a reusable `SupervisorAuthorizationDialog` (parameterized
  title/message/icon/CTA label) rather than building a new PIN UI; `RefundAuthorizationDialog`
  becomes a thin wrapper over it with no behavior change.
- **Server re-verifies PIN, not just the kiosk.** The kiosk calls `verifyPin` before showing success,
  but the actual `close` endpoint also takes `authorizerId` + `pin` and re-verifies server-side
  inside the close transaction — a financial close must never trust a client-only check.
- **Persisted snapshot table, print = close.** Same pattern as X-Reading/Daily Report: one row per
  close in `z_readings` with a `snapshot jsonb` column holding the exact computed DTO, so history/
  reprint never re-aggregates and can't drift from what was actually printed.
- **Empty close rejected.** If zero unclosed transactions exist store-wide, `close` throws
  (`ConflictException`), same as the existing two report types; kiosk disables Print when the
  preview's `periodStart == null`.
- **History: store-wide, not cashier-scoped.** Unlike X-Reading/Daily-Report history (which is
  filtered to the requesting cashier), Z-Reading history/detail is visible to any cashier — it's a
  store-level record, not a personal one.
- **Supplementary per-cashier breakdown.** Strict BIR Z-Reading format is per-machine, not
  per-cashier (mandatory fields: Beginning/Ending SI number, VATable/VAT-exempt sales, VAT amount,
  discounts, Old Grand Total, New Grand Total, Z-counter — none of it cashier-scoped). BIR doesn't
  prohibit additional information on the tape, so the report adds a **"Sales by Cashier"** section
  (cashier name, transaction count, sales total) below the mandatory store-wide totals, for
  in-store accountability. This section is supplementary only — it doesn't replace or alter any of
  the required aggregate fields.

## Backend (`be/src/`)

### Migration

New migration, e.g. `z-readings.ts`:

```sql
CREATE SEQUENCE "z_readings_z_counter_seq" START 1;

CREATE TABLE "z_readings" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "z_counter" integer NOT NULL DEFAULT nextval('z_readings_z_counter_seq'),
  "period_start" timestamp NULL,
  "period_end" timestamp NULL,
  "generated_at" timestamp NOT NULL DEFAULT now(),
  "closed_by" integer NOT NULL REFERENCES "users"("id"),
  "authorized_by" integer NOT NULL REFERENCES "users"("id"),
  "beginning_balance" numeric(14,2) NOT NULL,
  "ending_balance" numeric(14,2) NOT NULL,
  "snapshot" jsonb NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX "idx_z_readings_z_counter" ON "z_readings" ("z_counter");

ALTER TABLE "sales_orders"
  ADD COLUMN "done_z_reading" boolean NOT NULL DEFAULT false,
  ADD COLUMN "z_reading_id" uuid NULL REFERENCES "z_readings"("id");
CREATE INDEX "idx_sales_orders_z_reading_id" ON "sales_orders" ("z_reading_id");
```

`down()` drops the `sales_orders` columns/index first, then the `z_readings` table, then the
sequence.

### Entity

New `be/src/reports/entities/z-reading.entity.ts`: `id`, `zCounter`, `periodStart`, `periodEnd`,
`generatedAt`, `closedBy`/`closedById` (relation to `User`), `authorizedBy`/`authorizedById`
(relation to `User`), `beginningBalance`, `endingBalance`, `snapshot: Record<string, unknown>`,
timestamps.

`sales-orders/entities/sales-order.entity.ts` — add alongside `doneDailyReport`/`doneXReading`:

```ts
@Column({ name: 'done_z_reading', default: false })
doneZReading: boolean;

@ManyToOne(() => ZReading, { nullable: true })
@JoinColumn({ name: 'z_reading_id' })
zReading: ZReading | null;
```

### Service — `ZReadingReportService` (`be/src/reports/services/z-reading-report.service.ts`)

- **`getReport(causer)`** — store-wide preview: aggregates `sales_orders` where
  `done_z_reading = false AND so_date <= NOW()` and `STATUS_FILTER` (no `created_by` filter). Same
  aggregation categories as `CashierDailyReportResponseDto` (sales by payment method, product
  breakdown, discounts, VAT, voids, refunds, cash total), plus `beginningBalance` (= latest
  `z_readings.ending_balance`, or `0`) and a live-computed `endingBalance` (`beginningBalance` +
  this period's total). Additionally groups the same row set `BY created_by` to produce a
  `salesByCashier` array (`cashierId`, `cashierName`, `transactionCount`, `salesTotal`), ordered by
  `salesTotal DESC` — a supplementary breakdown, not a replacement for the store-wide totals.
- **`closeReport(causer, authorizerId, pin)`** — single DB transaction:
  1. Re-verify `authorizerId`/`pin` server-side (reuse the same verification the `verifyPin`
     endpoint uses) — throws `UnauthorizedException` on failure, no mutation occurs.
  2. Capture `requestTime = new Date()`.
  3. Recompute the report as of `requestTime` (store-wide, same filters as `getReport`).
  4. If `periodStart` is null, roll back and throw `ConflictException` ("nothing to close").
  5. Compute `beginningBalance` (previous `z_readings.ending_balance` or `0`) and
     `endingBalance = beginningBalance + periodTotal`.
  6. Insert the `z_readings` row (`z_counter` auto-allocated from the sequence, `closed_by:
     causer.id`, `authorized_by: authorizerId`, `beginning_balance`, `ending_balance`, `snapshot`).
  7. `UPDATE sales_orders SET done_z_reading = true, z_reading_id = :newId WHERE done_z_reading = false AND so_date <= :requestTime`
     — store-wide, no `created_by` filter.
  8. Commit. Return the snapshot DTO with `id`, `zCounter`, `beginningBalance`, `endingBalance`.
- **`getHistory(page, limit)` / `getHistoryDetail(id)`** — paginated list / detail of past closed
  Z-Readings, **not** scoped to a requesting cashier (store-wide visibility). 404 if `id` doesn't
  exist.

### Controller routes

On the existing `ReportsController`:
- `GET /reports/z-reading` — live preview.
- `POST /reports/z-reading/close` — body `{ authorizerId: string, pin: string }`.
- `GET /reports/z-reading/history?page=&limit=`
- `GET /reports/z-reading/history/:id`

All routes `@CurrentUser()`-scoped (any authenticated cashier may call them); authorization for the
close itself is enforced by the PIN check inside `closeReport`, not by route-level role guards.

### DTOs

New `ZReadingResponseDto` (mirrors `CashierDailyReportResponseDto`'s aggregation fields, adds
`id: string | null`, `zCounter: number | null`, `beginningBalance: number`,
`endingBalance: number`, `salesByCashier: ZReadingCashierBreakdownDto[]`). New
`ZReadingCashierBreakdownDto` (`cashierId`, `cashierName`, `transactionCount`, `salesTotal`). New
`ZReadingHistoryItemDto` for list rows
(`id`, `zCounter`, `periodStart`, `periodEnd`, `generatedAt`, `totalSales`, `endingBalance`).

## Kiosk (`kiosk/lib/features/cashier_report/`)

- **Entities**: `entities/z_reading.dart` (+ `.mapper.dart`) — mirrors `CashierDailyReport` plus
  `zCounter`, `beginningBalance`, `endingBalance`. `entities/z_reading_history_item.dart` for list
  rows.
- **Schemas**: `data/backend_api/schemas/z_reading_dto.dart`, `z_reading_history_item_dto.dart`.
- **Repository** (`repositories/cashier_report_repository.dart`) gains: `getZReading()`,
  `closeZReading({required String authorizerId, required String pin})`,
  `getZReadingHistory({page, limit})`, `getZReadingHistoryDetail(id)`.
- **State**: `state/z_reading_notifier.dart` — loads the live preview on screen open (no PIN
  prompt). Exposes a `close({authorizerId, pin})` method the view calls only after the auth dialog
  succeeds; on success, replaces in-memory state with the returned closed report and triggers
  print. Mirrors `cashier_x_reading_notifier.dart`'s loading/error state shape. New paginated
  history provider + detail provider, store-wide (no cashier filter applied client-side either).
- **Auth dialog**: generalize `refund_authorization_dialog.dart` into
  `widgets/supervisor_authorization_dialog.dart` (`SupervisorAuthorizationDialog.show(context,
  {title, message, ctaLabel, ctaIcon})`), returning the verified `(authorizerId, pin)` pair (not
  just `bool`) so the caller can forward them to its own close call. `RefundAuthorizationDialog`
  becomes a thin wrapper preserving its existing call sites and copy.
- **View**: `view/cashier_z_reading_screen.dart` — live preview screen using the shared
  `report_preview_widgets.dart` components (adds `Z-Counter`, `Beginning Balance`,
  `Ending Balance` rows, plus a "Sales by Cashier" table section below the store-wide totals).
  Print button: disabled when `periodStart == null`; on tap, opens
  `SupervisorAuthorizationDialog`, and only on success calls `close()` then prints the returned
  snapshot via a new `use_cases/encode_esc_pos_z_reading.dart` (reusing `sanitizeForPrinter`),
  which renders the per-cashier lines after the mandatory BIR-style totals.
- **History tab**: `cashier_reports_screen.dart`'s `TabBar` gains a third tab, **"Z-Reading"**,
  listing paginated closed Z-Readings store-wide; tapping a row opens a read-only detail view (same
  screen, fed from history-detail provider) with a Reprint button that re-encodes from the
  already-fetched snapshot (no backend call, no PIN required for reprint).
- **Route**: `navigation/z_reading_route.dart`, registered in `router.dart`.

## Edge cases

- Two rapid Print taps (after PIN success): second `close` call's filter matches zero rows (first
  already flipped everything), hits the same "nothing to close" rejection — no duplicate snapshot.
  Print button also disabled while the close request is in flight.
- PIN entered incorrectly: `close` throws `UnauthorizedException`, dialog shows inline error, PIN
  clears, no mutation occurs, on-screen preview is untouched.
- A sale completes between opening the preview and tapping Print: the close call recomputes fresh
  as of its own `requestTime`, so the new transaction is included or deferred to the next
  Z-Reading — never lost, never double-counted.
- Concurrent Z-Reading closes from two terminals: transaction + `WHERE done_z_reading = false`
  guard + sequence-based `z_counter` prevents any double-close or duplicate counter value.
- First-ever Z-Reading: `beginningBalance = 0` (no prior `z_readings` row).

## Testing

- Backend: service tests for `ZReadingReportService` — empty-close rejection, store-wide
  aggregation (includes orders regardless of `created_by`/`done_x_reading`/`done_daily_report`
  state), correct `z_counter` sequencing under concurrent closes, correct
  `beginningBalance`/`endingBalance` arithmetic across multiple sequential closes, PIN
  re-verification failure path.
- Kiosk: widget test confirming `SupervisorAuthorizationDialog` still backs both the refund and
  Z-Reading call sites correctly. Notifier tests for the preview-then-close flow and for the
  history/detail providers.
- Manual (via `/run`): open Z-Reading preview, tap Print, verify PIN dialog appears (not on page
  load), complete auth, confirm print output includes Z-Counter/Beginning/Ending Balance, confirm
  the closed Z-Reading appears in history and reprints correctly, confirm X-Reading/Daily-Report
  watermarks are unaffected by the Z-Reading close.
