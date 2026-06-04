param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$nssm    = "$AppDir\nssm\nssm.exe"
$beExe   = "$AppDir\backend\POSBackend.exe"
$logs    = "$AppDir\logs"
$svcName = "POSBackendService"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\install-backend-service-install.log" -Force

try {
    Write-Host "AppDir  : $AppDir"
    Write-Host "NSSM    : $nssm"
    Write-Host "Backend : $beExe"

    foreach ($f in @($nssm, $beExe)) {
        if (!(Test-Path $f)) {
            Write-Error "Required file not found: $f"
            exit 1
        }
    }

    # ── Remove existing service if present ───────────────────────────────
    $existing = Get-Service $svcName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing existing $svcName..."
        & $nssm stop   $svcName 2>&1 | Write-Host
        Start-Sleep -Seconds 2
        & $nssm remove $svcName confirm 2>&1 | Write-Host
        Start-Sleep -Seconds 2
    }

    # ── Install via NSSM ─────────────────────────────────────────────────
    Write-Host "Installing $svcName via NSSM..."
    & $nssm install $svcName $beExe
    & $nssm set $svcName AppDirectory   "$AppDir\backend"
    & $nssm set $svcName Start          SERVICE_AUTO_START
    & $nssm set $svcName AppStdout      "$logs\backend-output.log"
    & $nssm set $svcName AppStderr      "$logs\backend-error.log"
    & $nssm set $svcName AppRotateFiles 1
    & $nssm set $svcName AppRotateBytes 10485760

    # ── Start the service ─────────────────────────────────────────────────
    Write-Host "Starting $svcName..."
    & $nssm start $svcName
    Start-Sleep -Seconds 5

    $svc = Get-Service $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "Service status: $($svc.Status)"
    } else {
        Write-Error "Service $svcName not found after install."
        exit 1
    }

    # ── Verify backend health (up to 60s) ────────────────────────────────
    # Uses /health/live (memory-only check) so a slow DB connection doesn't
    # block the installer from confirming the process is up and listening.
    Write-Host "Waiting for backend to be ready (up to 60s)..."
    $healthy = $false
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 1
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:3000/health/live" `
                     -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $healthy = $true; break }
        } catch { }
        if ($i % 10 -eq 0) { Write-Host "  still waiting... ($i/60)" }
    }

    if ($healthy) {
        Write-Host "Backend is up and accepting requests."
    } else {
        Write-Host "WARNING: Backend did not respond within 60s."
        Write-Host "Check $logs\backend-error.log for details."
        Write-Host "The kiosk may show 'No Connection' until the backend finishes starting."
    }

    Write-Host "install-backend-service.ps1 completed successfully."

} catch {
    Write-Error "install-backend-service.ps1 failed: $_"
    exit 1
} finally {
    Stop-Transcript
}
