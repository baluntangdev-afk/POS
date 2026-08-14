param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir,

    [Parameter(Mandatory=$true)]
    [string]$DumpFile
)

# Restores pos_db from a backup-database.ps1 dump. DESTRUCTIVE: drops and recreates every
# object in pos_db before restoring, so run this only when you actually intend to replace
# the current database (disaster recovery, or restoring onto a freshly reinstalled machine).
#
# Usage (as administrator):
#   .\restore-database.ps1 -AppDir "C:\POSKiosk" -DumpFile "C:\POSKiosk\Backups\pos_db_20260810_020000.dump"
#
# If a config snapshot with a matching timestamp exists under Backups\config\, this also
# offers to restore .env / settings.txt from it.

$ErrorActionPreference = 'Stop'
$pgBin = "$AppDir\pgsql\bin"
$logs  = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\restore-database.log" -Append

try {
    Write-Host "AppDir   : $AppDir"
    Write-Host "DumpFile : $DumpFile"

    if (!(Test-Path "$pgBin\pg_restore.exe")) {
        Write-Error "Missing binary: $pgBin\pg_restore.exe"
        exit 1
    }
    if (!(Test-Path $DumpFile)) {
        Write-Error "Dump file not found: $DumpFile"
        exit 1
    }

    Write-Host ""
    Write-Host "WARNING: this will DROP and recreate every object in pos_db, replacing all" -ForegroundColor Yellow
    Write-Host "current data with the contents of the dump file above." -ForegroundColor Yellow
    $confirm = Read-Host "Type YES to continue"
    if ($confirm -ne 'YES') {
        Write-Host "Aborted."
        exit 1
    }

    # -- 1. Stop the backend so it isn't holding connections/writing during restore ----
    Write-Host "Stopping POSBackendService..."
    sc.exe stop POSBackendService 2>&1 | Out-Null
    Start-Sleep -Seconds 3

    # -- 2. Restore (Postgres itself must be running for pg_restore to connect) --------
    $env:PGPASSWORD = "postgres"
    Write-Host "Restoring pos_db from $DumpFile..."
    & "$pgBin\pg_restore.exe" -U postgres -h 127.0.0.1 -p 5432 -d pos_db --clean --if-exists $DumpFile
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "pg_restore reported exit code $LASTEXITCODE. This is sometimes non-fatal" `
            "(e.g. warnings about objects that didn't exist to drop) -- check the log above" `
            "and verify the data before trusting the restore."
    } else {
        Write-Host "Database restore complete."
    }

    # -- 3. Offer to restore the matching config snapshot ------------------------------
    $timestamp = [IO.Path]::GetFileNameWithoutExtension($DumpFile) -replace '^pos_db_', ''
    $configDir = "$AppDir\Backups\config\$timestamp"
    if (Test-Path $configDir) {
        Write-Host ""
        $restoreConfig = Read-Host "Matching config snapshot found at $configDir. Restore .env/settings.txt too? (y/N)"
        if ($restoreConfig -eq 'y' -or $restoreConfig -eq 'Y') {
            if (Test-Path "$configDir\.env") {
                Copy-Item "$configDir\.env" "$AppDir\backend\.env" -Force
                Write-Host "Restored .env."
            }
            if (Test-Path "$configDir\settings.txt") {
                Copy-Item "$configDir\settings.txt" "$AppDir\settings.txt" -Force
                Write-Host "Restored settings.txt."
            }
        }
    } else {
        Write-Host "No matching config snapshot found at $configDir (dump may have been taken manually); skipping."
    }

    # -- 4. Restart the backend ---------------------------------------------------------
    Write-Host "Starting POSBackendService..."
    sc.exe start POSBackendService 2>&1 | Out-Null

    Write-Host "restore-database.ps1 completed. Verify with: Invoke-WebRequest http://localhost:3000/api/v1/health/ready"

} catch {
    Write-Error ('restore-database.ps1 failed: ' + $_.ToString())
    exit 1
} finally {
    Stop-Transcript
}
