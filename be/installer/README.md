# POS Kiosk — Build & Deployment Guide

How to build the Windows installer and deploy the POS Kiosk (Flutter app + NestJS
backend + portable PostgreSQL 16) to a terminal.

> **TL;DR**
> 1. Run `build-installer.bat` from the repo root.
> 2. **Right-click the resulting `.exe` → "Run as administrator"** to install.
> 3. Confirm `POSPostgres` and `POSBackendService` are `RUNNING`, then launch the kiosk.

---

## What the installer bundles

| Component | Source | Installed to | Runs as |
|---|---|---|---|
| Flutter kiosk app | `kiosk\build\windows\x64\runner\Release\` | `C:\POSKiosk\` | desktop app (`pos_app.exe`) |
| NestJS backend | `be\POSBackend.exe` (SEA build) | `C:\POSKiosk\backend\` | Windows service `POSBackendService` (via NSSM) |
| PostgreSQL 16 | `C:\pgsql\` (portable) | `C:\POSKiosk\pgsql\` | Windows service `POSPostgres` (via `pg_ctl`) |
| Database data | created on install | `C:\posdata\` | — |
| Logs | created on install | `C:\POSKiosk\logs\` | — |
| Database backups | created on first scheduled run | `C:\POSKiosk\Backups\` | Scheduled Task `POSKioskDatabaseBackup` (daily, 2 AM, as `SYSTEM`) |
| Transaction/report PDF archive | created by the kiosk app at print time | `C:\POSKiosk\History\` | — |

Install paths have **no spaces** on purpose — `pg_ctl` cannot register a service
whose binary path contains spaces.

---

## One-time machine prerequisites

The build script (`build-installer.ps1`) checks all of these and aborts if any are
missing:

| Requirement | Expected location |
|---|---|
| Inno Setup 6 | `%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe` |
| Portable PostgreSQL 16 | `C:\pgsql\bin\pg_ctl.exe` (plus `lib\`, `share\`) |
| NSSM | `C:\nssm\nssm.exe` |
| FVM + Flutter | `fvm flutter` on PATH |
| Node.js | `npm` on PATH |
| Backend prod config | `be\.env.prod` (copy from `.env.example`, fill in real JWT secrets / DB creds) |

---

## Building the installer

From the repository root:

```powershell
.\build-installer.bat
```

- Prompts for a version. Press **Enter** to keep the current one, or type a new
  version (e.g. `1.1.7`) to bump `installer.iss` automatically.
- Output: `be\installer\output\POSKiosk-Setup-<version>.exe`

### What `build-installer.bat` → `build-installer.ps1` does, in order

1. **Preflight** — verifies all prerequisites above.
2. **(Optional) version bump** — rewrites `#define MyAppVersion` in `installer.iss`.
3. **Flutter codegen** — `fvm flutter pub get` + `dart run build_runner build`.
4. **Parallel build:**
   - Backend: `npm run build:sea` → produces `be\POSBackend.exe`.
     `build:sea` itself runs `migration:sync-index`, `seed:sync-index`, and `build`
     first, so the migration/seeder index files are always current.
   - Flutter: `fvm flutter build windows`.
5. **Sanitize `installer.iss`** — strips any curly/smart quotes (`“ ”`) and replaces
   them with straight ASCII quotes. See *Troubleshooting → Curly quotes* below.
6. **Compile** — runs `ISCC.exe installer.iss` (LZMA2 ultra, ~2 min).

Because steps 3–5 are automatic, **the only manual prep is making sure
`be\.env.prod` exists and is correct.** Migrations/seeders index-sync is handled
by `build:sea`. (For a deeper pre-flight on migrations/seeders, see
`be\docs\pre-installer-checklist.md`.)

---

## Installing on a terminal

1. Copy `POSKiosk-Setup-<version>.exe` to the target machine.
2. **Right-click → "Run as administrator".** This is required — the installer
   registers two Windows services (`POSPostgres`, `POSBackendService`), and service
   registration fails silently without elevation.
3. During the wizard:
   - **Kiosk Number** — a unique number `1–999` for this terminal. It appears in all
     sales order numbers (e.g. `SO-001-2026-0001`). Stored in `C:\POSKiosk\settings.txt`.
   - **Seed initial data** — check **only on a first-time install** to load starter
     products/menus/users. Leave unchecked on upgrades (it would duplicate data).
   - **Desktop shortcut** — optional.

### What the installer does at run time

1. Installs the Visual C++ 2015–2022 runtime (silent, skips if present).
2. `setup-postgres.bat` → initializes `C:\posdata`, registers + starts `POSPostgres`
   (as `NT AUTHORITY\NetworkService`), creates `pos_db`, runs TypeORM migrations.
3. `run-migrations.bat` → applies any remaining migrations.
4. *(if "Seed" checked)* `POSBackend.exe --seed`.
5. `install-backend-service.bat` → registers + starts `POSBackendService` via NSSM,
   then polls `http://localhost:3000/api/v1/health/live` until the backend answers.
6. Offers to launch the kiosk.

---

## Backups

Every install registers a Windows Scheduled Task (`POSKioskDatabaseBackup`) that runs
`scripts\backup-database.bat` daily at **2:00 AM as `SYSTEM`**. Each run:

1. `pg_dump`s `pos_db` in custom format (compressed, restorable) to
   `C:\POSKiosk\Backups\pos_db_<YYYYMMDD_HHmmss>.dump`.
2. Copies `backend\.env` and `settings.txt` into
   `C:\POSKiosk\Backups\config\<YYYYMMDD_HHmmss>\` alongside it — a restored database is
   useless without the JWT secrets/DB credentials in `.env`.
3. Deletes dumps and config snapshots older than **30 days**.

Logged to `C:\POSKiosk\logs\backup-database.log`. Run `scripts\backup-database.bat
"C:\POSKiosk"` manually (as administrator) to take an ad-hoc backup, e.g. before an
uninstall/reinstall.

**Secondary copy (USB / LAN share / cloud-synced folder) — opt-in per store:** a local-only
backup dies with the machine it's protecting, which defeats the point for a single physical
terminal. To enable it, create `C:\POSKiosk\Backups\secondary-target.txt` containing a single
line with a reachable path (a drive letter like `E:\` for a USB drive, or a UNC path like
`\\NAS\posbackups\`). Every run of `backup-database.ps1` then also copies that run's dump +
config snapshot there; if the file is absent, empty, or the path isn't reachable, the local
backup still succeeds — the secondary copy is best-effort on top of it, never a dependency.

**Restore:** run `scripts\restore-database.bat "C:\POSKiosk" "<dump file>"` as administrator —
it stops the backend, runs `pg_restore --clean`, offers to restore the matching
`.env`/`settings.txt` config snapshot, and restarts the backend. (Equivalent manual command:
`pgsql\bin\pg_restore.exe -U postgres -h 127.0.0.1 -p 5432 -d pos_db --clean --if-exists <dump file>`.)

Both `C:\POSKiosk\Backups\` and `C:\POSKiosk\History\` (the kiosk's transaction/cashier-report
PDF archive, see `kiosk/CLAUDE.md` / the print flow in `receipt_notifier.dart`) intentionally
survive uninstall — see the comment in `installer.iss`'s `[UninstallDelete]`. Full design
rationale: `docs/superpowers/specs/2026-08-10-backup-strategy-design.md`.

---

## Verifying a successful install

```powershell
sc query POSPostgres
sc query POSBackendService
```

Both must show `STATE : 4  RUNNING`. Then:

```powershell
# Backend liveness (note the api/v1 prefix)
Invoke-WebRequest http://localhost:3000/api/v1/health/live -UseBasicParsing
```

A `200` response means the backend is up. Launch the kiosk — it should connect.

---

## Upgrading an existing install

Run a newer `POSKiosk-Setup-<version>.exe` **as administrator** over the top.
Before extracting, the installer stops `POSBackendService`, `POSPostgres`, and any
running `pos_app.exe` so locked files can be overwritten (`InitializeSetup` in
`installer.iss`). `C:\POSKiosk\backend\.env` is preserved (`onlyifdoesntexist`).
Leave "Seed initial data" **unchecked** on upgrades.

Backend-only hotfix (replace just the exe without a full reinstall):
`C:\POSKiosk\scripts\update-backend.bat` (run as administrator).

---

## Troubleshooting

### Kiosk shows "Unable to reach server"

The backend or database isn't running. Check the services:

```powershell
sc query POSPostgres
sc query POSBackendService
```

If either is missing or stopped, run the recovery script **as administrator**:

```
C:\POSKiosk\scripts\recover-services.bat   (right-click → Run as administrator)
```

It re-runs PostgreSQL setup, then the backend-service install, and prints both
service states. Then inspect the logs in `C:\POSKiosk\logs\`.

### "CreateProcess failed; code 2 — The system cannot find the file specified"

The path in the error dialog is wrapped in **curly quotes** (`“ ”`). Inno Setup only
recognizes straight ASCII quotes (`"`) as delimiters; curly quotes get treated as
part of the filename, so even `cmd.exe` / `powershell.exe` appear "not found".

- **Cause:** an editor with smart-quote autocorrect re-saved `installer.iss`.
- **Prevention:** `build-installer.ps1` auto-strips curly quotes before compiling, so
  always build through `build-installer.bat`. Avoid editing the `[Run]`/`[Files]`
  lines in an editor that auto-converts quotes.
- **Manual fix** (if ever needed):
  ```powershell
  $p="be\installer\installer.iss"; $t=[IO.File]::ReadAllText($p)
  $t=$t.Replace([char]0x201C,'"').Replace([char]0x201D,'"')
  [IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($true)))
  ```

### PostgreSQL service won't start

Usually **port 5432 is already in use** (a Docker postgres container or another
local PostgreSQL). Stop the conflicting instance and re-run
`recover-services.bat`. Detail is logged to
`C:\POSKiosk\logs\setup-postgres-install.log` and the PostgreSQL log under
`C:\posdata\log\`.

### Health check / backend not responding

The backend mounts everything under the global prefix `api/v1` (`be\src\main.ts`),
so its health endpoints are:

| Endpoint | Checks |
|---|---|
| `GET /api/v1/health` | memory + disk + postgres |
| `GET /api/v1/health/live` | memory only (liveness) |
| `GET /api/v1/health/ready` | postgres (readiness) |

`http://localhost:3000/health/live` (without the prefix) returns **404** — that's
expected, not a bug.

---

## Log reference (`C:\POSKiosk\logs\`)

| File | Written by |
|---|---|
| `setup-postgres-install.log` | PostgreSQL init / service registration / migrations |
| `run-migrations-install.log` | migration step |
| `install-backend-service-install.log` | NSSM service install + health poll |
| `backend-output.log` / `backend-error.log` | the running backend (NSSM redirects stdout/stderr; rotates at 10 MB) |
| `update-backend.log` | `update-backend.bat` runs |

---

## File map

```
build-installer.bat / build-installer.ps1     # repo root — one-click build
be\.env.prod                                   # prod backend config (you create this)
be\POSBackend.exe                              # SEA build output
be\installer\
├── installer.iss                              # Inno Setup script
├── README.md                                  # this file
├── output\POSKiosk-Setup-<version>.exe        # build output
├── redist\vc_redist.x64.exe                   # bundled VC++ runtime
└── scripts\
    ├── setup-postgres.{bat,ps1}               # init DB + register POSPostgres + migrate
    ├── run-migrations.{bat,ps1}               # apply TypeORM migrations
    ├── install-backend-service.{bat,ps1}      # register POSBackendService via NSSM
    ├── update-backend.{bat,ps1}               # replace backend exe (hotfix)
    ├── uninstall-services.{bat,ps1}           # remove both services (+ backup task)
    ├── backup-database.{bat,ps1}              # pg_dump + config snapshot + retention
    ├── register-backup-task.{bat,ps1}         # register the daily backup Scheduled Task
    ├── restore-database.{bat,ps1}             # pg_restore a chosen dump (disaster recovery)
    └── recover-services.bat                   # re-run DB + backend setup (recovery)
be\docs\pre-installer-checklist.md             # migrations/seeders pre-flight detail
```

> The `.bat` files are thin wrappers that invoke their `.ps1` counterpart. The
> installer calls the `.bat` wrappers via `cmd.exe` (`{cmd}`) so `powershell.exe`
> resolves through `PATH` — avoiding `{sys}` resolving to `SysWOW64` in the 32-bit
> installer process (where `WindowsPowerShell\v1.0\powershell.exe` does not exist).
