param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Adds Windows Firewall rule for port 3000 and a Defender exclusion for the
# install directory. Runs once during installation so unsigned backend executables
# are not blocked on the target machine.

$ErrorActionPreference = 'Continue'
$logs = "$AppDir\logs"
if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

try { Start-Transcript -Path "$logs\configure-security-install.log" -Force | Out-Null } catch { }

$backendExe = "$AppDir\backend\POSBackend.exe"

# ── Windows Firewall ─────────────────────────────────────────────────────────
# Inbound rule: allow the backend process to accept connections on port 3000.
# Loopback (localhost) traffic normally bypasses the firewall, but some
# corporate/managed machines enforce loopback filtering via policy.
Write-Host "Configuring Windows Firewall..."

# Remove stale rule first (idempotent)
netsh advfirewall firewall delete rule name="POSBackend-In" | Out-Null

netsh advfirewall firewall add rule `
    name="POSBackend-In" `
    dir=in `
    action=allow `
    protocol=TCP `
    localport=3000 `
    program="$backendExe" `
    description="Allow POSBackend to accept connections on port 3000" | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Firewall rule added: POSBackend-In (TCP 3000, inbound)."
} else {
    Write-Warning "Failed to add firewall rule (exit $LASTEXITCODE). Manual step may be needed."
}

# ── Windows Defender exclusion ───────────────────────────────────────────────
# Prevents Defender from quarantining or scan-locking the backend executable
# while it is running. Unsigned executables on fresh Windows installs are
# routinely scanned on first launch, which can cause the health-check to time
# out even when the process appears to be "Running" in Services.
#
# C:\posdata is excluded too (separately -- it's outside $AppDir). initdb
# writes hundreds of brand-new database files there on every install, and
# since it's re-created from scratch each time (see setup-postgres.ps1),
# Defender has never seen them before and scans/locks them in real time.
# That race is what makes POSPostgres intermittently fail to start with
# "the system cannot find the file specified" right after installation.
Write-Host "Configuring Windows Defender exclusion..."
foreach ($path in @($AppDir, "C:\posdata")) {
    try {
        Add-MpPreference -ExclusionPath $path -ErrorAction Stop
        Write-Host "Defender exclusion added for: $path"
    } catch {
        Write-Warning "Could not add Defender exclusion for $path : $_"
        Write-Warning "If the kiosk stays on 'Starting up...', add $path to Defender exclusions manually."
    }
}

Write-Host "configure-security.ps1 completed."
try { Stop-Transcript | Out-Null } catch { }
