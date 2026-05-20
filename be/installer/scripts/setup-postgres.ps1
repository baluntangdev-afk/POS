param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$pgBin  = "$AppDir\pgsql\bin"
$pgData = "C:\posdata"
$logs   = "$AppDir\logs"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

Start-Transcript -Path "$logs\setup-postgres-install.log" -Force

try {
    Write-Host "AppDir   : $AppDir"
    Write-Host "pgBin    : $pgBin"
    Write-Host "pgData   : $pgData"

    # ── 1. Verify binaries are present ───────────────────────────────────
    foreach ($exe in @("initdb.exe","pg_ctl.exe","pg_isready.exe","postgres.exe","psql.exe")) {
        if (!(Test-Path "$pgBin\$exe")) {
            Write-Error "Missing binary: $pgBin\$exe"
            exit 1
        }
    }
    Write-Host "All required binaries present."

    # ── 2. Initialize data directory (idempotent) ─────────────────────────
    if (!(Test-Path "$pgData\PG_VERSION")) {
        Write-Host "Initializing PostgreSQL data directory at $pgData..."
        New-Item -ItemType Directory -Force $pgData | Out-Null

        "postgres" | Set-Content "$env:TEMP\pgpass.txt" -Encoding Ascii -NoNewline
        & "$pgBin\initdb.exe" -D $pgData -U postgres -A scram-sha-256 `
            --pwfile="$env:TEMP\pgpass.txt" --encoding=UTF8 --locale=C
        $initExit = $LASTEXITCODE
        Remove-Item "$env:TEMP\pgpass.txt" -Force -ErrorAction SilentlyContinue

        if ($initExit -ne 0 -or !(Test-Path "$pgData\PG_VERSION")) {
            Write-Error "initdb failed (exit $initExit)."
            exit 1
        }
        Write-Host "initdb complete."
    } else {
        Write-Host "Data directory already initialized at $pgData."
    }

    # ── 3. Write postgresql.conf settings (idempotent) ────────────────────
    $confPath = "$pgData\postgresql.conf"
    $confContent = Get-Content $confPath -Raw
    $additions = @()
    if ($confContent -notmatch "^port\s*=") {
        $additions += "port = 5432"
    }
    if ($confContent -notmatch "^listen_addresses") {
        $additions += "listen_addresses = 'localhost'"
    }
    if ($confContent -notmatch "^logging_collector") {
        $additions += "logging_collector = on"
        $additions += "log_directory = 'log'"
        $additions += "log_filename = 'postgresql.log'"
        $additions += "log_truncate_on_rotation = off"
    }
    if ($additions.Count -gt 0) {
        Add-Content $confPath ("`n# POS Kiosk installer settings`n" + ($additions -join "`n"))
        Write-Host "Updated postgresql.conf."
    } else {
        Write-Host "postgresql.conf already configured."
    }

    # Remove stale lock from a previous crash
    Remove-Item "$pgData\postmaster.pid" -Force -ErrorAction SilentlyContinue

    # ── 4. Grant NetworkService permissions ───────────────────────────────
    Write-Host "Granting permissions to NT AUTHORITY\NetworkService..."
    icacls $pgData /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T /Q
    if ($LASTEXITCODE -ne 0) { Write-Error "icacls failed on $pgData"; exit 1 }
    icacls $pgBin /grant "NT AUTHORITY\NetworkService:(OI)(CI)RX" /T /Q
    if ($LASTEXITCODE -ne 0) { Write-Error "icacls failed on $pgBin"; exit 1 }
    icacls $logs /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T /Q
    if ($LASTEXITCODE -ne 0) { Write-Error "icacls failed on $logs"; exit 1 }
    Write-Host "Permissions granted."

    # ── 5. Remove any existing POSPostgres service ────────────────────────
    $existing = Get-Service "POSPostgres" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing existing POSPostgres service..."
        Stop-Service "POSPostgres" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        & "$pgBin\pg_ctl.exe" unregister -N POSPostgres
        Start-Sleep -Seconds 2
        Write-Host "Existing service removed."
    }

    # ── 6. Register PostgreSQL as native Windows service ─────────────────
    Write-Host "Registering POSPostgres service..."
    & "$pgBin\pg_ctl.exe" register -N POSPostgres `
        -U "NT AUTHORITY\NetworkService" -D $pgData -S auto
    if ($LASTEXITCODE -ne 0) {
        Write-Error "pg_ctl register failed (exit $LASTEXITCODE)"
        exit 1
    }
    Write-Host "Service registered."

    # ── 7. Start PostgreSQL ───────────────────────────────────────────────
    Write-Host "Starting POSPostgres..."
    Start-Service "POSPostgres" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    $svc = Get-Service "POSPostgres"
    Write-Host "Service status: $($svc.Status)"

    if ($svc.Status -ne "Running") {
        Write-Host "Service did not reach Running state immediately, waiting..."
        Start-Sleep -Seconds 5
        $svc.Refresh()
        Write-Host "Service status after wait: $($svc.Status)"
    }

    # ── 8. Wait for PostgreSQL to accept connections ──────────────────────
    Write-Host "Waiting for PostgreSQL to accept connections (up to 60s)..."
    $ready = $false
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 1
        & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p 5432 -q
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        if ($i % 5 -eq 0) { Write-Host "  still waiting... ($i/60)" }
    }

    if (!$ready) {
        Write-Error "PostgreSQL did not become ready within 60 seconds."
        Write-Host "=== PostgreSQL log ==="
        Get-ChildItem "$pgData\log\" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1 |
            ForEach-Object { Get-Content $_.FullName -Tail 30 }
        exit 1
    }
    Write-Host "PostgreSQL is ready."

    # ── 9. Create application database ───────────────────────────────────
    $env:PGPASSWORD = "postgres"
    $exists = (& "$pgBin\psql.exe" -U postgres -h 127.0.0.1 -p 5432 `
        -tAc "SELECT 1 FROM pg_database WHERE datname='pos_db'") 2>&1
    if ($exists -match "^1") {
        Write-Host "Database pos_db already exists."
    } else {
        Write-Host "Creating database pos_db..."
        & "$pgBin\psql.exe" -U postgres -h 127.0.0.1 -p 5432 `
            -c "CREATE DATABASE pos_db WITH ENCODING 'UTF8';"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create pos_db (exit $LASTEXITCODE)"
            exit 1
        }
        Write-Host "Database pos_db created."
    }

    # ── 10. Run TypeORM migrations ────────────────────────────────────────
    $backend = "$AppDir\backend\POSBackend.exe"
    if (!(Test-Path $backend)) {
        Write-Error "POSBackend.exe not found at: $backend"
        exit 1
    }
    Write-Host "Running database migrations..."
    Set-Location "$AppDir\backend"
    & $backend --migrate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Migrations failed (exit $LASTEXITCODE)"
        exit 1
    }
    Write-Host "Migrations complete."

    Write-Host "setup-postgres.ps1 completed successfully."

} catch {
    Write-Error "setup-postgres.ps1 failed: $_"
    exit 1
} finally {
    Stop-Transcript
}
