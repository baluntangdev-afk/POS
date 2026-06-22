param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Starts the POS services in dependency order: PostgreSQL first, then (once it
# accepts connections) the NestJS backend. Use this after stop-services.ps1, or
# any time the services are stopped but still registered. It does NOT register
# or repair services — for a broken/missing service use recover-services.bat.

$ErrorActionPreference = 'Continue'
$pgBin = "$AppDir\pgsql\bin"
$nssm  = "$AppDir\nssm\nssm.exe"
$logs  = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

try { Start-Transcript -Path "$logs\start-services.log" -Force | Out-Null } catch { }

Write-Host "AppDir : $AppDir"

# Polls until the named service reports Running, or the timeout elapses.
function Wait-ServiceRunning {
    param([string]$Name, [int]$TimeoutSecs = 30)
    for ($i = 0; $i -lt $TimeoutSecs; $i++) {
        $svc = Get-Service $Name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') { return $true }
        Start-Sleep -Seconds 1
    }
    $svc = Get-Service $Name -ErrorAction SilentlyContinue
    return ($svc -and $svc.Status -eq 'Running')
}

# -- 1. Start the PostgreSQL service --------------------------------------
if (Get-Service "POSPostgres" -ErrorAction SilentlyContinue) {
    Write-Host "Starting POSPostgres..."
    & sc.exe start POSPostgres 2>&1 | Write-Host
    if (Wait-ServiceRunning "POSPostgres" 30) {
        Write-Host "POSPostgres is running."
    } else {
        Write-Error "POSPostgres did not reach Running state within 30s. See $logs\start-services.log."
        try { Stop-Transcript | Out-Null } catch { }
        exit 1
    }
} else {
    Write-Error "POSPostgres service is not installed. Run recover-services.bat to (re)install it."
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}

# -- 2. Wait for PostgreSQL to accept connections -------------------------
# The service reaching "Running" does not mean it is accepting TCP connections
# yet; start the backend only once pg_isready confirms it is reachable, so the
# backend connects on its first attempt instead of failing/retrying.
if (Test-Path "$pgBin\pg_isready.exe") {
    Write-Host "Waiting for PostgreSQL to accept connections (up to 60s)..."
    $ready = $false
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 1
        & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p 5432 -q
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        if ($i % 5 -eq 0) { Write-Host "  still waiting... ($i/60)" }
    }
    if (!$ready) {
        Write-Error "PostgreSQL did not become ready within 60s. See $logs\start-services.log."
        try { Stop-Transcript | Out-Null } catch { }
        exit 1
    }
    Write-Host "PostgreSQL is ready."
}

# -- 3. Start the NestJS backend service ----------------------------------
if (Get-Service "POSBackendService" -ErrorAction SilentlyContinue) {
    Write-Host "Starting POSBackendService..."
    if (Test-Path $nssm) {
        & $nssm start POSBackendService 2>&1 | Write-Host
    } else {
        & sc.exe start POSBackendService 2>&1 | Write-Host
    }
    if (Wait-ServiceRunning "POSBackendService" 30) {
        Write-Host "POSBackendService is running."
    } else {
        Write-Warning "POSBackendService did not reach Running state within 30s. See $logs\backend-error.log."
    }
} else {
    Write-Error "POSBackendService is not installed. Run recover-services.bat to (re)install it."
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}

# -- 4. Report final state ------------------------------------------------
$pg = Get-Service "POSPostgres"       -ErrorAction SilentlyContinue
$be = Get-Service "POSBackendService" -ErrorAction SilentlyContinue
Write-Host ("POSPostgres       : " + $(if ($pg) { $pg.Status } else { 'not installed' }))
Write-Host ("POSBackendService : " + $(if ($be) { $be.Status } else { 'not installed' }))
Write-Host "You can now launch the POS Kiosk."

try { Stop-Transcript | Out-Null } catch { }
