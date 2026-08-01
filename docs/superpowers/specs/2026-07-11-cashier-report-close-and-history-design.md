# Cashier Report Close & History — Design Spec

**Date:** 2026-07-11
**Status:** Approved

## Summary

`done_daily_report` and `done_x_reading` on `sales_orders` (added in
[2026-07-10-cashier-report-shift-window](2026-07-10-cashier-report-shift-window-design.md)) are
currently never flipped to `true` — both the X-Reading and Cashier Daily Report `GET` endpoints
are permanently read-only, so every report a cashier generates includes their full history of
unreported transactions forever.

This spec adds the "closing" step that plan deliberately deferred: when a cashier taps **Print**
on either report, the backend atomically (1) computes the report fresh from the DB, (2) persists
that computed report as a snapshot row, (3) flips the covered transactions' `done_*` flag to
`true` and stamps them with the new report's id, so the *next* report starts from a clean window.
It also adds a **Reports** screen so a cashier can browse and reprint their past closed reports.

## Decisions (from brainstorming)

- **Persisted report tables, not a bare id.** Two new tables, `cashier_daily_reports` and
  `cashier_x_readings`, each store one row per close action: `id`, `cashier_id`, `period_start`,
  `period_end`, `generated_at`, and a `snapshot jsonb` column holding the exact response DTO that
  was computed and printed. `sales_orders` gets two new nullable FK columns —
  `daily_report_id` → `cashier_daily_reports.id`, `x_reading_id` → `cashier_x_readings.id`.
  Rationale: the new Reports screen needs to show *exactly* what a past report said, not a
  re-aggregation that could drift if query logic changes later.
- **Print = close.** There is no separate "close" action in the UI. Tapping Print on either report
  screen triggers the server-side close (fresh compute + snapshot insert + flag/id stamp) and
  prints whatever the close call returns — not the possibly-stale on-screen preview. Each Print
  always starts a fresh reporting window for that cashier.
- **Server-computed, not client-supplied.** The kiosk never sends totals in the close request body.
  The close endpoint recomputes from the DB using the same query logic as the existing `GET`
  (`done_* = false AND so_date <= requestTime AND created_by = cashier`, `requestTime` captured
  once), so the printed snapshot is always authoritative as of the moment of closing.
- **Snapshot storage: single JSON column, not normalized tables.** Both report DTOs are rich
  (payment/discount breakdowns, cash ledger entries, product sales lines). Modeling every field as
  typed columns/child tables is not worth it for data that is only ever read back as a whole
  report. `snapshot jsonb` stores the full DTO (the same shape the app already renders).
- **Empty report → close is rejected, not silently created.** If zero transactions match the close
  filter, the endpoint responds with an error (409/validation) rather than persisting an empty
  snapshot. The kiosk enforces this proactively by disabling Print whenever `periodStart == null`.
- **History scope: cashier-owned only.** Both history list and detail endpoints filter to
  `cashier_id = <requesting cashier>`; a cashier can never see another cashier's closed reports.
  Detail lookups for a report that doesn't belong to the requester return 404 (not 403, to avoid
  confirming the id exists).
- **History UI: list → tap → snapshot detail → reprint.** Not a summary-only list. Each tab is a
  paginated list of that cashier's past closed reports (reusing the existing pagination pattern
  from `TransactionsScreen`/`PaginatedResponse<T>`); tapping a row opens the existing preview
  screen rendered from the stored snapshot, with a Reprint action that re-encodes ESC/POS from the
  already-fetched snapshot (no additional backend call).
- **Separate feature area from `kiosk/lib/features/reports/`.** That existing folder is the
  unrelated admin/manager sales-analytics + export module (`ReportsRepository`,
  `SalesReportRoute`, etc.). This feature lives entirely under the existing
  `kiosk/lib/features/cashier_report/` folder with new route names (`CashierReportsRoute`) to avoid
  any naming collision.

## Backend (`be/src/`)

### Migration

New migration, e.g. `cashier-daily-reports-and-x-readings.ts`:

```sql
CREATE TABLE "cashier_daily_reports" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "cashier_id" integer NOT NULL REFERENCES "users"("id"),
  "period_start" timestamp NULL,
  "period_end" timestamp NULL,
  "generated_at" timestamp NOT NULL DEFAULT now(),
  "snapshot" jsonb NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now()
);
CREATE INDEX "idx_cashier_daily_reports_cashier_id" ON "cashier_daily_reports" ("cashier_id");

CREATE TABLE "cashier_x_readings" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "cashier_id" integer NOT NULL REFERENCES "users"("id"),
  "period_start" timestamp NULL,
  "period_end" timestamp NULL,
  "generated_at" timestamp NOT NULL DEFAULT now(),
  "snapshot" jsonb NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT now(),
  "updated_at" timestamp NOT NULL DEFAULT now()
);
CREATE INDEX "idx_cashier_x_readings_cashier_id" ON "cashier_x_readings" ("cashier_id");

ALTER TABLE "sales_orders"
  ADD COLUMN "daily_report_id" uuid NULL REFERENCES "cashier_daily_reports"("id"),
  ADD COLUMN "x_reading_id" uuid NULL REFERENCES "cashier_x_readings"("id");
CREATE INDEX "idx_sales_orders_daily_report_id" ON "sales_orders" ("daily_report_id");
CREATE INDEX "idx_sales_orders_x_reading_id" ON "sales_orders" ("x_reading_id");
```

`down()` drops both new FK columns/indexes on `sales_orders` first, then drops both new tables.

### Entities

New `be/src/reports/entities/cashier-daily-report.entity.ts` and
`cashier-x-reading.entity.ts` (plain TypeORM entities: `id`, `cashierId`/`cashier` relation,
`periodStart`, `periodEnd`, `generatedAt`, `snapshot: Record<string, unknown>`, timestamps).

`sales-orders/entities/sales-order.entity.ts` — add alongside `doneDailyReport`/`doneXReading`:

```ts
@ManyToOne(() => CashierDailyReport, { nullable: true })
@JoinColumn({ name: 'daily_report_id' })
dailyReport: CashierDailyReport | null;

@ManyToOne(() => CashierXReading, { nullable: true })
@JoinColumn({ name: 'x_reading_id' })
xReading: CashierXReading | null;
```

### Close endpoints

`POST /reports/cashier-daily-report/close` and `POST /reports/cashier-x-reading/close`, both
`@CurrentUser()`-scoped, no request body. Each runs inside a single DB transaction:

1. Capture `const requestTime = new Date()`.
2. Compute the report the same way `getReport()` does today (same 7/9 sub-queries, same
   `done_* = false AND so_date <= :requestTime AND created_by = :cashier` filter), inside the
   transaction's query runner.
3. If `periodStart` is null (no qualifying transactions), roll back and throw
   (`ConflictException` or similar — "nothing to close").
4. Insert the new `cashier_daily_reports`/`cashier_x_readings` row: `cashierId`, `periodStart`,
   `periodEnd`, `generatedAt: requestTime`, `snapshot: <computed DTO>`.
5. `UPDATE sales_orders SET done_daily_report = true, daily_report_id = :newId WHERE done_daily_report = false AND so_date <= :requestTime AND created_by = :cashier`
   — identical filter/bound as step 2, so the exact same row set is marked as was aggregated.
6. Commit. Return the snapshot DTO with its new `id` included.

The existing 7/9 private query-builder methods in `cashier-daily-report.service.ts` /
`cashier-x-reading-report.service.ts` are reused (parameterized to accept a query runner/manager
and an explicit `requestTime` instead of always using `NOW()`), rather than duplicated.

### History endpoints

For each report type:

- `GET /reports/cashier-daily-report/history?page=&limit=` — `PaginatedResponse<CashierDailyReportHistoryItemDto>` (reusing `be/src/utils/pagination`), scoped to `cashier_id = causer.id`, ordered `generated_at DESC`. Each item: `id`, `periodStart`, `periodEnd`, `generatedAt`, `totalSales`, `completedTransactions` (pulled from the row's own columns + a couple of fields read out of `snapshot`).
- `GET /reports/cashier-daily-report/history/:id` — full `snapshot` deserialized back into the same response DTO shape as `GET /reports/cashier-daily-report` (plus `id`). 404 if the row doesn't exist or doesn't belong to the requesting cashier.
- Same two endpoints for `cashier-x-reading`.

### DTOs

`CashierDailyReportResponseDto` / `CashierXReadingResponseDto` gain an optional `id: string | null`
(`null` for a live/unclosed preview from the existing `GET`, populated for `close` and history
detail responses). New `CashierDailyReportHistoryItemDto` / `CashierXReadingHistoryItemDto` for
list rows.

## Kiosk (`kiosk/lib/features/cashier_report/`)

- **Repository** (`repositories/cashier_report_repository.dart`) gains: `closeDailyReport()`,
  `closeXReading()`, `getDailyReportHistory({page, limit})`, `getXReadingHistory({page, limit})`,
  `getDailyReportHistoryDetail(id)`, `getXReadingHistoryDetail(id)`.
- **Entities**: `CashierDailyReport` / `CashierXReading` gain `final String? id`. New
  `CashierDailyReportHistoryItem` / `CashierXReadingHistoryItem` entities for list rows.
- **State**: `CashierDailyReportNotifier.print()` / `CashierXReadingNotifier.print()` change from
  "encode the in-memory report" to "call `close...()`, replace in-memory state with the returned
  (now-closed) report, then encode+print that." New paginated `AsyncNotifier` providers for each
  history list (mirroring `transactions_notifier.dart`'s page/limit pattern) and a detail provider
  keyed by report id.
- **Print button gating**: both `_CashierReportButton`/preview-screen Print actions stay disabled
  whenever the loaded report's `periodStart == null`, consistent with the backend rejecting an
  empty close.
- **New screen**: `view/cashier_reports_screen.dart` — `CashierReportsScreen`, a
  `HookConsumerWidget` with a `TabBar` (`X-Reading`, `Cashier Daily Report`). Each tab reuses the
  table/list + pagination-controls pattern already established in `transactions_screen.dart`
  (page/limit state, `_PaginationRow`-style controls), listing that cashier's history items
  newest-first. Tapping a row pushes the existing `CashierReportPreviewScreen` /
  `CashierDailyReportScreen`, fed from the history-detail provider instead of the live
  load-notifier, with a Reprint button that re-runs the existing ESC/POS encode+send use case
  against the already-fetched snapshot (no backend call).
- **Route**: `navigation/router.dart` gets `CashierReportsRoute` at path `/cashier-reports`
  (distinct from the existing singular `/cashier-report` X-Reading route and
  `/cashier-daily-report`).
- **Entry point**: `transactions_screen.dart`'s `_TransactionsHeaderActions` gains a third button,
  `_ReportsButton`, placed after `_CashierDailyReportButton`, matching their existing pill-button
  styling, pushing `CashierReportsRoute`.

## Edge cases

- Two rapid Print taps: the second `close` call's filter naturally matches zero rows (the first
  already flipped everything to `done = true`), so it hits the same "nothing to close" rejection
  as an empty report — no duplicate snapshot, no double-charge risk. The kiosk also disables the
  Print button while the close request is in flight (existing `isLoading`-gated button pattern).
- A sale completes in the moment between the on-screen preview (`GET`) and tapping Print: the
  close call recomputes fresh, so that new transaction is either included (if before
  `requestTime`) or left for the next report — never lost, never double-counted, per the existing
  `so_date <= requestTime` guard from the shift-window plan.
- History detail for a report id that exists but belongs to another cashier: 404, not 403 (don't
  confirm existence to a non-owner).

## Testing

- Backend: service-level test for the close transaction (marks exactly the covered rows, stamps
  the right id, rejects when nothing qualifies, snapshot content matches what was computed) for
  both report types. Mapper/DTO specs for history list + detail responses.
- Kiosk: notifier tests updated for the new close-then-print flow on both existing notifiers; new
  notifier tests for the two history list providers and the two history-detail providers.
- Manual: close a report, confirm the covered transactions no longer appear in the next live
  preview, confirm the closed report appears in the Reports history tab and reprints correctly
  from the stored snapshot.
