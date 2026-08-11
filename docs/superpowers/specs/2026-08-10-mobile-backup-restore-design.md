# Mobile POS backup & restore

> **Revision note (2026-08-11):** Two decisions below were revised after the initial
> implementation shipped, based on follow-up discussion: the automatic trigger changed from
> daily to **hourly** (with retention changed from count-based to time-based to match), and the
> Backup Password changed from an arbitrary string to a **6-digit PIN** entered via the app's
> existing PIN keypad. Both changes are reflected inline below rather than kept as a separate
> "originally we said X" appendix — this document describes the shipped design.

## Problem

`mobile/` ("Offline mobile POS application") stores everything locally in a Drift/SQLite
database (`lib/core/database/app_database.dart`, 18 tables: users, products, sales, payments,
refunds, X/Z-readings, daily reports, store info, etc.) plus locally-stored product photos
(`lib/core/services/image_storage_service.dart`). There is no backend — the app never syncs
anywhere — so this local data is the *only* copy that exists.

There is currently no way to get a durable copy of that data off the device, and nothing
protects it from device loss, an accidental uninstall, or a factory reset. A design
(`docs/superpowers/specs/2026-08-07-export-all-data-design.md`) proposed a manual CSV export
via the OS share sheet, but it was never implemented, and on inspection it has two gaps that
matter for a real backup: files are written to the app's private temp directory (deleted on
uninstall, so the backup only survives if the admin manually shares it somewhere before
uninstalling), and there's no restore path.

This spec **supersedes** the 2026-08-07 spec and replaces it with a design that (a) survives an
uninstall automatically via a background backup that runs independent of app usage, (b)
supports manual on-demand export, and (c) supports restoring a backup onto a device — e.g.
after a reinstall or device swap.

## Scope

- Automatic hourly backup, running as a background job independent of app usage.
- Manual "Back Up Now" action, admin/supervisor-gated, for on-demand backup + sharing off-device.
- "Restore Data" action, admin/supervisor-gated, to load a backup file back onto a device.
- Backup format: one password-protected `.zip` per backup containing a single JSON file (all 18
  tables) plus the `product_images/` folder, protected by a 6-digit Backup PIN.
- Out of scope: syncing to a cloud service, merge-style restore (restore is always full
  replace), redaction/anonymization of any column (matches the superseded spec's stance —
  `users.pin_hash` is included as-is; it's a bcrypt hash, not a raw PIN), true incremental/
  per-transaction backup (considered and rejected — see "Why not per-transaction" below).

## Design

### Backup format

Each backup is one `.zip` file:

- `data.json` — top-level object keyed by table name (`users`, `product_groups`, `products`,
  `product_variants`, `modifier_groups`, `modifier_options`, `product_modifier_groups`, `sales`,
  `sale_items`, `sale_item_modifiers`, `payments`, `payment_methods`, `refunds`, `refund_items`,
  `store_info`, `x_readings`, `z_readings`, `daily_reports`), each value an array of that
  table's rows as JSON objects (column name → value), generated from a fixed, foreign-key-safe
  table order (`kBackupTableOrder` in `backup_data_serializer.dart`) rather than Drift's generic
  `db.allTables` reflection — this keeps dump/delete/insert ordering explicit and correct.
- `product_images/` — copy of every file referenced by a product's local image path
  (`ImageStorageService`'s `<appDocumentsDir>/product_images/`).
- The zip itself is encrypted with the Backup PIN (AES/ZipCrypto via the `archive` package's
  password support — new dependency). JSON was chosen over CSV specifically because it's a
  single file that preserves types (numbers/booleans/null) explicitly, which makes restore
  reliable; CSV would require 18 separate files and lossy type reconstruction.

File naming: `pos_backup_<yyyyMMdd_HHmmss>.zip`.

### Storage location

Written to the public `Downloads/POS Backups/` folder via Android's MediaStore API, using the
`media_store_plus` package (new dependency). This directory is **not** app-private storage,
so it survives an app uninstall — unlike `path_provider`'s app-specific external directory,
which Android deletes on uninstall same as internal storage.

Retention: **time-based, not count-based.** After each successful backup, entries older than 7
days are dropped from a local manifest (`BackupManifestStore`, since `media_store_plus` has no
"list files in a folder" API) and their corresponding files deleted from `Downloads/POS
Backups/`. A count-based "keep the newest 30" was the original design, but that assumed daily
backups (~30 days of history); once the trigger moved to hourly, a count cap would only cover
a day and a bit before the oldest backups start rolling off — so retention had to become a time
window instead. 7 days caps storage at roughly 168 zips while keeping a week of fallback history.

### Backup PIN

One shared secret — a **6-digit PIN**, not an arbitrary password — stored in `Settings`
(admin/supervisor-gated "Backup & Restore" screen), persisted via `flutter_secure_storage` (new
dependency — not currently used in `mobile/`; `kiosk/` already depends on it for a similar
purpose) so it's available to the background job without prompting anyone.

- Entered via the app's existing `PinDots`/`PinKeypad` widgets (`features/auth/view/widgets/`) —
  the same numeric keypad used for login and the forced-PIN-change flow — rather than a free-text
  field, so it feels identical to every other PIN entry in the app.
- Setting or changing it is a two-step **enter, then confirm** flow (mirrors `SetupPinScreen`):
  the PIN must be typed twice and match before it's saved, so a mistyped PIN can't silently lock
  an admin out of their own backups.
- Any user logged in as **admin or supervisor** can view (implicitly, by choosing "Change") or
  set/change the Backup PIN (a single shared value — not tied to any individual's login PIN,
  since a zip needs one consistent password to decrypt and different admins/supervisors have
  different PINs).
- Used automatically to encrypt every automatic and manual backup.
- Restore prompts for this PIN via the same keypad; a wrong PIN fails cleanly with an error
  message (see Error handling) and does not touch existing local data.
- The Backup & Restore screen shows "Backups are off until a Backup PIN is set" and disables
  "Back Up Now"/"Restore Data" until one exists.
- **Known trade-off, accepted deliberately:** a 6-digit numeric PIN has only 1,000,000 possible
  combinations — meaningfully weaker as zip-encryption key material than an arbitrary password.
  This was chosen anyway for consistency with the rest of the app's PIN-based UX and because the
  device itself being physically secured is the primary defense; it's a conscious trade-off, not
  an oversight.

### Automatic hourly backup

- **Primary trigger**: an Android `WorkManager` periodic job (via the `workmanager` package —
  new dependency), registered on app startup if not already registered
  (`ExistingPeriodicWorkPolicy.keep`), running roughly **every hour**
  (`Workmanager().registerPeriodicTask(..., frequency: Duration(hours: 1))`). Runs independently
  of whether the app is open — WorkManager wakes the app's background isolate to perform the
  backup.
- **Fallback safety net**: on every app startup (foreground launch), check the newest backup's
  timestamp. If it's more than **1 hour** old (or there's never been one), run a backup
  immediately in the foreground. This covers cases where the device was off, asleep, or under
  aggressive battery-optimization restrictions and the WorkManager job didn't fire — Android's
  WorkManager only guarantees an *interval*, not wall-clock timing, so this backstop matters more
  at hourly cadence than it would at daily.
- Both paths call the same underlying `BackupService.createBackup()` — the trigger is the only
  difference.
- If the Backup PIN hasn't been set yet, automatic backup silently skips (no error shown to a
  cashier who isn't admin/supervisor).

#### Why not per-transaction

An earlier discussion considered triggering a backup after every sale instead of on a timer, to
minimize the data-loss window further. Rejected because the backup mechanism dumps the **entire**
database on every run, not a delta — there's no incremental/append-only backup here. Per-
transaction would mean re-serializing and re-zipping the full history on every single sale
(wasteful and gets slower as history grows), would blow through any reasonable retention count
in hours for a busy store, and would flood `Downloads/POS Backups/` with hundreds of files a day.
Hourly was chosen as the practical middle ground: it meaningfully shrinks the loss window
compared to daily, reuses the exact same full-dump mechanism without needing a delta/incremental
redesign, and keeps the Downloads folder and retention window sane.

### Manual backup ("Back Up Now")

Admin/supervisor-gated "Back Up Now" action on the "Backup & Restore" screen (`Settings` →
"Backup & Restore", alongside the Backup PIN card and "Restore Data"):

1. Calls the same `BackupService.createBackup()` used by the automatic path — writes to
   `Downloads/POS Backups/` and applies the same 7-day retention.
2. Additionally opens the OS share sheet (`share_plus`, already a dependency) with the resulting
   zip, so the admin can immediately send it off-device (email, Drive, USB transfer app, etc.).
3. Standard loading/error UX matching the existing `ReportExportService` pattern used elsewhere
   in Settings/Reports (disable tile + spinner while running, `SnackBar` on failure).

### Restore

Admin/supervisor-gated "Restore Data" action on the "Backup & Restore" screen:

1. Pick a `.zip` file via a file picker (`file_picker`, already a dependency) scoped to `.zip`
   files, and enter the 6-digit Backup PIN via the same keypad used elsewhere.
2. Attempts to decrypt and parse `data.json` from the selected zip using the entered PIN.
   - Wrong PIN or unparseable/corrupt archive → inline error message, stop. No data touched.
3. On successful parse, shows a confirmation dialog: *"This will replace all data currently on
   this device with the contents of this backup. A safety backup of the current data will be
   made first. Continue?"*
4. On confirm:
   a. Run `BackupService.createBackup()` first (safety snapshot of current on-device data,
      written to `Downloads/POS Backups/` like any other backup, subject to the same retention).
   b. Inside a single DB transaction: delete all rows from all 18 tables (in reverse
      foreign-key-dependency order), then insert all rows from `data.json` (in
      foreign-key-dependency order: `store_info`, `users`, `product_groups`, `products`,
      `product_variants`, `modifier_groups`, `modifier_options`, `product_modifier_groups`,
      `payment_methods`, `sales`, `sale_items`, `sale_item_modifiers`, `payments`, `refunds`,
      `refund_items`, `x_readings`, `z_readings`, `daily_reports`).
   c. Replace the `product_images/` directory contents with the zip's `product_images/` folder.
   d. If any step in (b) or (c) fails, the DB transaction rolls back so local data is left
      exactly as it was before the restore attempt; the safety backup from (a) still exists in
      `Downloads/POS Backups/` regardless, so nothing is unrecoverable even in that failure case.
5. Show a success dialog instructing the admin/supervisor to close and reopen the app (not just
   a `SnackBar`, since this needs to be acted on) — the app is not force-closed programmatically;
   the dialog has an "OK" button and the admin restarts it manually. A full restart is the
   simplest way to guarantee every already-open screen and cached provider state reflects the
   restored data, rather than trying to invalidate every affected Riverpod provider in place.
   On failure, show an error message and leave the app running as-is (restore did not apply).

### Error handling

- Any failure during backup creation (table read, JSON serialize, zip/encrypt, file write) fails
  the whole operation — no partial zip is left in `Downloads/POS Backups/`.
- Restore failures never partially apply — either the full replace succeeds or the previous data
  remains untouched (transaction + the pre-restore safety backup as a second line of defense).
- WorkManager job failures (e.g. thrown exception) are swallowed — a background job silently
  failing shouldn't surface anything to whoever is using the device; the startup safety net will
  retry it as a normal foreground backup the next time the app opens.

### Testing

- Unit test the table→JSON dump against an in-memory `AppDatabase` (seed a couple of tables,
  assert JSON structure, verify empty tables still appear as empty arrays).
- Unit test restore's delete+reinsert ordering against a seeded in-memory DB, including a
  failure-mid-restore case (a NOT NULL violation) to confirm rollback leaves prior data intact.
- Unit test zip encrypt/decrypt round-trip (create with PIN, decrypt with correct PIN succeeds,
  decrypt with wrong PIN fails cleanly with `BackupArchiveException`).
- Unit test the manifest's time-based retention (`removeOlderThan`): entries past the cutoff are
  dropped and their file names returned; nothing dropped when everything is within the window.
- Unit test `BackupPasswordService` against a fake in-memory key/value store (no platform-channel
  mocking needed, since it depends on an injectable `SecureKeyValueStore` interface).
- Manual on-device verification: trigger manual backup, confirm zip appears in `Downloads/POS
  Backups/` and share sheet opens; confirm WorkManager job is registered (`adb shell dumpsys
  jobscheduler` or WorkManager's own inspection tooling); confirm restore from a real backup zip
  restores products/sales/images correctly on a second device or after clearing app data.

## New dependencies

- `archive` — zip creation/extraction with password support.
- `workmanager` — periodic background job for the hourly backup trigger.
- `media_store_plus` — writes files into public `Downloads/` via MediaStore on Android 10+.
- `flutter_secure_storage` — persists the Backup PIN (not currently used in `mobile/`; `kiosk/`
  already depends on it for a similar purpose, so this is a proven pattern in this codebase).
