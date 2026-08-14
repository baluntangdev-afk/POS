# Export all data (mobile POS backup)

## Problem

The mobile app (`mobile/`, "Offline mobile POS application") stores everything locally in a
Drift/SQLite database (`lib/core/database/app_database.dart`) — users, products, categories,
sales, payments, refunds, X-readings, Z-readings, daily (cashier) reports, store info. There is
currently no way to get a copy of that data off the device. `ReportExportService`
(`lib/core/services/report_export_service.dart`) can export a single computed sales report to
CSV, and `Import CSV` (Settings) can bulk-import a handful of entities, but neither gives a full
snapshot of the device's data for backup purposes.

This adds an "Export Data" action that dumps every table in the local database to CSV and hands
the files to the OS share sheet, so an admin can pull a backup off the device at any time (e.g.
before a reinstall, device swap, or just for periodic safekeeping).

## Scope

- One-tap export of **all 18 database tables** — not just the entities the requester named
  (users, transactions, products, categories, X/Z readings, cashier report) — so the backup is
  guaranteed complete and stays complete as the schema grows: `users`, `product_groups`
  (categories), `products`, `product_variants`, `modifier_groups`, `modifier_options`,
  `product_modifier_groups`, `sales`, `sale_items`, `sale_item_modifiers`, `payments`,
  `payment_methods`, `refunds`, `refund_items`, `store_info`, `x_readings`, `z_readings`,
  `daily_reports`.
- Each table becomes one CSV file (header row = column names, one row per record). Files are
  named after the table's actual DB name (`product_groups.csv`, not `categories.csv`) — this is
  the trade-off of the generic approach below and is called out explicitly.
- Full history, no date filtering — this is a backup, not a report.
- All columns included as-is, including `users.pin_hash` (bcrypt hash, not a raw PIN) — an
  explicit choice for backup fidelity.
- Delivery is through the existing OS share sheet (`share_plus`), the same mechanism
  `ReportExportService` already uses — the admin picks where the files go (email, Drive, USB
  transfer app, etc.). Files are **not** zipped; they're shared as a set of individual CSVs.
- Out of scope (deferred to a future spec if ever needed): a "restore from backup" import flow,
  zipping/bundling the CSVs into one archive, and any redaction/anonymization of sensitive
  columns.

## Design

### `DataExportService` — generic table dump

New file `lib/core/services/data_export_service.dart`, structured like the existing
`ReportExportService`:

```dart
abstract final class DataExportService {
  static Future<List<File>> exportAllToCsv(AppDatabase db) async {
    final dir = await getTemporaryDirectory();
    final files = <File>[];
    for (final table in db.allTables) {
      final rows = await db
          .customSelect('SELECT * FROM ${table.actualTableName}')
          .get();
      final columns = rows.isNotEmpty
          ? rows.first.data.keys.toList()
          : await _columnNamesFor(db, table.actualTableName);
      final csvRows = <List<Object?>>[
        columns,
        for (final row in rows) [for (final c in columns) row.data[c]],
      ];
      final csv = const ListToCsvConverter().convert(csvRows);
      final file = File('${dir.path}/${table.actualTableName}.csv');
      await file.writeAsString(csv);
      files.add(file);
    }
    return files;
  }

  static Future<void> shareCsvs(List<File> files, {String? storeName}) async {
    final label = storeName != null ? 'POS data export – $storeName' : 'POS data export';
    await Share.shareXFiles(
      [for (final f in files) XFile(f.path)],
      text: '$label – ${DateTime.now().toIso8601String().split('T').first}',
    );
  }
}
```

Notes:
- `db.allTables` is Drift's built-in `Iterable<TableInfo>` of every table registered on
  `AppDatabase` — this is what makes the exporter generic. No per-table code, and any table
  added to `AppDatabase` later (a new migration + entry in the `tables:` list) is automatically
  included in the next export with zero changes here.
- Column names come from the query result when rows exist; `_columnNamesFor` falls back to
  `PRAGMA table_info(<table>)` (same technique already used as `_hasColumn` in
  `app_database.dart`) so a table with zero rows still produces a CSV with just a header row,
  keeping the exported file set consistent across stores regardless of how much data they have.
- Reuses `csv`, `path_provider`, `share_plus` — all already dependencies. No new packages.

### Settings UI

`lib/features/settings/view/settings_screen.dart` — add a new tile to the existing admin-only
`Data` section (same gate as `Import CSV`, i.e. `if (isAdmin)`):

```dart
_SettingsTile(
  icon: Icons.download_rounded,
  title: 'Export Data',
  subtitle: 'Export all data as CSV files for backup',
  onTap: () => _exportAllData(context, ref),
),
```

`_exportAllData` follows the same loading/error pattern already used in
`reports_screen.dart`'s `_export` (an `isExporting` flag flips a button icon to a small
`CircularProgressIndicator`, disables the tile while running, and shows a `SnackBar` on
failure):

1. Set exporting state, disable the tile.
2. `final files = await DataExportService.exportAllToCsv(db);`
3. `await DataExportService.shareCsvs(files, storeName: storeInfo?.storeName);`
4. On any thrown error, show an error `SnackBar` and do not open the share sheet.
5. Reset exporting state in a `finally`.

The database instance and store name come from existing providers already used elsewhere in
Settings (`appDatabaseProvider` / store info provider) — no new providers needed.

### Error handling

- If a table read or file write fails partway through, the whole export fails (no partial
  share sheet with some files missing) — surfaced as a `SnackBar`, matching
  `ReportExportService`'s existing failure UX in `reports_screen.dart`.
- No special handling for an empty database (e.g. a freshly onboarded device with no sales yet)
  beyond the empty-table-still-gets-a-header-row behavior above — the share sheet just opens
  with mostly-empty files, which is correct.

### Testing

- Unit test `DataExportService.exportAllToCsv` against an in-memory `AppDatabase` (existing
  test setup pattern, see other `core/services` tests if present / `core/database` tests):
  seed a couple of tables, assert one CSV file per table is produced, header row matches column
  names, and an empty table still produces a header-only file.
- Manual verification on-device: tap Export Data with a populated database, confirm the share
  sheet opens with 18 files and spot-check a couple of CSVs (e.g. `sales.csv`, `users.csv`
  including `pin_hash`) for correct content.
