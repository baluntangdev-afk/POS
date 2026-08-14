param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Registers a daily Windows Scheduled Task that runs backup-database.bat unattended.
# Idempotent: safe to re-run on every install/upgrade (removes and re-creates the task
# so a changed AppDir or schedule is always picked up).

$taskName = "POSKioskDatabaseBackup"
$logs     = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\register-backup-task-install.log" -Force

try {
    Write-Host "AppDir   : $AppDir"
    Write-Host "taskName : $taskName"

    $scriptPath = "$AppDir\scripts\backup-database.bat"
    if (!(Test-Path $scriptPath)) {
        Write-Error "Missing script: $scriptPath"
        exit 1
    }

    # -- 1. Remove any existing registration (idempotent) ------------------
    schtasks /Query /TN $taskName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Removing existing $taskName task..."
        schtasks /Delete /TN $taskName /F 2>&1 | Write-Host
    }

    # -- 2. Register: daily at 2:00 AM, as SYSTEM (runs whether or not a --
    #    user is logged in), highest privilege (needed to read C:\posdata
    #    and the backend's .env).
    $trCommand = '"' + $scriptPath + '" "' + $AppDir + '"'
    Write-Host "Registering $taskName -> $trCommand"
    schtasks /Create /TN $taskName /TR $trCommand /SC DAILY /ST 02:00 `
        /RU "SYSTEM" /RL HIGHEST /F 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Error "schtasks /Create failed (exit $LASTEXITCODE)."
        exit 1
    }

    # -- 3. Verify -----------------------------------------------------------
    schtasks /Query /TN $taskName 2>&1 | Write-Host
    if ($LASTEXITCODE -eq 0) {
        Write-Host "register-backup-task.ps1 completed successfully."
    } else {
        Write-Error "Task registration could not be verified."
        exit 1
    }

} catch {
    Write-Error ('register-backup-task.ps1 failed: ' + $_.ToString())
    exit 1
} finally {
    Stop-Transcript
}
