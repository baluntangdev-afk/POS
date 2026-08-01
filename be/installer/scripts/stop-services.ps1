param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Stops the POS services WITHOUT removing/unregistering them, so they can be
# started again later (via the Services console, `sc start`, or a reboot if set
# to auto-start). Use this for maintenance — e.g. freeing port 5432, taking a
# cold database backup, or replacing POSBackend.exe — not for uninstalling.
# To remove the services entirely, use uninstall-services.ps1 instead.

$ErrorActionPreference = 'Continue'
$nssm  = "$AppDir\nssm\nssm.exe"
$logs  = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

try { Start-Transcript -Path "$logs\stop-services.log" -Force | Out-Null } catch { }

Write-Host "AppDir : $AppDir"

# Polls until the named service reports Stopped (or no longer exists), or the
# timeout elapses. Returns $true when the service is stopped/absent.
function Wait-ServiceStopped {
    param([string]$Name, [int]$TimeoutSecs = 30)
    for ($i = 0; $i -lt $TimeoutSecs; $i++) {
        $svc = Get-Service $Name -ErrorAction SilentlyContinue
        if (-not $svc) { return $true }
        if ($svc.Status -eq 'Stopped') { return $true }
        Start-Sleep -Seconds 1
    }
    $svc = Get-Service $Name -ErrorAction SilentlyContinue
    return ((-not $svc) -or ($svc.Status -eq 'Stopped'))
}

# -- 0. Stop the kiosk app so it stops hitting the backend -----------------
Write-Host "Stopping kiosk app (pos_app.exe)..."
taskkill /F /IM pos_app.exe /T 2>&1 | Write-Host

# -- 1. Stop the NestJS backend service (NSSM) ----------------------------
if (Get-Service "POSBackendService" -ErrorAction SilentlyContinue) {
    Write-Host "Stopping POSBackendService..."
    if (Test-Path $nssm) {
        & $nssm stop POSBackendService 2>&1 | Write-Host
    } else {
        & sc.exe stop POSBackendService 2>&1 | Write-Host
    }
    if (Wait-ServiceStopped "POSBackendService" 20) {
        Write-Host "POSBackendService stopped."
    } else {
        Write-Warning "POSBackendService did not stop within 20s."
    }
} else {
    Write-Host "POSBackendService not found, skipping."
}

# -- 2. Stop the PostgreSQL service ---------------------------------------
if (Get-Service "POSPostgres" -ErrorAction SilentlyContinue) {
    Write-Host "Stopping POSPostgres..."
    & sc.exe stop POSPostgres 2>&1 | Write-Host
    if (Wait-ServiceStopped "POSPostgres" 30) {
        Write-Host "POSPostgres stopped."
    } else {
        # PostgreSQL can be slow to release; report but don't force-kill here.
        # Forcibly killing postgres.exe risks leaving a stale postmaster.pid.
        Write-Warning "POSPostgres did not stop within 30s. Check $logs\stop-services.log."
    }
} else {
    Write-Host "POSPostgres not found, skipping."
}

# -- 3. Report final state ------------------------------------------------
$be = Get-Service "POSBackendService" -ErrorAction SilentlyContinue
$pg = Get-Service "POSPostgres"       -ErrorAction SilentlyContinue
Write-Host ("POSBackendService : " + $(if ($be) { $be.Status } else { 'not installed' }))
Write-Host ("POSPostgres       : " + $(if ($pg) { $pg.Status } else { 'not installed' }))
Write-Host "Services remain registered and can be started again."

try { Stop-Transcript | Out-Null } catch { }
