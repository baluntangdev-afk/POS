# Backup strategy implementation

> Executed inline in a single session from `docs/superpowers/specs/2026-08-10-backup-strategy-design.md`.
> This is a record of what was built, not a task list to re-execute.

**Goal:** implement the two backup mechanisms from the design spec — automated, restorable
`pos_db` backups, and a human-readable PDF History archive of receipts/cashier reports.

## Part 1 — Database backup automation (`be/installer/`)

- `scripts/backup-database.ps1` (+ `.bat` wrapper) — daily `pg_dump -Fc` of `pos_db` to
  `{app}\Backups\pos_db_<timestamp>.dump`, config snapshot (`.env` + `settings.txt`) to
  `{app}\Backups\config\<timestamp>\`, 30-day retention cleanup. Logs to
  `{app}\logs\backup-database.log`.
- `scripts/register-backup-task.ps1` (+ `.bat`) — idempotently registers the
  `POSKioskDatabaseBackup` Windows Scheduled Task (daily, 2:00 AM, runs as `SYSTEM`).
- `scripts/uninstall-services.ps1` — added a step to remove the `POSKioskDatabaseBackup`
  task on uninstall (mirrors how services are torn down).
- `installer.iss` —
  - `[Dirs]`: added `{app}\Backups\config` and `{app}\History`.
  - `[Files]`: added the two new script pairs.
  - `[Run]`: added "Step 3b" invoking `register-backup-task.bat` after the backend service
    install step.
  - `[UninstallDelete]`: added a comment guard — `Backups`/`History` must never be added
    here, since surviving uninstall is the entire point (see the risk this closes: uninstall
    already wipes `C:\posdata`).
- `README.md` — new "Backups" section (schedule/retention/restore commands) + file map/
  component table updates.

## Part 2 — Transaction/cashier-report PDF History (`kiosk/`)

- `pubspec.yaml` — added `pdf: ^3.11.1` (`flutter pub get` run, resolved clean).
- `lib/services/history/history_archive_service.dart` — resolves
  `<app dir>\History\<year>\<month>\` relative to `Platform.resolvedExecutable` (base dir
  injectable for tests), writes bytes to a named file.
- `lib/services/history/pdf_document_builder.dart` — shared narrow-page (80mm-equivalent)
  PDF layout helper (text/row/tableRow/divider primitives) used by all four renderers below.
- Four render use cases, each mirroring its existing `encode_esc_pos_*.dart` counterpart
  (same data, PDF output instead of ESC/POS bytes):
  - `features/sales/use_cases/render_receipt_pdf.dart`
  - `features/cashier_report/use_cases/render_cashier_report_pdf.dart` (X-reading)
  - `features/cashier_report/use_cases/render_z_reading_pdf.dart`
  - `features/cashier_report/use_cases/render_cashier_daily_report_pdf.dart`
- Wired into the four existing print flows (`receipt_notifier.dart`,
  `cashier_x_reading_notifier.dart`, `z_reading_notifier.dart`,
  `cashier_daily_report_notifier.dart`): after the ESC/POS bytes are sent to the printer, each
  notifier renders the PDF and saves it via `HistoryArchiveService`, wrapped in a `try/catch`
  so a History write failure never blocks or fails the print/close action.

## Verification performed

- `dart analyze lib`: clean — no errors; only pre-existing info-level lints across the
  codebase (one new file matches a lint pattern already present in the ESC/POS encoders it
  mirrors).
- New unit tests: `test/services/history/history_archive_service_test.dart` (3 tests — nested
  path construction, directory creation, default-to-now) — all pass.
- Full `flutter test` run: all pre-existing tests still pass, including the three cashier
  report notifier `print()`/`close()` tests that now exercise code paths adjacent to the new
  History-save call. One unrelated, pre-existing failure
  (`test/features/catalog/data/models/product_test.dart`, references a `lib/features/catalog/`
  path that doesn't exist) predates this change — confirmed via `git log` on that file.

## Not done in this pass (flagged, not silently skipped)

- **Visual verification of the rendered PDFs** — no Windows/printer hardware available in this
  environment. `dart analyze` and the unit test verify the code compiles and writes files to
  the right place; they do not verify the PDFs render correctly or read well. Recommend a
  manual check on the target hardware (or `flutter run -d windows`) before relying on this in
  production: print a receipt and each report type, confirm the PDFs appear under
  `History\<year>\<month>\` and look right.
- **Secondary/off-machine backup copy** (USB/LAN share/cloud) — deliberately left open in the
  design spec pending a specific target; `backup-database.ps1` only writes locally to
  `{app}\Backups\`.
- **Restore runbook script** — the design spec's restore steps are documented in
  `README.md` but not scripted (no `restore-database.ps1`). Manual `pg_restore` today.
- **`be/installer/installer.iss` was not recompiled/tested end-to-end** (no Inno Setup /
  portable Postgres / NSSM available in this dev environment) — the next real installer build
  should confirm the new `[Run]`/`[Dirs]` entries work as expected on a target machine.
