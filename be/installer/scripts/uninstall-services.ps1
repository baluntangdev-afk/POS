param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Runs from installer.iss [UninstallRun], BEFORE Inno deletes the installed
# files (so nssm.exe / pg_ctl.exe under $AppDir are still available here).
# Goal: leave NO trace of the two Windows services. A half-removed service
# (e.g. POSPostgres still registered after C:\posdata is deleted) is what
# causes the next install to fight an orphaned, perpetually-failing service.

$ErrorActionPreference = 'Continue'
$nssm  = "$AppDir\nssm\nssm.exe"
$pgBin = "$AppDir\pgsql\bin"

# Log to TEMP, not $AppDir\logs -- the install dir is deleted right after this
# runs, so a log under it would vanish. TEMP survives for post-mortem.
$log = "$env:TEMP\pos-uninstall-services.log"
try { Start-Transcript -Path $log -Force | Out-Null } catch { }

Write-Host "AppDir : $AppDir"

# Returns $true once the service no longer exists, or after the timeout.
function Wait-ServiceGone {
    param([string]$Name, [int]$TimeoutSecs = 20)
    for ($i = 0; $i -lt $TimeoutSecs; $i++) {
        if (-not (Get-Service $Name -ErrorAction SilentlyContinue)) { return $true }
        Start-Sleep -Seconds 1
    }
    return (-not (Get-Service $Name -ErrorAction SilentlyContinue))
}

# -- 0. Stop the kiosk app so it can't hold file locks ---------------------
Write-Host "Stopping kiosk app (pos_app.exe)..."
taskkill /F /IM pos_app.exe /T 2>&1 | Write-Host

# -- 1. Stop + remove the NestJS backend service (NSSM) --------------------
if (Get-Service "POSBackendService" -ErrorAction SilentlyContinue) {
    Write-Host "Removing POSBackendService..."
    if (Test-Path $nssm) {
        & $nssm stop   POSBackendService 2>&1 | Write-Host
        Start-Sleep -Seconds 3
        & $nssm remove POSBackendService confirm 2>&1 | Write-Host
    } else {
        & sc.exe stop   POSBackendService 2>&1 | Write-Host
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 2
    # Fallback: if it is still registered, force-delete via SCM.
    if (Get-Service "POSBackendService" -ErrorAction SilentlyContinue) {
        Write-Host "POSBackendService still present, deleting via sc.exe..."
        & sc.exe delete POSBackendService 2>&1 | Write-Host
    }
    Wait-ServiceGone "POSBackendService" 15 | Out-Null
} else {
    Write-Host "POSBackendService not found, skipping."
}

# -- 2. Stop + unregister the PostgreSQL service --------------------------
if (Get-Service "POSPostgres" -ErrorAction SilentlyContinue) {
    Write-Host "Stopping POSPostgres..."
    & sc.exe stop POSPostgres 2>&1 | Write-Host
    Start-Sleep -Seconds 4
    # Kill any lingering postgres.exe so unregister/delete cannot be blocked.
    Get-Process postgres -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Write-Host "Unregistering POSPostgres..."
    if (Test-Path "$pgBin\pg_ctl.exe") {
        & "$pgBin\pg_ctl.exe" unregister -N POSPostgres 2>&1 | Write-Host
        Start-Sleep -Seconds 2
    }
    # Fallback: if pg_ctl could not remove it, force-delete via SCM.
    if (Get-Service "POSPostgres" -ErrorAction SilentlyContinue) {
        Write-Host "POSPostgres still present, deleting via sc.exe..."
        & sc.exe delete POSPostgres 2>&1 | Write-Host
    }
    Wait-ServiceGone "POSPostgres" 15 | Out-Null
} else {
    Write-Host "POSPostgres not found, skipping."
}

# -- 3. Revert kiosk auto-logon, if configured-autologon.ps1 set it up ----
$winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if ((Get-ItemProperty -Path $winlogon -Name DefaultUserName -ErrorAction SilentlyContinue).DefaultUserName -eq "POSKiosk") {
    Write-Host "Reverting kiosk auto-logon registry settings..."
    Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon" -Value "0" -Type String
    Remove-ItemProperty -Path $winlogon -Name "DefaultPassword" -ErrorAction SilentlyContinue
}
if (Get-LocalUser -Name "POSKiosk" -ErrorAction SilentlyContinue) {
    Write-Host "Removing POSKiosk local account..."
    Remove-LocalUser -Name "POSKiosk" -ErrorAction SilentlyContinue
}

# -- 3b. Remove the daily database backup Scheduled Task -------------------
if (schtasks /Query /TN "POSKioskDatabaseBackup" 2>$null) {
    Write-Host "Removing POSKioskDatabaseBackup scheduled task..."
    schtasks /Delete /TN "POSKioskDatabaseBackup" /F 2>&1 | Write-Host
} else {
    Write-Host "POSKioskDatabaseBackup scheduled task not found, skipping."
}

# -- 4. Verify -----------------------------------------------------------
$beLeft = Get-Service "POSBackendService" -ErrorAction SilentlyContinue
$pgLeft = Get-Service "POSPostgres"       -ErrorAction SilentlyContinue
if ($beLeft -or $pgLeft) {
    Write-Warning "Service teardown incomplete. Backend left: $([bool]$beLeft); Postgres left: $([bool]$pgLeft)."
} else {
    Write-Host "Both services removed cleanly."
}

try { Stop-Transcript | Out-Null } catch { }
