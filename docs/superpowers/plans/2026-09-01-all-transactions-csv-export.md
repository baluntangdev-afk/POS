# All-Transactions CSV Export (Download / Email) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Cashier Accounting hub's three cashier-scoped CSV export choices with two actions — **Download file** and **Email** — that export every transaction from every cashier over a user-picked date range.

**Architecture:** The hub app-bar `PopupMenuButton` gets two items. Both open a date-range picker (default: 1st of month → today). *Download* saves an unencrypted CSV to the Android Downloads folder via the existing `MediaStore` path. *Email* opens an add-chip recipient dialog (recipients persisted in `SharedPreferences`), writes the CSV to a temp file, and hands it to the device mail composer via `flutter_email_sender`. A new `ReportCsvBuilder.buildTransactions` reuses the existing transaction/items-sold section writers. No DAO or schema changes — `SalesDao.getTransactionsForExport` already returns all cashiers when `cashierId` is omitted.

**Tech Stack:** Flutter, Hooks Riverpod, drift (unchanged), `shared_preferences` (present), `media_store_plus` (present), `path_provider` (present), `intl` (present), `flutter_email_sender` 10.0.1 (new).

---

## ⚠️ Repo rules for the executing agent

- **This repository prohibits automated git commits.** Do **not** run `git add`, `git commit`, or `git push`. End each task at the verification step. The user commits manually.
- **Do not author new test files.** Per project convention for mobile implementation tasks, verification is `dart analyze` clean (plus a manual smoke check at the end). The existing `test/core/csv/report_csv_builder_test.dart` must still pass unchanged — only *add* to `ReportCsvBuilder`, never modify existing methods.
- Primary working directory: `C:\Users\Jufiel\Documents\POS_ENTERPRISE\POS_KIOSK\mobile`. All paths below are relative to it. Run all commands from there.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `pubspec.yaml` | Add `flutter_email_sender` dependency | Modify |
| `android/app/src/main/AndroidManifest.xml` | Add `mailto` intent to `<queries>` so the composer resolves on Android 11+ | Modify |
| `lib/core/services/report_email_recipients.dart` | Load/save the last-used recipient list in `SharedPreferences` | Create |
| `lib/core/csv/report_csv_builder.dart` | Add `buildTransactions` (header totals + reused transaction & items-sold sections) | Modify (append only) |
| `lib/core/csv/report_csv_exporter.dart` | Add `exportTransactions` (save to Downloads) + `writeTransactionsTempFile` (temp file for email); refactor temp-write out of `_saveAsCsv` | Modify |
| `lib/features/cashier_accounting/shared/report_email_recipients_dialog.dart` | Add-chip email recipient dialog, returns `List<String>?` | Create |
| `lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart` | Rewrite `_ExportPopupButton`: two items, date-range picker, download/email flows | Modify |
| `lib/features/cashier_accounting/shared/export_csv_button.dart` | Reusable per-reading export button + password dialog | Delete |
| `lib/features/cashier_accounting/x_reading/view/x_reading_history_screen.dart` | Remove `ExportCsvButton` action + import | Modify |
| `lib/features/cashier_accounting/z_reading/view/z_reading_history_screen.dart` | Remove `ExportCsvButton` action + import | Modify |
| `lib/features/cashier_accounting/daily_report/view/daily_report_history_screen.dart` | Remove `ExportCsvButton` action + import | Modify |

**Left untouched (dead code, deliberate):** `ReportCsvExporter.exportXReading/exportZReading/exportDailyReport`, `ReportCsvBuilder.buildXReading/buildZReading/buildDailyReport`, `test/core/csv/report_csv_builder_test.dart`, `AppEnv.csvExportPassword` / `CsvExportKeyScreen`, `reports_screen.dart`'s summary CSV export.

---

## Task 1: Add `flutter_email_sender` dependency + AndroidManifest mailto query

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, in the `dependencies:` block, add the line alphabetically near the other `flutter_*` entries (it sits right after `flutter_hooks` / before `flutter_secure_storage` depending on current order — exact position does not matter, keep it inside `dependencies:`):

```yaml
  flutter_email_sender: ^10.0.1
```

- [ ] **Step 2: Add the mailto intent to the existing `<queries>` block**

In `android/app/src/main/AndroidManifest.xml`, the file already ends with:

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <package android:name="net.nyx.printerservice"/>
    </queries>
```

Change it to add a second `<intent>` for `mailto`:

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO"/>
            <data android:scheme="mailto"/>
        </intent>
        <package android:name="net.nyx.printerservice"/>
    </queries>
```

- [ ] **Step 3: Fetch packages**

Run: `flutter pub get`
Expected: completes with `Got dependencies!` (or `Changed N dependencies!`); no version-solving errors. `flutter_email_sender 10.0.1` appears in `pubspec.lock`.

If pub reports a version-solve conflict against the project's Flutter/Dart SDK, retry with the newest version that resolves (e.g. `^9.0.0`, then `^6.0.3`) — the API used here (`Email(recipients:, subject:, body:, attachmentPaths:, isHTML:)` + `FlutterEmailSender.send`) is unchanged since 5.x. If you fall back below 10.0.0, in Task 6 `runEmail` catch `PlatformException` (import `package:flutter/services.dart`) instead of `FlutterEmailSenderNotAvailableException`.

- [ ] **Step 4: Verify analyzer is still clean**

Run: `dart analyze`
Expected: `No issues found!` (the new package is not imported yet — this just confirms nothing broke).

---

## Task 2: Recipient persistence helper

**Files:**
- Create: `lib/core/services/report_email_recipients.dart`

- [ ] **Step 1: Create the helper**

Create `lib/core/services/report_email_recipients.dart` with exactly this content:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last-used list of report-email recipients so the Email dialog
/// can pre-populate it on the next export. Not sensitive → plain
/// SharedPreferences, mirroring `PrintService`'s storage style.
abstract final class ReportEmailRecipients {
  static const _key = 'report_email_recipients';

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<void> save(List<String> recipients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, recipients);
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/core/services/report_email_recipients.dart`
Expected: `No issues found!`

---

## Task 3: `ReportCsvBuilder.buildTransactions`

**Files:**
- Modify: `lib/core/csv/report_csv_builder.dart`

Context: this class is `abstract final` with `static` methods only. `_writeHeader`, `_writeTransactions`, `_writeItemsSold`, `_fmtDateTime`, `_moneyFmt`, `_esc` already exist and are reused as-is. `TransactionExportRow` exposes `.total` (double), `.discount` (double), `.refundedAmount` (double), `.netTotal` (double getter), `.status` (raw string: `completed` / `voided` / `refunded`).

- [ ] **Step 1: Add the method**

In `lib/core/csv/report_csv_builder.dart`, add this method inside the `ReportCsvBuilder` class, immediately **after** the existing `buildDailyReport` method and **before** `_writeHeader`:

```dart
  static String buildTransactions({
    required DateTime from,
    required DateTime to,
    required DateTime generatedAt,
    required List<TransactionExportRow> txns,
    required List<SaleItemExportRow> items,
  }) {
    final buf = StringBuffer();

    int countWhere(String status) =>
        txns.where((t) => t.status == status).length;
    double sum(double Function(TransactionExportRow) f) =>
        txns.fold(0.0, (acc, t) => acc + f(t));

    _writeHeader(buf, {
      'Report Type': 'All Transactions',
      'Period Start': _fmtDateTime(from),
      'Period End': _fmtDateTime(to),
      'Generated At': _fmtDateTime(generatedAt),
      'Total Transactions': '${txns.length}',
      'Completed': '${countWhere('completed')}',
      'Voided': '${countWhere('voided')}',
      'Refunded': '${countWhere('refunded')}',
      'Gross Total': _moneyFmt.format(sum((t) => t.total)),
      'Total Discounts': _moneyFmt.format(sum((t) => t.discount)),
      'Total Refunded': _moneyFmt.format(sum((t) => t.refundedAmount)),
      'Net Total': _moneyFmt.format(sum((t) => t.netTotal)),
    });
    buf.writeln();
    _writeTransactions(buf, txns);
    buf.writeln();
    _writeItemsSold(buf, txns, items);
    return buf.toString();
  }
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/core/csv/report_csv_builder.dart`
Expected: `No issues found!`

- [ ] **Step 3: Verify existing builder tests still pass**

Run: `flutter test test/core/csv/report_csv_builder_test.dart`
Expected: All tests pass (this task only added a method; existing ones are unchanged).

---

## Task 4: Exporter — `exportTransactions` + `writeTransactionsTempFile`

**Files:**
- Modify: `lib/core/csv/report_csv_exporter.dart`

Context: current `_saveAsCsv` writes a temp file then calls `MediaStore().saveFile(...)`. We split the temp-write into `_writeTempCsv` so the email path can reuse it. `getTemporaryDirectory`, `p` (path), `File`, `utf8`, `MediaStore`, `DirType`, `DirName` are already imported.

- [ ] **Step 1: Refactor `_saveAsCsv` to extract the temp-write**

In `lib/core/csv/report_csv_exporter.dart`, replace the existing `_saveAsCsv` method:

```dart
  Future<String> _saveAsCsv(String csvString, String filename) async {
    final bytes = utf8.encode(csvString);

    final tmp = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmp.path, filename));
    await tmpFile.writeAsBytes(bytes, flush: true);

    final mediaStore = MediaStore();
    await mediaStore.saveFile(
      tempFilePath: tmpFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    return filename;
  }
```

with:

```dart
  Future<File> _writeTempCsv(String csvString, String filename) async {
    final bytes = utf8.encode(csvString);
    final tmp = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmp.path, filename));
    await tmpFile.writeAsBytes(bytes, flush: true);
    return tmpFile;
  }

  Future<String> _saveAsCsv(String csvString, String filename) async {
    final tmpFile = await _writeTempCsv(csvString, filename);

    final mediaStore = MediaStore();
    await mediaStore.saveFile(
      tempFilePath: tmpFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    return filename;
  }
```

- [ ] **Step 2: Add the transactions build + public methods**

In the same file, add these methods inside the `ReportCsvExporter` class, immediately **after** `exportDailyReport` and **before** `_saveAsCsv`:

```dart
  Future<String> _buildTransactionsCsv(DateTime from, DateTime to) async {
    final txns = await _salesDao.getTransactionsForExport(from: from, to: to);
    final saleIds = txns.map((t) => t.id).toList();
    final items = await _salesDao.getSaleItemsForExport(saleIds);
    return ReportCsvBuilder.buildTransactions(
      from: from,
      to: to,
      generatedAt: DateTime.now(),
      txns: txns,
      items: items,
    );
  }

  /// Saves an all-cashier transactions CSV for [from]..[to] to Downloads.
  /// Returns the saved filename.
  Future<String> exportTransactions({
    required DateTime from,
    required DateTime to,
  }) async {
    final csv = await _buildTransactionsCsv(from, to);
    return _saveAsCsv(csv, _transactionsFilename(from, to));
  }

  /// Writes the same CSV to a temp file (for emailing as an attachment).
  /// Returns the temp [File].
  Future<File> writeTransactionsTempFile({
    required DateTime from,
    required DateTime to,
  }) async {
    final csv = await _buildTransactionsCsv(from, to);
    return _writeTempCsv(csv, _transactionsFilename(from, to));
  }
```

- [ ] **Step 3: Add the filename helper**

In the same file, add this `static` method immediately **after** the existing `static String _filename(...)` method:

```dart
  static String _transactionsFilename(DateTime from, DateTime to) {
    String d(DateTime x) {
      final l = x.toLocal();
      return '${l.year.toString().padLeft(4, '0')}'
          '${l.month.toString().padLeft(2, '0')}'
          '${l.day.toString().padLeft(2, '0')}';
    }

    return 'transactions_${d(from)}_${d(to)}.csv';
  }
```

- [ ] **Step 4: Verify analyzer**

Run: `dart analyze lib/core/csv/report_csv_exporter.dart`
Expected: `No issues found!` (the existing `exportXReading`/`exportZReading`/`exportDailyReport` stay — they still compile.)

---

## Task 5: Recipient dialog widget

**Files:**
- Create: `lib/features/cashier_accounting/shared/report_email_recipients_dialog.dart`

Context: uses `flutter_hooks` (`useState`, `useTextEditingController`, `useEffect`) like the other dialogs in this codebase (see the now-deleted `export_csv_button.dart` `_PasswordDialog` for the local style). It loads the persisted list on first build and returns the edited list (or `null` if cancelled). Saving to prefs happens in the caller, only on a real send.

- [ ] **Step 1: Create the file**

Create `lib/features/cashier_accounting/shared/report_email_recipients_dialog.dart` with exactly this content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/services/report_email_recipients.dart';

/// Shows the add-chip recipient dialog. Returns the chosen recipient list, or
/// `null` if the user cancelled. The list is guaranteed non-empty on a non-null
/// return. Persisting the list is the caller's job (do it only on a real send).
Future<List<String>?> showReportEmailRecipientsDialog(BuildContext context) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => const _ReportEmailRecipientsDialog(),
  );
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _ReportEmailRecipientsDialog extends HookWidget {
  const _ReportEmailRecipientsDialog();

  @override
  Widget build(BuildContext context) {
    final recipients = useState<List<String>>(const []);
    final controller = useTextEditingController();
    final error = useState<String?>(null);

    useEffect(() {
      ReportEmailRecipients.load().then((saved) {
        recipients.value = saved;
      });
      return null;
    }, const []);

    void addFromField() {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      if (!_emailRegex.hasMatch(value)) {
        error.value = 'Enter a valid email address';
        return;
      }
      if (recipients.value.contains(value)) {
        error.value = 'Already added';
        return;
      }
      recipients.value = [...recipients.value, value];
      controller.clear();
      error.value = null;
    }

    void remove(String email) {
      recipients.value =
          recipients.value.where((e) => e != email).toList(growable: false);
    }

    return AlertDialog(
      title: const Text('Email transactions CSV'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipients.value.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final email in recipients.value)
                    InputChip(
                      label: Text(email),
                      onDeleted: () => remove(email),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => addFromField(),
              decoration: InputDecoration(
                labelText: 'Add recipient',
                hintText: 'name@example.com',
                errorText: error.value,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addFromField,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: recipients.value.isEmpty
              ? null
              : () => Navigator.of(context).pop(recipients.value),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/features/cashier_accounting/shared/report_email_recipients_dialog.dart`
Expected: `No issues found!`

---

## Task 6: Rewrite `_ExportPopupButton` in the hub screen

**Files:**
- Modify: `lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart`

Context: the current `_ExportPopupButton` (lines ~98–179) watches `xReadingProvider` / `dailyReportProvider` / `zReadingProvider` and reads `authNotifierProvider`. All of that goes away. Keep the `isExporting` spinner behaviour. `CashierAccountingHubScreen`'s `actions: const [_ExportPopupButton()]` stays. `AppColors.primary` etc. are already imported.

- [ ] **Step 1: Update imports**

At the top of the file, the current import block is:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/csv/report_csv_exporter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../daily_report/state/daily_report_notifier.dart';
import '../x_reading/state/x_reading_notifier.dart';
import '../z_reading/state/z_reading_notifier.dart';
```

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/csv/report_csv_exporter.dart';
import '../../../core/services/report_email_recipients.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/report_email_recipients_dialog.dart';
```

(Removed: `auth_providers`, `auth_state`, `daily_report_notifier`, `x_reading_notifier`, `z_reading_notifier`. Added: `flutter_email_sender`, `intl`, `report_email_recipients`, `report_email_recipients_dialog`.)

- [ ] **Step 2: Replace the `_ExportPopupButton` class**

Replace the entire `_ExportPopupButton` class (from `class _ExportPopupButton extends HookConsumerWidget {` through its closing `}`) with:

```dart
class _ExportPopupButton extends HookConsumerWidget {
  const _ExportPopupButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExporting = useState(false);

    Future<DateTimeRange?> pickRange() {
      final now = DateTime.now();
      return showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        ),
        builder: (ctx, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        ),
      );
    }

    Future<void> runDownload(DateTime from, DateTime to) async {
      isExporting.value = true;
      try {
        final exporter = ref.read(reportCsvExporterProvider);
        final filename = await exporter.exportTransactions(from: from, to: to);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Downloads/$filename')),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed — check storage space')),
          );
        }
      } finally {
        isExporting.value = false;
      }
    }

    Future<void> runEmail(DateTime from, DateTime to) async {
      final recipients = await showReportEmailRecipientsDialog(context);
      if (recipients == null || recipients.isEmpty) return;
      await ReportEmailRecipients.save(recipients);

      isExporting.value = true;
      try {
        final exporter = ref.read(reportCsvExporterProvider);
        final file = await exporter.writeTransactionsTempFile(from: from, to: to);
        final dateFmt = DateFormat('yyyy-MM-dd');
        final label = '${dateFmt.format(from)} to ${dateFmt.format(to)}';
        await FlutterEmailSender.send(Email(
          recipients: recipients,
          subject: 'Transactions $label',
          body: 'Attached: all transactions from $label.',
          attachmentPaths: [file.path],
          isHTML: false,
        ));
      } on FlutterEmailSenderNotAvailableException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app found on this device')),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed — check storage space')),
          );
        }
      } finally {
        isExporting.value = false;
      }
    }

    Future<void> onSelected(String value) async {
      final range = await pickRange();
      if (range == null) return;
      final from = DateTime(
          range.start.year, range.start.month, range.start.day);
      final to = DateTime(
          range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);

      switch (value) {
        case 'download':
          await runDownload(from, to);
        case 'email':
          await runEmail(from, to);
      }
    }

    if (isExporting.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Export transactions',
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 12),
              Text('Download file'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email_outlined, size: 20),
              SizedBox(width: 12),
              Text('Email'),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify analyzer for the file**

Run: `dart analyze lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart`
Expected: `No issues found!` — in particular no "unused import" warnings (confirms the removed provider imports are gone) and no undefined-name errors.

---

## Task 7: Remove per-reading `ExportCsvButton` + delete the widget

**Files:**
- Modify: `lib/features/cashier_accounting/x_reading/view/x_reading_history_screen.dart`
- Modify: `lib/features/cashier_accounting/z_reading/view/z_reading_history_screen.dart`
- Modify: `lib/features/cashier_accounting/daily_report/view/daily_report_history_screen.dart`
- Delete: `lib/features/cashier_accounting/shared/export_csv_button.dart`

Context: in all three history screens the app-bar `actions:` list currently starts with an `ExportCsvButton(...)` followed by an `IconButton(...)` reprint button. Only the `ExportCsvButton` entry and its `import '../../shared/export_csv_button.dart';` line are removed. The `_toXReadingData` / `_toZReadingData` / `_toDailyReportData` helpers stay (still used by the reprint `IconButton`).

- [ ] **Step 1: x_reading_history_screen.dart**

Remove line 16: `import '../../shared/export_csv_button.dart';`

Remove this block from the `actions:` list (around lines 134–137):

```dart
          ExportCsvButton(
            periodStart: rowAsync.value?.periodStart,
            onExport: (exp) => exp.exportXReading(_toXReadingData(rowAsync.value!)),
          ),
```

so `actions:` now starts directly with the reprint `IconButton(`.

- [ ] **Step 2: z_reading_history_screen.dart**

Remove line 16: `import '../../shared/export_csv_button.dart';`

Remove this block from the `actions:` list (around lines 137–140):

```dart
          ExportCsvButton(
            periodStart: rowAsync.value?.periodStart,
            onExport: (exp) => exp.exportZReading(_toZReadingData(rowAsync.value!)),
          ),
```

- [ ] **Step 3: daily_report_history_screen.dart**

Remove line 16: `import '../../shared/export_csv_button.dart';`

Remove this block from the `actions:` list (around lines 137–140):

```dart
          ExportCsvButton(
            periodStart: rowAsync.value?.periodStart,
            onExport: (exp) => exp.exportDailyReport(_toDailyReportData(rowAsync.value!)),
          ),
```

- [ ] **Step 4: Delete the widget file**

Run: `git rm lib/features/cashier_accounting/shared/export_csv_button.dart`
(If the executing agent is not permitted to stage: instead `rm lib/features/cashier_accounting/shared/export_csv_button.dart` and let the user stage the deletion. Do **not** commit.)

- [ ] **Step 5: Verify no dangling references**

Run: `grep -rn "export_csv_button\|ExportCsvButton\|showExportPasswordDialog" lib/`
Expected: no matches.

- [ ] **Step 6: Verify analyzer**

Run: `dart analyze`
Expected: `No issues found!`

---

## Task 8: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Codegen (safety — no annotated classes changed, but keep the tree consistent)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes with `Succeeded`. No unexpected file changes in `git status` beyond what earlier tasks touched.

- [ ] **Step 2: Analyzer, whole project**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 3: Run the existing test suite**

Run: `flutter test`
Expected: all tests pass. (No test files were added or modified; `report_csv_builder_test.dart` still green.)

- [ ] **Step 4: Manual smoke check (device or emulator)**

Run: `flutter run -d android`

Verify:
1. Log in as **any** user (not just admin/supervisor). Open **Cashier Accounting** from the dashboard.
2. Tap the app-bar download icon → menu shows exactly **Download file** and **Email**.
3. **Download file** → date-range picker opens with the current month (1st → today) pre-selected → pick a range → snackbar `Saved to Downloads/transactions_<from>_<to>.csv`. Open the file from the device Downloads folder and confirm it contains transactions from **more than one cashier** (if the DB has them), plus the header totals and Items Sold section.
4. **Email** → date-range picker → recipient dialog: type an address + Enter → it becomes a chip → add a second → **Send** → device mail composer opens with both recipients and the `.csv` attached.
5. Re-open **Email** → the two recipients are pre-filled as chips (persistence works).
6. Open an **X-Reading / Z-Reading / Daily Report** history entry → the app bar has only the **reprint** button, no export icon.

- [ ] **Step 5: Report results**

Summarize: analyzer output, test output, and the smoke-check observations. Do **not** commit — hand back to the user.

---

## Addendum (2026-09-01, post-implementation)

Follow-up request: replace the native `showDateRangePicker` in `_ExportPopupButton.pickRange`
with a better-looking alternative.

- Added `calendar_date_picker2: ^3.0.0` (Apache-2.0, resolves on the repo's Dart SDK).
- `pickRange` now calls `showCalendarDatePicker2Dialog` in `CalendarDatePicker2Type.range`
  mode with `CalendarDatePicker2WithActionButtonsConfig`, themed via `AppColors` /
  `AppTextStyles` (teal highlight, translucent-teal range band, `radiusLg` corners,
  teal OK / grey Cancel). Same initial range (1st-of-month → today) and `firstDate`
  `DateTime(2020)` / `lastDate` today. Returns `DateTimeRange?`; a single picked day
  collapses to `end == start`. `onSelected` is unchanged.
- `dart analyze` clean; `flutter pub get` OK.

---

## Self-Review Notes (author)

- **Spec coverage:** hub menu (T6), date-range picker + default month-to-date (T6 `pickRange`), all-cashier export (T4 — `getTransactionsForExport` without `cashierId`), any-user access (unchanged — hub not admin-gated; verified in T8 smoke step 1), add-chip recipient dialog + persistence (T2, T5, T6 `runEmail`), `buildTransactions` CSV shape (T3), `flutter_email_sender` + manifest (T1), removals + file delete (T7), dead code left intact (no task touches it), no new tests (stated up front, verified T3/T8).
- **Sender-address limitation** from the spec is inherent to the composer approach — nothing to implement; the composer's From is the device account.
- **Type consistency:** `exportTransactions({from, to})` / `writeTransactionsTempFile({from, to})` / `buildTransactions({from, to, generatedAt, txns, items})` / `ReportEmailRecipients.load()/save(list)` / `showReportEmailRecipientsDialog(context) → List<String>?` used identically across T3–T6.
- **`intl` import in the hub screen:** `intl` is already a top-level dependency (used across the app), so importing `package:intl/intl.dart` needs no `pubspec` change.
