param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$pgBin   = "$AppDir\pgsql\bin"
$backend = "$AppDir\backend\POSBackend.exe"
$logs    = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\run-migrations-install.log" -Force

try {
    Write-Host "AppDir  : $AppDir"
    Write-Host "Backend : $backend"

    if (!(Test-Path $backend)) {
        Write-Error "POSBackend.exe not found at: $backend"
        exit 1
    }

    # ── Wait for PostgreSQL to be ready ───────────────────────────────────
    Write-Host "Waiting for PostgreSQL to be ready (up to 60s)..."
    $ready = $false
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 1
        & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p 5432 -q
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        if ($i % 5 -eq 0) { Write-Host "  still waiting... ($i/60)" }
    }

    if (!$ready) {
        Write-Error "PostgreSQL not ready after 60s — cannot run migrations."
        exit 1
    }
    Write-Host "PostgreSQL is ready."

    # ── Run migrations ────────────────────────────────────────────────────
    Write-Host "Running TypeORM migrations..."
    Set-Location "$AppDir\backend"
    & $backend --migrate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Migrations failed (exit $LASTEXITCODE)"
        exit 1
    }

    Write-Host "run-migrations.ps1 completed successfully."

} catch {
    Write-Error "run-migrations.ps1 failed: $_"
    exit 1
} finally {
    Stop-Transcript
}
