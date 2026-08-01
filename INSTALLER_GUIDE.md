# POS Kiosk — Installer Build Guide

This guide covers every step to build `POSKiosk-Setup-1.0.0.exe` from scratch on a Windows developer machine.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [One-time Machine Setup](#2-one-time-machine-setup)
3. [Prepare Environment File](#3-prepare-environment-file)
4. [Build the Backend Executable](#4-build-the-backend-executable)
5. [Build the Flutter App](#5-build-the-flutter-app)
6. [Compile the Installer](#6-compile-the-installer)
7. [What the Installer Does on a Target Machine](#7-what-the-installer-does-on-a-target-machine)
8. [Installer Wizard Walkthrough](#8-installer-wizard-walkthrough)
9. [Verifying a Successful Install](#9-verifying-a-successful-install)
10. [Troubleshooting](#10-troubleshooting)
11. [Rebuilding After Code Changes](#11-rebuilding-after-code-changes)

---

## 1. Prerequisites

Install the following on the **developer/build machine** before starting.

| Tool | Version | Purpose |
|---|---|---|
| Node.js | 22 LTS | Build NestJS backend + `npm run build:sea` |
| Flutter SDK | 3.x | Build Windows kiosk app |
| Inno Setup 6 | 6.x | Compile the installer script |
| Git | any | Source control |

> **Note:** PostgreSQL, NSSM, and the VC++ Redistributable are **not** installed on the build machine — they are bundled inside the installer from local directories (see Section 2).

---

## 2. One-time Machine Setup

These steps only need to be done once per build machine.

### 2a. Install Inno Setup 6

Download and install from [jrsoftware.org/isdl.php](https://jrsoftware.org/isdl.php) or via winget:

```powershell
winget install JRSoftware.InnoSetup
```

The compiler will be at:
```
C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe
```

### 2b. Download NSSM (Service Manager)

NSSM manages the NestJS backend as a Windows service.

```powershell
# Create directory and download
New-Item -ItemType Directory -Force C:\nssm
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "$env:TEMP\nssm.zip"
Expand-Archive "$env:TEMP\nssm.zip" -DestinationPath "$env:TEMP\nssm-extracted" -Force
Copy-Item "$env:TEMP\nssm-extracted\nssm-2.24\win64\nssm.exe" "C:\nssm\nssm.exe"
```

Verify:
```powershell
C:\nssm\nssm.exe --version
```

### 2c. Download Portable PostgreSQL 16

The installer bundles only the PostgreSQL **binaries** (not the full installer, not pgAdmin).

1. Download **PostgreSQL 16 Windows x64** zip from [postgresql.org/download/windows](https://www.postgresql.org/download/windows/) (choose the "zip archive" option, not the installer).
2. Extract to `C:\pgsql\` so the structure looks like:

```
C:\pgsql\
  bin\       ← pg_ctl.exe, postgres.exe, psql.exe, initdb.exe, pg_isready.exe ...
  lib\       ← shared libraries
  share\     ← SQL definitions, timezone data
```

> Only `bin\`, `lib\`, and `share\` are bundled. Do not include `pgAdmin 4\` or `doc\` — they bloat the installer by ~130 MB.

Verify:
```powershell
C:\pgsql\bin\pg_ctl.exe --version
# Expected: pg_ctl (PostgreSQL) 16.x
```

---

## 3. Prepare Environment File

The installer bundles `.env.prod` as the backend's production `.env`.

```powershell
cd C:\Users\<you>\Documents\POS\be
copy .env.example .env.prod
```

Open `.env.prod` and fill in all required values. Use `.env.example` as reference for the full list of keys — do not copy values from it directly.

Key things to set:
- **Database password** — use a strong, unique password for production
- **JWT secrets** — generate two separate long random strings (e.g. `openssl rand -hex 48`)
- **PORT** — leave as `3000` unless you have a conflict

> `KIOSK_NO` in `.env.prod` is only used in **development** mode. In production, the kiosk number is read from `C:\POSKiosk\settings.txt` (written by the installer wizard). You can leave it set to any value in `.env.prod`.

> Never commit `.env.prod` to source control. It is listed in `.gitignore`.

---

## 4. Build the Backend Executable

This compiles the NestJS backend into a single standalone `POSBackend.exe` using Node.js SEA (Single Executable Application).

```powershell
cd C:\Users\<you>\Documents\POS\be

# Install dependencies (first time or after package changes)
npm install

# Build: NestJS compile → NCC bundle → inject into Node binary
npm run build:sea
```

**What it does internally (`build-exe.ts`):**
1. Cleans previous `dist_sea/` output
2. Bundles the app with `@vercel/ncc` into a single JS file
3. Generates a SEA blob (`sea-prep.blob`)
4. Copies the local Node.js binary as `POSBackend.exe`
5. Injects the blob into the binary via `postject`

**Output:** `be\POSBackend.exe` (~80–120 MB)

**Estimated time:** 2–5 minutes

---

## 5. Build the Flutter App

```powershell
cd C:\Users\<you>\Documents\POS\kiosk

flutter pub get
flutter build windows --release
```

**Output:** `kiosk\build\windows\x64\runner\Release\`

Key files the installer picks up from that directory:
- `pos_app.exe`
- `*.dll` (Flutter engine + plugin DLLs)
- `data\` (assets, fonts, app bundle)

**Estimated time:** 1–3 minutes

---

## 6. Compile the Installer

With both binaries built and prerequisites in place:

```powershell
$iscc = "C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
& $iscc "C:\Users\<you>\Documents\POS\be\installer\installer.iss"
```

**Output:** `be\installer\output\POSKiosk-Setup-1.0.0.exe` (~90 MB)

**Estimated time:** 2–4 minutes (LZMA2 compression is slow but produces a smaller file)

To change the version number, edit the top of `installer.iss`:
```iss
#define MyAppVersion "1.0.0"
```

---

## 7. What the Installer Does on a Target Machine

When `POSKiosk-Setup-1.0.0.exe` is run on a fresh Windows 10/11 x64 machine:

| Step | Action | Log file |
|---|---|---|
| 0 | Silently installs Visual C++ 2015–2022 Redistributable (skips if present) | — |
| 1 | Extracts all files to `C:\POSKiosk\` | — |
| 2 | Initializes PostgreSQL data directory at `C:\posdata\` | `C:\POSKiosk\logs\setup-postgres-install.log` |
| 3 | Configures `postgresql.conf` (port, logging, listen address) | same log |
| 4 | Grants `NT AUTHORITY\NetworkService` permissions on data + bin dirs | same log |
| 5 | Registers + starts `POSPostgres` Windows service via `pg_ctl` | same log |
| 6 | Waits up to 60 s for PostgreSQL to accept connections | same log |
| 7 | Creates `pos_db` database | same log |
| 8 | Runs all TypeORM migrations (79 migrations) | same log |
| 9 | Optionally seeds initial data (products, menus, users) | — |
| 10 | Installs `POSBackendService` via NSSM (auto-start) | `C:\POSKiosk\logs\install-backend-service-install.log` |
| 11 | Writes `C:\POSKiosk\settings.txt` with the kiosk number from wizard | — |

**Install directory:** `C:\POSKiosk\` (no spaces — required for the PostgreSQL service registration to work correctly on Windows SCM)

**Data directory:** `C:\posdata\` (no spaces — avoids postgres argument-splitting bug)

---

## 8. Installer Wizard Walkthrough

1. **UAC prompt** — approve Administrator access
2. **Welcome page** — click Next
3. **License** (if configured) — accept and Next
4. **Select destination** — defaults to `C:\POSKiosk`, leave as-is
5. **Select tasks** — choose:
   - ✅ Create desktop shortcut (recommended)
   - ☐ Seed initial data — **check this on first install only**; leave unchecked on upgrades to avoid duplicate data
6. **Kiosk Configuration** — enter a unique number (1–999) for this machine
   - This appears in all sales order numbers: `SO-001-2026-0001`
   - Each physical terminal should have a different number
7. **Ready to Install** — click Install
8. **Installation progress** — takes 1–3 minutes
9. **Finish** — optionally launch the kiosk app

**Default credentials (after seeding):**

Seed credentials are defined in `be/src/database/seeders/`. Check the users seeder for the default admin and user accounts. Change all passwords and PINs immediately after first login on any production machine.

---

## 9. Verifying a Successful Install

Open PowerShell as Administrator on the target machine:

```powershell
# Check both services are running
Get-Service POSPostgres, POSBackendService | Format-Table Name, Status

# Check PostgreSQL is accepting connections
& "C:\POSKiosk\pgsql\bin\pg_isready.exe" -h 127.0.0.1 -p 5432

# Check backend is responding
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/health" -UseBasicParsing
# Expected: 401 Unauthorized (means the endpoint exists and auth is active)

# Check kiosk number was written
Get-Content "C:\POSKiosk\settings.txt"
# Expected: kiosk.no=<number you entered>
```

---

## 10. Troubleshooting

### App shows "no internet connection"

The Flutter app can't reach the backend. Check in order:

```powershell
# 1. Are both services running?
Get-Service POSPostgres, POSBackendService

# 2. Is PostgreSQL listening?
& "C:\POSKiosk\pgsql\bin\pg_isready.exe" -h 127.0.0.1 -p 5432

# 3. Check setup log for what failed
Get-Content "C:\POSKiosk\logs\setup-postgres-install.log" | Select-Object -Last 40

# 4. Check backend error log
Get-Content "C:\POSKiosk\logs\backend-error.log" | Select-Object -Last 30
```

### Internal server error on payment / sales order creation

The `settings.txt` file may be missing:

```powershell
# Check it exists
Get-Content "C:\POSKiosk\settings.txt"
# If missing, create it (replace 1 with your kiosk number):
"kiosk.no=1" | Set-Content "C:\POSKiosk\settings.txt" -Encoding Ascii
# Then restart the backend
Restart-Service POSBackendService
```

### Database tables are missing (42P01 errors)

Migrations didn't run. Run them manually (elevated PowerShell):

```powershell
Set-Location "C:\POSKiosk\backend"
& "C:\POSKiosk\backend\POSBackend.exe" --migrate
Restart-Service POSBackendService
```

### POSPostgres service not registered

The install path had spaces (old install). Reinstall using the current installer which installs to `C:\POSKiosk`.

### Log file locations

| Log | Contents |
|---|---|
| `C:\POSKiosk\logs\setup-postgres-install.log` | DB init, service registration, migrations |
| `C:\POSKiosk\logs\install-backend-service-install.log` | NSSM service install + health check |
| `C:\POSKiosk\logs\backend-output.log` | Live NestJS stdout (NSSM-captured) |
| `C:\POSKiosk\logs\backend-error.log` | Live NestJS stderr / errors |
| `C:\posdata\log\postgresql.log` | PostgreSQL server log |

---

## 11. Rebuilding After Code Changes

| Changed | Command | Then recompile installer? |
|---|---|---|
| NestJS backend source | `cd be && npm run build:sea` | Yes |
| Flutter kiosk source | `cd kiosk && flutter build windows --release` | Yes |
| `.env.prod` values | Edit file | Yes |
| `installer.iss` or scripts | Edit files | Yes |
| Only `installer.iss` / scripts | — | Yes (no need to rebuild binaries) |

**Full rebuild sequence:**

```powershell
# 1. Build backend
cd C:\Users\<you>\Documents\POS\be
npm run build:sea

# 2. Build Flutter app
cd C:\Users\<you>\Documents\POS\kiosk
flutter build windows --release

# 3. Compile installer
$iscc = "C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
& $iscc "C:\Users\<you>\Documents\POS\be\installer\installer.iss"

# Output: be\installer\output\POSKiosk-Setup-1.0.0.exe
```
