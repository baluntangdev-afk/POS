# Daily Sales XLSX Export — Design Spec

**Date:** 2026-06-02  
**Branch:** feature/catalog_migration  
**Scope:** Full-stack — NestJS backend (`be/`) + Flutter kiosk (`kiosk/`)

---

## Overview

Track which sales transactions have been included in an exported report using a `done_export` flag on each transaction. When a cashier or admin navigates to the Reports screen, the app checks whether yesterday has any unexported transactions. If it does, a blocking modal forces them to export before accessing reports. The export fetches only unexported transactions, builds a 6-sheet XLSX, saves it to the Windows Downloads folder, then marks those transactions as exported on the backend.

A daily midnight auto-export also runs silently in the background using the same flow.

---

## Goals

- Add `done_export` tracking to every sales transaction
- Block access to the Reports screen until yesterday's transactions are exported
- Export only `done_export == false` transactions for a given day
- Mark transactions as `done_export = true` after a successful file save
- Auto-export at midnight every day (silent, no blocking UI)
- Allow manual export of today's data via a button in the TopAppBar

---

## Non-Goals

- No email delivery, cloud upload, or remote sync
- No configurable export time (always midnight for auto-export)
- `done_export` is on transactions only — not on refunds or void records
- No support for re-exporting already-exported transactions
- No Android support (Windows kiosk only)

---

## New Package

| Package | Version | Purpose |
|---|---|---|
| `excel` | `^4.0.6` | Pure-Dart XLSX builder, no native dependencies |

---

## Backend Changes (`be/`)

### 1. Database Migration

Add `done_export BOOLEAN DEFAULT FALSE` to the `sales_orders` table.

```sql
ALTER TABLE sales_orders ADD COLUMN done_export BOOLEAN NOT NULL DEFAULT FALSE;
```

Migration file: `src/database/migrations/<timestamp>-add-done-export-to-sales-orders.ts`

### 2. Entity Update

`SalesOrder` entity gets a new column:

```typescript
@Column({ name: 'done_export', type: 'boolean', default: false })
doneExport: boolean;
```

### 3. New Endpoints

#### `GET /api/v1/reports/exportable`

Query params: `date: string` (format `YYYY-MM-DD`)

Returns all aggregated report data for transactions on `date` where `done_export = false`, structured identically to the existing report endpoints so the Flutter client reuses existing DTOs.

**Response shape:**

```typescript
{
  date: string,                  // YYYY-MM-DD
  count: number,                 // total unexported transaction count
  summary: SalesReportRawRow,    // totals (sales, discounts, refunds, voided, items)
  hourlyBreakdown: SalesReportTypeDto[],
  byProduct: SalesDataItemDto[],
  byProductGroup: SalesDataItemDto[],
  byPayment: SalesDataItemDto[],
  byCashier: SalesDataItemDto[],
}
```

If `count == 0`, all arrays are empty and `summary` is zero-filled. The client uses `count` to decide whether to show the blocking modal.

#### `PATCH /api/v1/reports/mark-exported`

Body: `{ date: string }` (format `YYYY-MM-DD`)

Sets `done_export = true` for all `sales_orders` on `date` where `done_export = false`.

Returns: `{ updatedCount: number }`

### 4. Module wiring

Both endpoints live in the existing `ReportsModule` / `ReportsController`. Two new service methods are added to the existing `ReportsService` (or a dedicated `ExportableReportService` if the file grows too large).

---

## Flutter Changes (`kiosk/`)

### New Files

```
kiosk/lib/features/reports/
├── services/
│   ├── report_export_service.dart       # Data fetch + XLSX build + file save + mark-exported call
│   └── daily_export_scheduler.dart      # Midnight timer + startup catch-up
├── state/
│   └── export_notifier.dart             # isExporting, lastExportPath, exportError
└── view/
    └── unexported_export_dialog.dart    # Blocking modal shown before Reports screen
```

### Modified Files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `excel: ^4.0.6` |
| `lib/data/backend_api/sources/reports_api.dart` | Add `getExportable(date)` and `markExported(date)` |
| `lib/features/reports/repositories/reports_repository.dart` | Add corresponding abstract + impl methods |
| `lib/features/reports/view/sales_report_screen.dart` | Add export button to `TopAppBar` trailing slot; trigger unexported check on init |
| `lib/app.dart` | Read `dailyExportSchedulerProvider` in `_WindowCloseGuardState.initState()` |

---

## Component Details

### `ReportExportService`

```dart
class ReportExportService {
  Future<String> exportDay(DateTime date) async { ... }
}
final reportExportServiceProvider = Provider<ReportExportService>(...);
```

**`exportDay(DateTime date)`:**
1. Call `repository.getExportable(date)` — gets aggregated data for `done_export == false` transactions
2. Build 6-sheet XLSX from the response (see Sheet Specs)
3. Resolve save path: `${Platform.environment['USERPROFILE']}\Downloads\sales_report_YYYY-MM-DD.xlsx`
4. Write file bytes to disk
5. Call `repository.markExported(date)` to flip `done_export = true`
6. Return the resolved file path

Step 5 only runs after step 4 succeeds. If the file write fails, `markExported` is never called.

---

### `DailyExportScheduler`

```dart
final dailyExportSchedulerProvider = NotifierProvider<DailyExportScheduler, void>(
  DailyExportScheduler.new,
);
```

**On `build()`:**
1. Read `lastExportDate` from SharedPreferences (key: `daily_export_last_date`, format `yyyy-MM-dd`)
2. If `lastExportDate` is null or before today → call `_runExport(yesterday)` immediately (catch-up)
3. Compute `durationUntilMidnight` and start a `Timer`
4. On timer fire: call `_runExport(today — now yesterday)`, persist new date, restart timer

**`_runExport(DateTime date)`:**
- Calls `exportNotifier.export(date)`
- Persists `lastExportDate` to SharedPreferences **only on success**
- Silently logs on failure — does not crash the scheduler; allows the blocking modal to surface the issue when the user navigates to Reports

Provider is **not autoDispose** — stays alive for the full app session.

---

### `ExportNotifier`

```dart
@immutable
class ExportState {
  final bool isExporting;
  final String? lastExportPath;
  final String? exportError;
}
final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(...);
```

**`export(DateTime date)`:**
1. Set `isExporting = true`, clear previous error
2. Call `reportExportService.exportDay(date)`
3. On success: `isExporting = false`, `lastExportPath = path`
4. On failure: `isExporting = false`, `exportError = message`

---

### `UnexportedExportDialog` (blocking modal)

Shown when the user navigates to the Reports screen and yesterday has `count > 0` unexported transactions.

**Trigger:** `SalesReportScreen.initState()` calls `repository.getExportable(yesterday)`. If `count > 0`, immediately show the dialog via `showDialog(barrierDismissible: false)`.

**Modal content:**
```
┌────────────────────────────────────────────────┐
│  Unexported Transactions                        │
│                                                 │
│  Yesterday (Jun 1) has 45 transactions that     │
│  have not been exported yet.                    │
│                                                 │
│  You must export yesterday's report before      │
│  accessing the Reports screen.                  │
│                                                 │
│  [  Export Now  ]   ← primary filled button     │
└────────────────────────────────────────────────┘
```

- `barrierDismissible: false` — cannot be dismissed without exporting
- No "Skip" or "Cancel" button
- "Export Now" triggers `exportNotifier.export(yesterday)`
- While exporting: button shows a spinner, label changes to "Exporting…"
- On success: dialog closes automatically, user proceeds to Reports screen
- On failure: show error text inside the dialog with a "Retry" option — do not close

---

### Export Button (TopAppBar)

Location: `TopAppBar` `trailing` slot in `SalesReportScreen`.

- White download icon button, 44×44 minimum touch target
- Disabled (spinner) while `exportState.isExporting == true`
- On tap: calls `exportNotifier.export(DateTime.now())` for today's data
- Listens via `ref.listen(exportNotifierProvider, ...)` to react to state changes
- On success: `ScaffoldMessenger.showSnackBar` — `"Report saved to Downloads/sales_report_2026-06-02.xlsx"`
- On failure: snackbar — `"Export failed: {message}"`

---

## XLSX Sheet Specifications

All monetary values: `P#,##0.00`. Percentage columns: `0.0%`. Header row: bold, brand primary `#1B7A8C` background, white text. Total rows: bold.

### Sheet 1 — Daily Summary

Two-column key/value layout:

| Label | Value |
|---|---|
| Report Date | Jun 2, 2026 |
| Generated At | Jun 2, 2026 11:59 PM |
| Gross Sales | P 13,000.00 |
| Total Discounts | P 655.00 |
| Net Sales | P 12,345.00 |
| Total Refunds | P 200.00 |
| Voided Transactions | 3 |
| Voided Amount | P 450.00 |
| Total Transactions | 87 |
| Total Items Sold | 210 |

### Sheet 2 — Hourly Breakdown

Columns: **Hour · Gross Sales · Discounts · Transactions · Items**  
Source: `hourlyBreakdown` from the exportable endpoint.  
Last row: bold TOTAL row.

### Sheet 3 — Sales by Product

Columns: **Product · Total Sales · % Share**  
Source: `byProduct`. Sorted descending by Total Sales.

### Sheet 4 — Sales by Product Group

Columns: **Product Group · Total Sales · % Share**  
Source: `byProductGroup`. Same sort logic.

### Sheet 5 — Sales by Payment Method

Columns: **Payment Method · Total Sales · % Share**  
Source: `byPayment`.

### Sheet 6 — Sales by Cashier

Columns: **Cashier · Total Sales · % Share**  
Source: `byCashier`.

---

## Full Data Flow

```
Navigate to Reports screen
        │
        ▼
repository.getExportable(yesterday)
        │
   count > 0?
   ├── NO  → show Reports screen normally
   └── YES → show UnexportedExportDialog (blocking)
                    │
             user taps "Export Now"
                    │
                    ▼
         ExportNotifier.export(yesterday)
                    │
                    ▼
         ReportExportService.exportDay(date)
                    │
                    ├── build XLSX from response data
                    ├── save to Downloads/sales_report_YYYY-MM-DD.xlsx
                    └── repository.markExported(date)  ← only on success
                    │
                    ▼
            dialog closes → Reports screen
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| `getExportable` fails on Reports navigate | Show error snackbar; do not block screen (allow access) |
| File write fails | `markExported` is NOT called; dialog stays open with retry button |
| `markExported` fails after successful file write | Log error; show warning snackbar; file is saved but transactions remain unexported — they will appear again in next check |
| Auto-export fails at midnight | Do not persist `lastExportDate`; blocking modal surfaces the issue next morning |
| `count == 0` on `getExportable` | Skip dialog, proceed normally |
| Downloads folder not found | Fall back to app documents directory; log warning |
| File already exists for that date | Overwrite silently |

---

## SharedPreferences Key

| Key | Type | Purpose |
|---|---|---|
| `daily_export_last_date` | `String` (`yyyy-MM-dd`) | Tracks last successful auto-export date for catch-up logic |

---

## Scheduler Initialization

`dailyExportSchedulerProvider` is read inside `_WindowCloseGuardState.initState()` in `app.dart` via `widget.container.read(dailyExportSchedulerProvider)`. This activates the scheduler for the full app session since `_WindowCloseGuard` never disposes until exit.
