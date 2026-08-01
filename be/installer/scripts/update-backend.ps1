param(
    [string]$AppDir    = "C:\POSKiosk",
    [string]$ExePath   = "",         # path to new POSBackend.exe; defaults to AppDir\backend\POSBackend.exe in-place
    [string]$PublicDir = ""          # optional: path to new static assets (be\public) to sync into AppDir\backend\public
)

$ErrorActionPreference = "Stop"
$backend = "$AppDir\backend\POSBackend.exe"
$svc     = "POSBackendService"
$logs    = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\update-backend.log" -Force

try {
    Write-Host "AppDir  : $AppDir"
    Write-Host "ExePath : $(if ($ExePath) { $ExePath } else { '(in-place)' })"

    # ── Stop service ─────────────────────────────────────────────────────────
    Write-Host "Stopping $svc..."
    $svcObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($svcObj -and $svcObj.Status -ne 'Stopped') {
        Stop-Service -Name $svc -Force
        $svcObj.WaitForStatus('Stopped', '00:00:30')
        Write-Host "$svc stopped."
    } else {
        Write-Host "$svc was already stopped."
    }

    # ── Swap exe if a new one was provided ────────────────────────────────────
    if ($ExePath -ne "") {
        if (!(Test-Path $ExePath)) {
            Write-Error "New exe not found at: $ExePath"
            exit 1
        }
        Write-Host "Copying new exe to $backend..."
        Copy-Item -Path $ExePath -Destination $backend -Force
        Write-Host "Exe replaced."
    }

    if (!(Test-Path $backend)) {
        Write-Error "POSBackend.exe not found at: $backend"
        exit 1
    }

    # ── Sync static assets (product images) if a source was provided ──────────
    # The backend serves these from {AppDir}\backend\public at /static/* (see
    # main.ts useStaticAssets). The exe does NOT bundle them, so an exe-only
    # update would otherwise leave images missing. Merge-copy: overwrites shipped
    # files and adds new ones; admin-added files not in the source are preserved.
    if ($PublicDir -ne "") {
        if (!(Test-Path $PublicDir)) {
            Write-Error "PublicDir not found at: $PublicDir"
            exit 1
        }
        $destPublic = "$AppDir\backend\public"
        Write-Host "Syncing static assets from $PublicDir to $destPublic..."
        if (!(Test-Path $destPublic)) { New-Item -ItemType Directory -Force $destPublic | Out-Null }
        Copy-Item -Path "$PublicDir\*" -Destination $destPublic -Recurse -Force
        Write-Host "Static assets synced."
    }

    # ── Run migrations ────────────────────────────────────────────────────────
    Write-Host "Running migrations..."
    Set-Location "$AppDir\backend"
    & $backend --migrate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Migrations failed (exit $LASTEXITCODE)"
        exit 1
    }
    Write-Host "Migrations complete."

    # ── Restart service ───────────────────────────────────────────────────────
    Write-Host "Starting $svc..."
    Start-Service -Name $svc
    Write-Host "$svc started."

    Write-Host "update-backend.ps1 completed successfully."

} catch {
    Write-Error "update-backend.ps1 failed: $_"
    # Try to restart service even if something went wrong
    Start-Service -Name $svc -ErrorAction SilentlyContinue
    exit 1
} finally {
    Stop-Transcript
}
