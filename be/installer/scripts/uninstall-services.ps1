param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$nssm   = "$AppDir\nssm\nssm.exe"
$pgBin  = "$AppDir\pgsql\bin"

# ── Stop and remove backend service (NSSM) ────────────────────────────
$beSvc = Get-Service "POSBackendService" -ErrorAction SilentlyContinue
if ($beSvc) {
    Write-Host "Removing POSBackendService..."
    & $nssm stop   POSBackendService 2>&1 | Write-Host
    Start-Sleep -Seconds 3
    & $nssm remove POSBackendService confirm 2>&1 | Write-Host
} else {
    Write-Host "POSBackendService not found, skipping."
}

# ── Stop and unregister PostgreSQL service ────────────────────────────
$pgSvc = Get-Service "POSPostgres" -ErrorAction SilentlyContinue
if ($pgSvc) {
    Write-Host "Stopping POSPostgres..."
    Stop-Service "POSPostgres" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 4
    Write-Host "Unregistering POSPostgres..."
    & "$pgBin\pg_ctl.exe" unregister -N POSPostgres 2>&1 | Write-Host
} else {
    Write-Host "POSPostgres not found, skipping."
}

Write-Host "Services removed."
