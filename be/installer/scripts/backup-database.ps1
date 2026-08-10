param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Daily backup of pos_db + config, run unattended via the "POSKioskDatabaseBackup"
# Scheduled Task (see register-backup-task.ps1). Safe to run manually too, e.g. before
# an uninstall/reinstall. See docs/superpowers/specs/2026-08-10-backup-strategy-design.md
# for the full strategy this implements.

$pgBin      = "$AppDir\pgsql\bin"
$backupDir  = "$AppDir\Backups"
$configRoot = "$backupDir\config"
$logs       = "$AppDir\logs"
$retentionDays = 30

if (!(Test-Path $logs))      { New-Item -ItemType Directory -Force $logs      | Out-Null }
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Force $backupDir | Out-Null }
if (!(Test-Path $configRoot)) { New-Item -ItemType Directory -Force $configRoot | Out-Null }

Start-Transcript -Path "$logs\backup-database.log" -Append

try {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Write-Host "=== backup-database.ps1 starting: $timestamp ==="
    Write-Host "AppDir     : $AppDir"
    Write-Host "backupDir  : $backupDir"

    if (!(Test-Path "$pgBin\pg_dump.exe")) {
        Write-Error "Missing binary: $pgBin\pg_dump.exe"
        exit 1
    }

    # -- 1. Dump the database (custom format: compressed, restorable via pg_restore) --
    $dumpFile = "$backupDir\pos_db_$timestamp.dump"
    Write-Host "Dumping pos_db to $dumpFile..."
    $env:PGPASSWORD = "postgres"
    & "$pgBin\pg_dump.exe" -U postgres -h 127.0.0.1 -p 5432 -Fc -f $dumpFile pos_db
    if ($LASTEXITCODE -ne 0 -or !(Test-Path $dumpFile)) {
        Write-Error "pg_dump failed (exit $LASTEXITCODE)."
        exit 1
    }
    Write-Host "Database dump complete: $((Get-Item $dumpFile).Length) bytes."

    # -- 2. Copy config alongside the dump ---------------------------------
    # A restored database with no .env (JWT secrets, DB credentials) can't be brought
    # back up standalone, so each run's config snapshot lives next to its dump.
    $configDir = "$configRoot\$timestamp"
    New-Item -ItemType Directory -Force $configDir | Out-Null
    $envFile = "$AppDir\backend\.env"
    if (Test-Path $envFile) {
        Copy-Item $envFile "$configDir\.env"
        Write-Host "Copied .env."
    } else {
        Write-Warning ".env not found at $envFile, skipping."
    }
    $settingsFile = "$AppDir\settings.txt"
    if (Test-Path $settingsFile) {
        Copy-Item $settingsFile "$configDir\settings.txt"
        Write-Host "Copied settings.txt."
    } else {
        Write-Warning "settings.txt not found at $settingsFile, skipping."
    }

    # -- 3. Optional secondary copy (USB / LAN share / cloud-synced folder) ------------
    # A local-only backup dies with the machine it's protecting -- the realistic failure
    # mode for a single physical terminal (theft, fire, disk failure). Opt in per store by
    # writing the target path (a drive letter or UNC path) into this file. Left blank/
    # absent by default: no secondary target is assumed, and the local backup above still
    # succeeds either way.
    $secondaryTargetFile = "$backupDir\secondary-target.txt"
    if (Test-Path $secondaryTargetFile) {
        $secondaryTarget = (Get-Content $secondaryTargetFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ([string]::IsNullOrWhiteSpace($secondaryTarget)) {
            Write-Host "secondary-target.txt is empty, skipping secondary copy."
        } elseif (!(Test-Path $secondaryTarget)) {
            Write-Warning "Secondary target not reachable: $secondaryTarget (skipping secondary copy; local backup already succeeded above)."
        } else {
            try {
                Write-Host "Copying to secondary target: $secondaryTarget..."
                Copy-Item $dumpFile "$secondaryTarget\" -Force
                Copy-Item $configDir "$secondaryTarget\config_$timestamp" -Recurse -Force
                Write-Host "Secondary copy complete."
            } catch {
                Write-Warning "Secondary copy failed: $_ (non-fatal; local backup already succeeded above)."
            }
        }
    } else {
        Write-Host "No secondary-target.txt found at $secondaryTargetFile -- local-only backup (see be/installer/README.md to configure a USB/LAN/cloud target)."
    }

    # -- 4. Retention: delete dumps + config snapshots older than 30 days --
    $cutoff = (Get-Date).AddDays(-$retentionDays)
    $oldDumps = Get-ChildItem "$backupDir\pos_db_*.dump" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($f in $oldDumps) {
        Write-Host "Deleting expired backup: $($f.Name)"
        Remove-Item $f.FullName -Force
    }
    $oldConfigDirs = Get-ChildItem $configRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($d in $oldConfigDirs) {
        Write-Host "Deleting expired config snapshot: $($d.Name)"
        Remove-Item $d.FullName -Recurse -Force
    }

    Write-Host "=== backup-database.ps1 completed successfully ==="

} catch {
    Write-Error ('backup-database.ps1 failed: ' + $_.ToString())
    exit 1
} finally {
    Stop-Transcript
}
