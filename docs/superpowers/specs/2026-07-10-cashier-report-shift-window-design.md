# Cashier Daily Report & X-Reading — Shift Window (Cross-Midnight) — Design Spec

**Date:** 2026-07-10
**Status:** Approved

## Summary

Both the Cashier Daily Report and X-Reading currently scope transactions to
`so.created_by = cashier AND so.so_date::date = CURRENT_DATE`. This breaks for a cashier whose
shift crosses midnight: e.g. logging in at 8 PM and generating either report at 3 AM the next
calendar day currently drops all of the previous day's transactions.

This spec replaces the calendar-day filter with a **per-transaction "already reported" flag**,
so both reports always cover "the cashier's first not-yet-reported transaction, up through
whatever is unreported as of the moment the report is requested" — regardless of calendar date.

## Decisions (from brainstorming)

- **Mechanism:** two new boolean columns on `sales_orders` — `done_daily_report` and
  `done_x_reading`, both `NOT NULL DEFAULT false` — mirroring the existing `done_export` column
  and its use in `ExportableReportService`.
- **Query change:** every sub-query in both report services drops
  `so.so_date::date = CURRENT_DATE` in favor of `so.done_daily_report = false` (daily report) /
  `so.done_x_reading = false` (X-reading), still scoped to `so.created_by = cashier`, plus
  `so.so_date <= :requestTime` (the moment the report was requested, captured once per call) so
  the window is explicitly bounded at "up to now."
- **Scope of this change — read-only:** nothing sets `done_daily_report` or `done_x_reading` to
  `true` yet. Both flags stay `false` indefinitely after this change ships; a later task will
  decide when/how they flip (e.g. auto-mark-on-generate vs. a separate explicit "close shift"
  action, mirroring the `done_export` / `mark-exported` split). Until that lands, both reports
  are effectively cumulative-since-forever for a given cashier — acceptable for now per explicit
  direction to build this "gradually."
- **No backfill on migration:** pre-existing transactions are deliberately left at the column
  default (`false`) — they are **not** back-marked `true` at migration time. Confirmed
  explicitly: any transaction still flagged `false`, no matter how old, must be displayed and
  included in the report, not silently excluded. In practice this means the first report a
  cashier generates after this ships will include their full history of unreported transactions
  (potentially spanning well before the deploy date) — a known, accepted consequence of not
  flipping any flags yet, not a bug to guard against.
- **Session/login boundaries:** deliberately not used to scope the window. Only the done-flags
  matter; logging out and back in mid-shift does not reset or otherwise affect what is included.
- **Period display:** the existing "Business Date" line (`businessDate: string`, formatted
  `MM/DD/YYYY`) is **removed** from both response DTOs and **replaced** with `periodStart` /
  `periodEnd` (ISO 8601 strings, `null` when the cashier has zero unreported transactions) — the
  earliest and latest `so_date` among the included transactions. `reportGeneratedAt` is unchanged.

## Backend (`be/src/`)

### Migration

New migration (timestamp after the latest existing one), e.g.
`sales-orders-done-daily-report-and-x-reading.ts`:

```sql
ALTER TABLE "sales_orders" ADD COLUMN "done_daily_report" boolean NOT NULL DEFAULT false;
ALTER TABLE "sales_orders" ADD COLUMN "done_x_reading" boolean NOT NULL DEFAULT false;
```

`down()` drops both columns (`IF EXISTS`). Regenerate `migrations/index.ts` via
`npm run migration:sync-index` (or equivalent create-migration script) so the SEA build picks it
up.

### Entity

`sales-orders/entities/sales-order.entity.ts` — add, alongside the existing `doneExport`:

```ts
@Column({ name: 'done_daily_report', type: 'boolean', default: false })
doneDailyReport: boolean;

@Column({ name: 'done_x_reading', type: 'boolean', default: false })
doneXReading: boolean;
```

### `services/cashier-daily-report.service.ts`

- `getReport(causer)` captures `const requestTime = new Date();` once at the top.
- All 7 sub-queries (`getSalesTotals`, `getTax`, `getVatExemptSales`, `getQuantitySold`,
  `getSalesByProduct`, `getCashSales`, `getCashLedgerEntries`) replace
  `.andWhere('so.so_date::date = CURRENT_DATE')` with:
  ```ts
  .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
  .andWhere('so.so_date <= :requestTime', { requestTime })
  ```
- `getSalesTotals` additionally selects `MIN(so.so_date) AS "periodStart"` and
  `MAX(so.so_date) AS "periodEnd"` (both nullable when no rows match) for the period range.

### `services/cashier-x-reading-report.service.ts`

Same treatment across all 9 sub-queries, using `so.done_x_reading = :doneXReading` and the same
`requestTime` bound. `getSalesTotals` gets the same `MIN`/`MAX` `so_date` addition.

### DTOs

`dto/cashier-daily-report-response.dto.ts` and `dto/cashier-x-reading-response.dto.ts`:

- Remove `businessDate: string`.
- Add:
  ```ts
  @ApiProperty({ description: 'Earliest unreported transaction in this report, if any (ISO 8601)', nullable: true, example: '2026-07-10T20:15:00.000Z' })
  periodStart: string | null;

  @ApiProperty({ description: 'Latest unreported transaction in this report, if any (ISO 8601)', nullable: true, example: '2026-07-11T03:02:00.000Z' })
  periodEnd: string | null;
  ```

### Mappers

`mapper/cashier-daily-report.mapper.ts` and `mapper/cashier-x-reading-report.mapper.ts`: drop the
`businessDate: dayjs().format(DATE_FORMAT)` line; add
`periodStart: raw.salesTotals?.periodStart ? new Date(raw.salesTotals.periodStart).toISOString() : null`
(and the equivalent for `periodEnd`). Update `cashier-daily-report.mapper.spec.ts` accordingly
(new fixture cases: normal same-day window, cross-midnight window, and the empty/no-transactions
case where both are `null`).

### `reports.interface.ts`

Add `periodStart` / `periodEnd` (raw `string | null`) to `CashierSalesTotalsRawRow`.

## Kiosk (`kiosk/lib/`)

- **Schemas** — `data/backend_api/schemas/cashier_daily_report_dto.dart` and
  `cashier_x_reading_dto.dart`: replace `businessDate: String` with `periodStart: DateTime?` /
  `periodEnd: DateTime?` (nullable, using the existing date/offset mapper). Run
  `dart run build_runner build --delete-conflicting-outputs` after.
- **Entities** — `features/cashier_report/entities/cashier_daily_report.dart` and
  `cashier_x_reading.dart`: same field swap.
- **Mappers** — `features/cashier_report/mappers/cashier_daily_report_mappers.dart` and
  `cashier_x_reading_mappers.dart`: map the new fields through.
- **Preview screens** — `cashier_daily_report_screen.dart` and
  `cashier_report_preview_screen.dart`: replace the `ReportKeyValueRow('Business Date', ...)` row
  with a `Period` row. Format: `MM/dd/yyyy h:mm a - MM/dd/yyyy h:mm a` on both sides (always full
  date+time on both ends, even when same-day, for simplicity/consistency) — e.g.
  `07/10/2026 8:15 PM - 07/11/2026 3:02 AM`. When `periodStart`/`periodEnd` are `null`, show
  `No transactions yet` instead.
- **ESC/POS encoders** — `encode_esc_pos_cashier_daily_report.dart` and
  `encode_esc_pos_cashier_report.dart`: same replacement of the printed `Business Date:` /
  header business-date column with the `Period:` line, same format and null-case text.

## Dev simulation script

New `be/scripts/seed-late-night-shift-transactions.ts`, sibling to the existing
`seed-today-transactions.ts` (same style: raw `DataSource` + raw SQL inserts, deletes its own
prior output before re-seeding, not part of `seed:run` or the seeders index — manual-only, never
touches production). Generates a batch of transactions for a single cashier with `so_date`
spanning a shift that crosses midnight (e.g. from 8 PM "yesterday" through 3 AM "today"), leaving
`done_daily_report` / `done_x_reading` at their default `false`. Used to manually verify, against
a running dev backend, that both reports now include the full cross-midnight window and that the
new `Period` line renders correctly on both the kiosk preview and the printed receipt.

## Edge cases

- Cashier has zero unreported transactions → `periodStart`/`periodEnd` both `null`; all other
  totals default to 0 as today; preview/receipt show `No transactions yet` for the period line.
- `so.so_date <= requestTime` guards against any (currently theoretical) future-dated transaction
  leaking into a report generated before it "happens."
- No migration backfill and no flag-flipping yet (see Decisions) means both reports keep growing
  to include every historical unreported transaction for that cashier until a follow-up task
  wires up marking — confirmed, not a bug.

## Testing

- Backend: extend `cashier-daily-report.mapper.spec.ts` with cross-midnight and empty-window
  cases for the new `periodStart`/`periodEnd` fields; add the equivalent for the X-Reading mapper
  if a spec file doesn't already exist for it.
- Manual: run `seed-late-night-shift-transactions.ts` against a local dev DB, then hit both
  `GET /reports/cashier-daily-report` and `GET /reports/cashier-x-reading` (or view them in the
  kiosk) to confirm the full cross-midnight window is included and the `Period` line is correct.
