# Run this as Administrator to repair the currently installed instance.
# Handles both old (C:\Program Files\POS Kiosk) and new (C:\POSKiosk) install paths.

$appDir = if (Test-Path "C:\POSKiosk\pgsql\bin\pg_ctl.exe") { "C:\POSKiosk" }
          elseif (Test-Path "C:\Program Files\POS Kiosk\pgsql\bin\pg_ctl.exe") { "C:\Program Files\POS Kiosk" }
          else { $null }

if (!$appDir) {
    Write-Error "Could not find POS Kiosk installation. Check C:\POSKiosk or 'C:\Program Files\POS Kiosk'."
    exit 1
}

Write-Host "Found installation at: $appDir"
& "$appDir\scripts\setup-postgres.ps1" -AppDir $appDir
if ($LASTEXITCODE -ne 0) { Write-Error "setup-postgres failed"; exit 1 }

Write-Host "`nRestarting backend service..."
Restart-Service POSBackendService -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

Write-Host "`n=== Final status ==="
Get-Service POSPostgres, POSBackendService | Format-Table Name, Status

Write-Host "`n=== Health check ==="
try {
    $r = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "OK - $($r.StatusCode): $($r.Content)"
} catch {
    Write-Host "Health check failed: $_"
    Write-Host "Check logs at: $appDir\logs\"
}
