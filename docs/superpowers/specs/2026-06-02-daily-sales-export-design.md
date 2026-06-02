# Daily Sales XLSX Export — Design Spec

**Date:** 2026-06-02  
**Branch:** feature/catalog_migration  
**Scope:** Flutter kiosk (Windows) — `kiosk/` only

---

## Overview

Automatically generate and save a daily sales report as an XLSX file to the Windows Downloads folder every midnight. A manual export button in the Sales Report screen TopAppBar lets staff export on demand at any time.

---

## Goals

- Export yesterday's full-day data automatically at midnight every day
- Catch missed exports on app restart (e.g. if app was down at midnight)
- Allow manual export of today's data via a button in the TopAppBar
- Save files to `C:\Users\{user}\Downloads\sales_report_YYYY-MM-DD.xlsx`
- Show a snackbar confirmation with the saved file path

---

## Non-Goals

- No email delivery, cloud upload, or remote sync
- No configurable export time (always midnight)
- No support for exporting arbitrary date ranges from this flow (manual button always exports today)
- No Android support (Windows kiosk only)

---

## New Packages

| Package | Version | Purpose |
|---|---|---|
| `excel` | `^4.0.6` | Pure-Dart XLSX builder, no native dependencies |

`path_provider` is not needed — the Windows Downloads path is derived from `Platform.environment['USERPROFILE']`.

---

## Architecture

### New Files

```
kiosk/lib/features/reports/
├── services/
│   ├── report_export_service.dart       # Data fetch + XLSX build + file save
│   └── daily_export_scheduler.dart      # Midnight timer + startup catch-up
└── state/
    └── export_notifier.dart             # isExporting, lastExportPath, exportError
```

### Modified Files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `excel: ^4.0.6` |
| `lib/features/reports/view/sales_report_screen.dart` | Add export button to `TopAppBar` trailing slot |
| `lib/app.dart` | Read `dailyExportSchedulerProvider` in `_WindowCloseGuardState.initState()` to activate the scheduler on app start |

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
1. Compute `startDate = DateTime(date.year, date.month, date.day)` and `endDate = startDate + 23:59:59`
2. Fetch all 6 data sources in parallel via `Future.wait`:
   - `getSalesReports` → `SalesSummary`
   - `getSalesReportType(type: hourly)` → `List<SalesReportType>`
   - `getSalesByProducts` → `List<SalesDataItem>`
   - `getSalesByProductGroups` → `List<SalesDataItem>`
   - `getSalesByPayment` → `List<SalesDataItem>`
   - `getSalesByUser` → `List<SalesDataItem>`
3. Build XLSX with 6 sheets (see Sheet Specs below)
4. Resolve save path: `${Platform.environment['USERPROFILE']}\Downloads\sales_report_YYYY-MM-DD.xlsx`
5. Write bytes to file, return the resolved path

---

### `DailyExportScheduler`

```dart
final dailyExportSchedulerProvider = NotifierProvider<DailyExportScheduler, void>(
  DailyExportScheduler.new,
);
```

**On `build()`:**
1. Read `lastExportDate` string from SharedPreferences (key: `daily_export_last_date`, format `yyyy-MM-dd`)
2. If `lastExportDate` is null or before today → call `_runExport(yesterday)` immediately (catch-up)
3. Compute `durationUntilMidnight` and start a `Timer` for it
4. On timer fire: call `_runExport(today — which is now yesterday)`, persist new date, restart timer for next midnight

**`_runExport(DateTime date)`:**
- Calls `exportNotifierProvider.notifier.export(date)`
- Persists `lastExportDate = yyyy-MM-dd` to SharedPreferences on success
- Silently logs on failure (does not crash the scheduler)

**Provider type:** `NotifierProvider` (not autoDispose) so it stays alive for the entire app session.

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
3. On success: set `isExporting = false`, `lastExportPath = path`
4. On error: set `isExporting = false`, `exportError = message`

---

### Export Button (UI)

Location: `TopAppBar` `trailing` slot in `SalesReportScreen`.

```
[Download icon button]  ← white icon, 44×44 min touch target
```

- Disabled (spinner icon) while `exportState.isExporting == true`
- On tap: calls `exportNotifier.export(DateTime.now())`
- After export completes: `ScaffoldMessenger.of(context).showSnackBar(...)` with path or error message
- Listens via `ref.listen(exportNotifierProvider, ...)` to react to state changes

---

## XLSX Sheet Specifications

All monetary values formatted as `P#,##0.00`. Percentage columns are `0.0%`. Headers row is bold. Total/summary rows are bold. Brand primary color (`#1B7A8C`) used for header cell backgrounds with white text.

### Sheet 1 — Daily Summary

| Row | Label | Value |
|---|---|---|
| 1 | Report Date | Jun 2, 2026 |
| 2 | Generated At | Jun 2, 2026 11:59 PM |
| 3 | Gross Sales | P 13,000.00 |
| 4 | Total Discounts | P 655.00 |
| 5 | Net Sales | P 12,345.00 |
| 6 | Total Refunds | P 200.00 |
| 7 | Voided Transactions | 3 |
| 8 | Voided Amount | P 450.00 |
| 9 | Total Transactions | 87 |
| 10 | Total Items Sold | 210 |

Two columns: Label (col A) and Value (col B).

### Sheet 2 — Hourly Breakdown

Columns: **Hour | Gross Sales | Discounts | Transactions | Items**

Source: `SalesReportType` list filtered to the export day, period = `hourly`.  
Last row: bold TOTAL row summing numeric columns.

### Sheet 3 — Sales by Product

Columns: **Product | Total Sales | % Share**

Source: `groupedSalesData[SalesDataItemType.product]`.  
% Share = item.totalSales / sum(all items).  
Sorted descending by Total Sales.

### Sheet 4 — Sales by Product Group

Columns: **Product Group | Total Sales | % Share**

Source: `groupedSalesData[SalesDataItemType.productGroup]`.  
Same sort and % logic as Sheet 3.

### Sheet 5 — Sales by Payment Method

Columns: **Payment Method | Total Sales | % Share**

Source: `groupedSalesData[SalesDataItemType.payment]`.

### Sheet 6 — Sales by Cashier

Columns: **Cashier | Total Sales | % Share**

Source: `groupedSalesData[SalesDataItemType.user]`.

---

## Data Flow

```
DailyExportScheduler (midnight / startup)
        │
        ▼
ExportNotifier.export(date)
        │
        ▼
ReportExportService.exportDay(date)
        │
        ├──► ReportsRepository.getSalesReports(start, end)
        ├──► ReportsRepository.getSalesReportType(hourly, start, end)
        ├──► ReportsRepository.getSalesByProducts(start, end)
        ├──► ReportsRepository.getSalesByProductGroups(start, end)
        ├──► ReportsRepository.getSalesByPayment(start, end)
        └──► ReportsRepository.getSalesByUser(start, end)
                    │ (all parallel via Future.wait)
                    ▼
              Build Excel workbook
                    │
                    ▼
        Downloads/sales_report_YYYY-MM-DD.xlsx
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| API call fails during auto-export | Log error silently; do NOT persist `lastExportDate` so it retries on next startup |
| API call fails during manual export | Show error snackbar: "Export failed: {message}" |
| Downloads folder not found | Fall back to app documents directory; log warning |
| File already exists for that date | Overwrite silently |
| App closed before midnight timer fires | Startup catch-up handles it on next launch |

---

## Scheduler Initialization

The scheduler must be initialized early, before the user navigates to the reports screen. It is activated by reading `dailyExportSchedulerProvider` inside `_WindowCloseGuardState.initState()` in `app.dart`. Since `_WindowCloseGuard` wraps the entire app and never disposes until exit, the provider stays alive for the full session.

```dart
// In _WindowCloseGuardState.initState():
final container = widget.container;
container.read(dailyExportSchedulerProvider); // activates scheduler
```

---

## File Naming

`sales_report_YYYY-MM-DD.xlsx` where the date is the day being exported (yesterday for auto-export, today for manual export).

Example: `sales_report_2026-06-02.xlsx`

---

## SharedPreferences Key

| Key | Type | Value |
|---|---|---|
| `daily_export_last_date` | String | `yyyy-MM-dd` of last successfully exported day |
