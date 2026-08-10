# Backup strategy for `be/` + `kiosk/` (design)

## Current state (as of this audit)

There is **no backup strategy** for the `be`/`kiosk` deployment today:

- No scheduled `pg_dump`/`pg_basebackup` anywhere in `be/installer/scripts/` or the PM2/NSSM
  setup. The only backup-adjacent text is a comment in
  `be/installer/scripts/stop-services.ps1:9` noting the service can be stopped for "a cold
  database backup" — that's a hook for a human to do it manually, not an implemented mechanism.
- `kiosk/` has no backup logic of its own (it's a stateless client of `be/`). Its only
  meaningfully unrecoverable local state is `C:\POSKiosk\backend\.env`, the
  `SECURE_STORAGE_KEY`-protected secure storage blob, and `C:\POSKiosk\settings.txt` (kiosk
  number).
- **`be/installer/installer.iss:206`** (`[UninstallDelete]`) deletes `C:\posdata` — the entire
  live PostgreSQL data directory — on every uninstall, with no prompt and no backup step. Any
  admin who uninstalls for a "clean reinstall" during troubleshooting currently loses **all**
  transaction data permanently. This is the sharpest risk this strategy needs to close.
- The sibling `mobile/` app has an "Export all data (CSV)" admin action
  (`docs/superpowers/specs/2026-08-07-export-all-data-design.md`) that dumps its local SQLite DB
  to CSV via the OS share sheet. That's a different app (offline mobile POS, different DB, no
  Postgres) — not applicable to `be`/`kiosk`, though it's a useful reference for "manual export as
  a backup mechanism" done elsewhere in this codebase.

## Goals

1. The Postgres database (`pos_db` in `C:\posdata`) must be recoverable after data loss, disk
   failure, or an uninstall — via a restorable, automated, unattended backup.
2. A human-readable, per-transaction/per-report **History** archive
   (`C:\POSKiosk\History\`) of receipts and cashier reports (X-reading, Z-reading, daily report)
   as PDFs, for quick lookup, reprint, and dispute resolution without touching the database.
3. Both survive the normal install/upgrade/uninstall lifecycle of the Windows installer.
4. Config needed to stand the app back up (`​.env`, `settings.txt`) is backed up alongside the
   database, not lost separately.

## Non-goals (this pass)

- No cloud upload target is chosen yet — see "Open decision" below.
- No "restore from PDF" flow — PDFs are read-only archive, never a restore source.
- No changes to `mobile/`.
- This document is the **strategy only**; no scripts or installer changes are implemented in this
  pass (per your answer above). A follow-up implementation plan should be written from this spec
  when you're ready to build it.

---

## Mechanism A — Database backup (disaster recovery)

**What:** a scheduled `pg_dump` of `pos_db` in custom format (`-Fc`), which is compressed and
restorable with `pg_restore` — matches the portable PostgreSQL 16 already bundled by the
installer, so no new tooling is needed on the terminal.

**Where:**
- Primary (always): `C:\POSKiosk\Backups\` — local, so a first backup exists with zero external
  dependencies.
- Secondary (recommended, configurable per store): a copy step to whatever the store already has
  — a USB drive letter or a LAN share path, set once during/after install. This is the part that
  actually protects against the realistic failure mode for a single physical terminal (theft,
  fire, disk failure) — a local-only backup dies with the machine it's backing up.
  - Cloud upload (e.g. a shared Drive/OneDrive folder) is a reasonable later upgrade to the same
    step, but needs a target and credentials chosen per store, which is a business decision, not
    a technical one — deferred until you have a specific target in mind.

**Schedule:** daily, off-hours (e.g. 2:00 AM), via a Windows Scheduled Task — the same class of
mechanism the installer already uses for services (NSSM/`sc.exe`), so it fits the existing
operational model rather than introducing a new one.

**Retention:** 30 days rolling. The backup script deletes its own dumps older than 30 days each
run — no separate cleanup job needed.

**Naming:** `pos_db_YYYYMMDD_HHMMSS.dump` — sortable, collision-free, self-describing.

**Config backup:** each run also copies `C:\POSKiosk\backend\.env` and `C:\POSKiosk\settings.txt`
into a `config\` subfolder of the same dated backup, since a database with no `.env` (JWT
secrets, DB credentials) can't be brought back up standalone.

---

## Mechanism B — Transaction & Cashier Report History (PDF)

**What you asked for:** `C:\POSKiosk\History\` containing a PDF per completed transaction
(receipt) and per generated cashier report (X-reading, Z-reading, daily report).

**Why this is a second mechanism, not a replacement for A:** a PDF is a rendered snapshot — it
lets a cashier or admin reprint a receipt or look up a report without opening the database, but
it cannot rebuild `pos_db` if the database is lost. Mechanism A is what makes the system
recoverable; Mechanism B is what makes daily operations (disputes, reprints, audits) fast.

**Layout:** `C:\POSKiosk\History\<year>\<month>\` — e.g.
`C:\POSKiosk\History\2026\08\receipt_SO-001-2026-0001.pdf`,
`.../zreading_2026-08-10_143000.pdf`. Sharding by year/month keeps any one folder from
accumulating years of files.

**Generation trigger:** at the same point the receipt/report is already sent to the thermal
printer — `kiosk/lib/features/sales/use_cases/encode_esc_pos_receipt.dart` and
`kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_{cashier_report,z_reading}.dart`
already have the full `Receipt` / `CashierDailyReport` / `CashierXReading` / `ZReading` entities
in hand at print time — a PDF render is a second output from the same data, not a new data path.

**New dependency required:** `kiosk/pubspec.yaml` has no PDF package today (only
`esc_pos_utils_plus` for thermal ESC/POS encoding). Implementing this mechanism means adding the
`pdf` package (and running `flutter pub get` + `build_runner`) and writing render functions
parallel to the existing `encode_esc_pos_*` use cases — flagged here as new work for the
follow-up plan, not present yet.

**Retention:** keep indefinitely by default — these are small text-heavy PDFs, and this looks like
a BIR-regulated retail POS (VAT lines on `Receipt`, `SO-001-2026-0001`-style official receipt
numbering, the existing senior/PWD discount spec). Philippine BIR bookkeeping records are
typically subject to multi-year retention requirements — confirm the exact duration with your
accountant rather than me guessing a number here. Until you have a figure, "never auto-delete" is
the safe default since disk cost is negligible.

---

## Surviving the installer lifecycle

Checked `be/installer/installer.iss`:
- `[InstallDelete]` only wipes `{app}\scripts` before extraction (line 202) — a new
  `Backups\`/`History\` folder under `{app}` (`C:\POSKiosk\`) is untouched by this.
- `[UninstallDelete]` removes `C:\posdata` and `{app}\data` (line 206, 209) — **not**
  `{app}\Backups` or `{app}\History`, so both would already survive an uninstall today without any
  installer change, as long as they're never added to that section later. Worth calling out
  explicitly in the follow-up plan so nobody "cleans up" `[UninstallDelete]` by adding them.
- Neither folder is declared in `[Dirs]` (line 86-93) yet — the follow-up plan should add them so
  they exist from first install rather than relying on the backup script to `mkdir` them.

---

## Restore runbook (for the follow-up plan to script/document properly)

1. `C:\POSKiosk\scripts\stop-services.bat` (or the `POSPostgres`/`POSBackendService` equivalents)
   to free the DB.
2. `pg_restore` the chosen `.dump` file from `C:\POSKiosk\Backups\` into a fresh/emptied `pos_db`.
3. Restore `.env`/`settings.txt` from the matching `config\` subfolder if those were also lost.
4. Restart services, confirm via `GET /api/v1/health/ready` (checks Postgres per
   `be/README.md`'s documented health endpoints).
5. `C:\POSKiosk\History\` needs no restore step — it's an independent, read-only archive that was
   never touched by the loss (unless the whole machine/disk was lost, in which case it's gone
   too, which is the argument for the secondary copy in Mechanism A eventually covering it as
   well).

---

## Open decision for you

The one thing this document can't finalize without you: **what's the secondary copy target** for
Mechanism A (USB drive letter, a specific LAN share path, or a cloud folder) — that's store
infrastructure I don't have visibility into. Local-only + PDF history can ship without it, but the
actual "survives losing the terminal" guarantee depends on picking one.

## Next step

When you're ready to build this, this spec is the input to `superpowers:writing-plans` for a
bite-sized implementation plan (backup script, Scheduled Task registration, installer.iss
`[Dirs]` entries, and the kiosk-side PDF render use cases).
