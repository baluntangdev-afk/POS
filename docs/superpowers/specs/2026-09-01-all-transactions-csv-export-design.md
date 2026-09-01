# All-Transactions CSV Export (Download / Email) — Design Spec

**Date:** 2026-09-01
**Feature branch:** feature/socket (mobile only)
**Scope:** Mobile app — Cashier Accounting hub export menu

---

## Overview

The Cashier Accounting hub app-bar export button currently opens a popup menu with
three cashier-scoped choices — **Export X-Reading CSV**, **Export Daily Report CSV**,
**Export Z-Reading CSV** — each of which exports only the *current user's* sales for
that reading's period.

This is replaced with a two-item menu:

- **Download file**
- **Email**

Both actions export **every transaction from every cashier** over a user-picked date
range, as a plain (unencrypted) UTF-8 CSV. Any authenticated user can use it — the
Cashier Accounting hub is already reachable by all roles, and no password gate is
applied.

The per-reading `Export CSV` buttons on the X-Reading / Z-Reading / Daily Report
reprint screens are removed.

---

## UI Changes

### 1. Hub export menu — `cashier_accounting_hub_screen.dart` → `_ExportPopupButton`

- Menu items become exactly two: `Download file` (icon `Icons.download`) and
  `Email` (icon `Icons.email_outlined`).
- The widget no longer watches `xReadingProvider` / `dailyReportProvider` /
  `zReadingProvider`, and no longer reads `authNotifierProvider` for a `cashierId`.
  Both items are always enabled.
- The in-progress spinner behaviour (icon swapped for a `CircularProgressIndicator`
  while `isExporting`) is kept.

**Flow for both actions:**

1. Show a date-range picker — `showCalendarDatePicker2Dialog` from the
   `calendar_date_picker2` package (range mode, OK/Cancel action buttons),
   themed with `AppColors` / `AppTextStyles` (teal `selectedDayHighlightColor`,
   translucent-teal `selectedRangeHighlightColor`, rounded `AppSpacing.radiusLg`
   corners).
   - `firstDate: DateTime(2020)`, `lastDate: today`.
   - **Initial range: first day of the current month → today.**
   - If the user cancels, abort silently. If only one day is picked, treat it as
     a single-day range (`end = start`).
2. Convert the picked range to `from = startOfDay(picked.start)` and
   `to = endOfDay(picked.end)` in local time (`to` = 23:59:59.999).
3. **Download file:** call `ReportCsvExporter.exportTransactions(from:, to:)`, then
   snackbar `Saved to Downloads/<filename>`.
4. **Email:** show the recipient dialog (below). On confirm, call
   `ReportCsvExporter.writeTransactionsTempFile(from:, to:)` then hand the path to
   `FlutterEmailSender`.

Errors → snackbar `Export failed — check storage space` (matches existing copy).

### 2. Recipient dialog (Email only)

A small dialog with an **add-chip email list**:

- A `TextField` — the user types an address and presses enter / done; on submit the
  text is validated with a simple email regex and, if valid, added as a removable
  `InputChip`. Invalid input shows an inline error and is not added.
- Chips render above/below the field; tapping a chip's `x` removes it.
- Pre-populated from the last-used recipient list (see persistence). Empty on first
  ever use.
- `Cancel` / `Send` actions. `Send` is disabled while the chip list is empty.
- On `Send`: persist the current list as the new last-used list, close the dialog,
  and proceed with the email.

### 3. Removals

- Delete `lib/features/cashier_accounting/shared/export_csv_button.dart`.
- Remove the `ExportCsvButton` app-bar action (and its now-unused import) from:
  - `x_reading/view/x_reading_history_screen.dart`
  - `z_reading/view/z_reading_history_screen.dart`
  - `daily_report/view/daily_report_history_screen.dart`

---

## Recipient Persistence

Follows the `PrintService` pattern — direct `SharedPreferences.getInstance()`, no
provider.

New helper `lib/core/services/report_email_recipients.dart`:

```dart
abstract final class ReportEmailRecipients {
  static Future<List<String>> load();          // pref key 'report_email_recipients'
  static Future<void> save(List<String> list); // stored as StringList
}
```

Not sensitive → `SharedPreferences` (not secure storage).

---

## CSV Structure

New method `ReportCsvBuilder.buildTransactions`:

```dart
static String buildTransactions({
  required DateTime from,
  required DateTime to,
  required DateTime generatedAt,
  required List<TransactionExportRow> txns,
  required List<SaleItemExportRow> items,
})
```

Same formatting rules as the existing builders (2dp money, `yyyy-MM-dd` dates,
`HH:mm` times, local timezone, `_esc` quoting).

**Section 1 — Header** (`Field,Value` rows, via existing `_writeHeader`):

| Field | Value |
|---|---|
| Report Type | All Transactions |
| Period Start | `<from>` |
| Period End | `<to>` |
| Generated At | `<generatedAt>` |
| Total Transactions | count of `txns` |
| Completed | count where status == completed |
| Voided | count where status == voided |
| Refunded | count where status == refunded |
| Gross Total | sum of `t.total` |
| Total Discounts | sum of `t.discount` |
| Total Refunded | sum of `t.refundedAmount` |
| Net Total | sum of `t.netTotal` |

**Section 2 — Transaction Detail:** reuse `_writeTransactions(buf, txns)` verbatim
(columns: `Invoice No, Date, Time, Cashier, Type, Status, Payment Method,
Gross Total, Discount, Refunded, Net Total, Void Reason`, ordered by time asc).

**Section 3 — Items Sold:** reuse `_writeItemsSold(buf, txns, items)` verbatim.

Sections separated by a blank line (`buf.writeln()`), same as the other builders.

---

## Data Layer

**No changes.** `SalesDao.getTransactionsForExport({from, to})` already returns all
cashiers when `cashierId` is omitted; `getSaleItemsForExport(saleIds)` is reused
as-is.

---

## Exporter Additions — `report_csv_exporter.dart`

Two new methods on `ReportCsvExporter` (the existing X/Z/Daily methods stay,
untouched, even though they become unreferenced):

```dart
Future<String> exportTransactions({required DateTime from, required DateTime to});
// fetch txns + items, build CSV, save via existing _saveAsCsv(), return filename

Future<File> writeTransactionsTempFile({required DateTime from, required DateTime to});
// fetch txns + items, build CSV, write to getTemporaryDirectory()/<filename>, return the File
```

Refactor: extract the "fetch + build CSV string" part into a private
`Future<String> _buildTransactionsCsv(DateTime from, DateTime to)` used by both.
`_saveAsCsv` already writes a temp file then hands it to `MediaStore`; factor its
temp-write step so `writeTransactionsTempFile` can share it.

**Filename:** `transactions_<YYYYMMDD-from>_<YYYYMMDD-to>.csv`
(e.g. `transactions_20260901_20260930.csv`). Reuse the date portion of the existing
`_filename` helper logic.

---

## Email Delivery

**Package:** `flutter_email_sender` (latest stable — pin the exact version during
plan/implementation). Android supported; no `ios/` folder in this project.

```dart
await FlutterEmailSender.send(Email(
  recipients: recipients,
  subject: 'Transactions $fromDate to $toDate',
  body: 'Attached: all transactions from $fromDate to $toDate '
        '($txnCount transactions).',
  attachmentPaths: [tempFile.path],
  isHTML: false,
));
```

This opens the **device's mail composer** with the recipients and CSV pre-filled;
the user taps Send in their mail app.

> **Known limitation (accepted):** the "from" address is whatever account the
> device's mail app uses — the app cannot force `dposoftware130@gmail.com` as the
> sender without embedding Gmail SMTP credentials in the APK, which was rejected.

**Error handling:**

| Scenario | Behaviour |
|---|---|
| No mail app installed / `PlatformException` | snackbar `No email app found on this device` |
| User backs out of the composer | no-op (no snackbar) |
| CSV write fails before compose | snackbar `Export failed — check storage space` |

### AndroidManifest

Add to the existing `<queries>` block in
`android/app/src/main/AndroidManifest.xml` so Android 11+ lets the intent resolve:

```xml
<intent>
    <action android:name="android.intent.action.SENDTO" />
    <data android:scheme="mailto" />
</intent>
```

---

## Packages

```yaml
dependencies:
  flutter_email_sender: <latest stable compatible with the repo's Dart SDK>
  calendar_date_picker2: ^3.0.0   # themeable range-picker dialog
```

`shared_preferences`, `path_provider`, `media_store_plus`, `intl` are already
present.

---

## Out of Scope / Notes

- **Dead code left in place:** `ReportCsvExporter.exportXReading/exportZReading/
  exportDailyReport`, `ReportCsvBuilder.buildXReading/buildZReading/
  buildDailyReport`, and their coverage in `test/core/csv/report_csv_builder_test.dart`
  are kept as-is.
- **`CSV_EXPORT_PASSWORD`** and the `showExportPasswordDialog` gate are no longer
  reachable from any export path after `export_csv_button.dart` is deleted. The env
  var, `AppEnv.csvExportPassword`, and the `CsvExportKeyScreen` settings tile are
  left untouched (removing them is a separate cleanup).
- The **Reports screen** (`reports_screen.dart`) keeps its own aggregate
  sales-summary CSV export via `ReportExportService` — that's a summary report, not
  transaction-level, and is unchanged.
- **No SMTP / direct send**, no in-app decryption, no scheduled/auto export.

---

## Testing

Per project convention for mobile implementation tasks: no new test files.
Verification is `dart analyze` clean + `dart run build_runner build` if any
annotated class changes (none expected here — no new `@MappableClass` / router /
env-generated code beyond a plain `pubspec` add).
