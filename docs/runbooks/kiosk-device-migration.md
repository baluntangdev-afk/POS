# Runbook: Migrating a kiosk to a new machine

Moves a store's **entire** POS dataset — users and PINs, products, modifiers,
POS-terminal config, sales orders, payments, refunds, discounts, and all
cashier/X/Z report history — from one Windows kiosk to a replacement machine.

The transfer is a **full replace**: importing wipes whatever is on the target and
loads the backup verbatim, including receipt/OR sequence positions.

## Prerequisites

- Both machines run the **same app version**. A strict import is refused if the
  database migration history differs; if you cannot line the versions up, see
  **Partial restore** below.
- You are signed in as an **Admin** or **Supervisor** on both machines.
- A USB drive or shared folder to carry one file between machines.
- A passphrase (12+ characters) that you choose and keep — the backup file is
  useless without it and it is not recoverable.

## 1. Export on the OLD machine

1. Sign in as Admin/Supervisor → **Backup & Transfer** → **Export Backup**.
2. Enter and confirm your passphrase.
3. Authorize with a supervisor PIN when prompted.
4. Choose where to save `pos-kiosk-backup-<date>.posbackup` (e.g. the USB drive).
5. Wait for "Backup Saved". Copy the file somewhere safe as well — treat it like
   a list of everyone's PINs, because it contains them (encrypted).

The old machine is untouched by an export; you can keep trading on it until the
new one is ready.

## 2. Prepare the NEW machine

1. Run the POS installer. Let it finish installing the app, the
   `POSBackendService`, and `POSPostgres`.
2. Launch the app once and let it reach the login screen (this confirms the
   backend + database came up and migrations ran).
3. Do **not** register the POS terminal or add staff yet — the import brings all
   of that across.

## 3. Import on the NEW machine

1. Copy the `.posbackup` file onto the new machine.
2. Sign in as Admin/Supervisor. If no staff exist yet, use the seeded
   admin account from the installer.
3. **Backup & Transfer** → **Import & Restore**.
4. Choose the `.posbackup` file, enter the passphrase, type `REPLACE`, and
   authorize with a supervisor PIN.
5. Wait for "Restore Complete" — do not close the app while it runs. You will be
   signed out automatically.

If you see **"Incompatible Backup"**, the two machines are on different app
versions. The best fix is to update both to the same version and export again.
If that is not possible, use **Partial restore** (next section).

## Partial restore (different app versions)

When the machines cannot be brought to the same version, tick **Partial restore**
in the Import & Restore dialog (or press **Partial restore** on the "Incompatible
Backup" prompt). This:

- imports only the tables and columns the two devices have in common,
- keeps the new machine's own database schema and migration history,
- reports everything it did **not** import on the "Restore Complete" screen.

Caveats:

- Data in tables or columns the new version added or changed is **not** carried
  across — you may need to re-enter it by hand.
- A table is skipped entirely if the new version added a required column the
  backup has no value for.
- Because it is still a full replace of everything else, take the same care as a
  normal import and verify thoroughly afterwards (step 4).
- Prefer matching versions whenever you can; partial restore is the fallback.

## 4. Finish

1. On the new machine, restart the services so nothing caches stale data:
   - `services.msc` → restart **POSBackendService** (and **POSPostgres** if in
     doubt), or reboot the machine.
2. Sign back in and verify:
   - staff list and roles,
   - product catalog and prices,
   - recent transactions and totals,
   - the next receipt / OR number continues where the old machine left off
     (ring up a test sale, then void it).
3. Retire the old machine. If it kept trading after the export, those extra
   sales are **not** in the backup — reconcile or re-export before switching
   over for real.

## Notes

- Product images and other binary data travel inside the archive.
- The archive is gzip-compressed then AES-256-GCM encrypted; the passphrase
  derives the key via scrypt. A wrong passphrase or a tampered file fails
  cleanly and changes nothing.
- A failed import rolls back — the target database is left exactly as it was.
