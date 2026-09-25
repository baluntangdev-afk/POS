# build-installer.ps1
# One-click build: backend + Flutter (parallel) → compile installer
#
# Usage:
#   .\build-installer.ps1                  # build with current version
#   .\build-installer.ps1 -Version 1.1.0   # bump version then build
#   .\build-installer.ps1 -Mode Offline    # build the offline flavor (default: Online)
#
# -Mode sets --dart-define=SKIP_DEVICE_REGISTRATION for the Flutter build and
# suffixes the output: POSKiosk-Setup-<version>-<Mode>.exe

param(
    [string]$Version = "",
    [ValidateSet("Online", "Offline")]
    [string]$Mode = "Online"
)

$ErrorActionPreference = "Stop"
$ProjectRoot  = $PSScriptRoot
$BeDir        = "$ProjectRoot\be"
$KioskDir     = "$ProjectRoot\kiosk"
$IssPath      = "$BeDir\installer\installer.iss"
$IsccPath     = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
$OutputDir    = "$BeDir\installer\output"

function Write-Step([string]$msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}
function Write-Ok([string]$msg) {
    Write-Host "    [OK] $msg" -ForegroundColor Green
}
function Write-Fail([string]$msg) {
    Write-Host "`n    [FAIL] $msg" -ForegroundColor Red
}

# ── Preflight checks ──────────────────────────────────────────────────────────
Write-Step "Checking prerequisites..."

if (-not (Test-Path $IsccPath)) {
    Write-Fail "Inno Setup not found at: $IsccPath"
    exit 1
}
if (-not (Test-Path "C:\pgsql\bin\pg_ctl.exe")) {
    Write-Fail "Portable PostgreSQL not found at C:\pgsql\bin\. Run one-time setup first."
    exit 1
}
if (-not (Test-Path "C:\nssm\nssm.exe")) {
    Write-Fail "NSSM not found at C:\nssm\nssm.exe. Run one-time setup first."
    exit 1
}
if (-not (Test-Path "$BeDir\.env.prod")) {
    Write-Fail ".env.prod not found at be\.env.prod. Copy .env.example and fill in values."
    exit 1
}

function Get-EnvKeys([string]$path) {
    Get-Content $path | ForEach-Object {
        if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=') { $Matches[1] }
    }
}
function Get-EnvValue([string]$path, [string]$key) {
    $line = Get-Content $path | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
    if ($line) { ($line -split '=', 2)[1].Trim() } else { "" }
}

# .env.prod must declare every key in .env.example (values may be blank) --
# the installer never overwrites an installed .env, so a key forgotten here
# silently falls back to code defaults on every kiosk.
$missingBeKeys = Get-EnvKeys "$BeDir\.env.example" |
                 Where-Object { (Get-EnvKeys "$BeDir\.env.prod") -notcontains $_ }
if ($missingBeKeys) {
    Write-Fail "be\.env.prod is missing keys from .env.example: $($missingBeKeys -join ', ')"
    exit 1
}

# envied compiles kiosk\.env into pos_app.exe at build time.
if (-not (Test-Path "$KioskDir\.env")) {
    Write-Fail "kiosk\.env not found. Copy kiosk\.env.sample and fill in values."
    exit 1
}
foreach ($key in @("BACKEND_API_BASE_URL", "SECURE_STORAGE_KEY")) {
    if (-not (Get-EnvValue "$KioskDir\.env" $key)) {
        Write-Fail "kiosk\.env has no value for $key."
        exit 1
    }
}

# Use the fvm-pinned Flutter SDK (kiosk\.fvmrc) when fvm is installed.
$UseFvm = [bool](Get-Command fvm -ErrorAction SilentlyContinue)
function Invoke-Flutter { if ($UseFvm) { & fvm flutter @args } else { & flutter @args } }
function Invoke-Dart    { if ($UseFvm) { & fvm dart @args }    else { & dart @args } }
if ($UseFvm) {
    Write-Ok "Using fvm-pinned Flutter SDK."
} else {
    Write-Host "    [WARN] fvm not found - using 'flutter' from PATH." -ForegroundColor Yellow
}
Write-Ok "All prerequisites present."

# ── Optional version bump ─────────────────────────────────────────────────────
if ($Version -ne "") {
    Write-Step "Bumping version to $Version..."
    # Read/write explicitly as UTF-8: Windows PowerShell's Get-Content decodes a
    # BOM-less file as ANSI, and writing that back re-encodes every non-ASCII char.
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    $iss = [System.IO.File]::ReadAllText($IssPath, $utf8Bom)
    $iss = $iss -replace '(#define MyAppVersion\s+")[^"]+(")', "`${1}$Version`$2"
    [System.IO.File]::WriteAllText($IssPath, $iss, $utf8Bom)
    Write-Ok "installer.iss updated to version $Version."
}

# ── Read current version ──────────────────────────────────────────────────────
$currentVersion = (Get-Content $IssPath | Select-String '#define MyAppVersion').ToString() -replace '.*"([^"]+)".*','$1'
$skipDeviceRegistration = if ($Mode -eq "Offline") { "true" } else { "false" }
Write-Host "`nBuilding version: $currentVersion ($Mode, SKIP_DEVICE_REGISTRATION=$skipDeviceRegistration)" -ForegroundColor Yellow

# ── Flutter pre-build setup (must run before jobs) ───────────────────────────
Write-Step "Preparing Flutter environment..."
Push-Location $KioskDir
Invoke-Flutter config --enable-native-assets | Out-Null
Invoke-Flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Fail "flutter pub get failed."; exit 1 }
Invoke-Dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Fail "build_runner failed."; exit 1 }
Pop-Location
Write-Ok "Flutter code generation done."

# ── Build backend + Flutter in parallel ──────────────────────────────────────
Write-Step "Building backend (npm run build:sea) and Flutter app in parallel..."

# A job whose native command exits non-zero still ends as "Completed", so each
# job throws on a non-zero $LASTEXITCODE to surface as "Failed" instead.
$beJob = Start-Job -Name "Backend" -ScriptBlock {
    param($dir)
    Set-Location $dir
    npm run build:sea 2>&1
    if ($LASTEXITCODE -ne 0) { throw "npm run build:sea exited with code $LASTEXITCODE" }
} -ArgumentList $BeDir

$flutterJob = Start-Job -Name "Flutter" -ScriptBlock {
    param($dir, $skipDeviceRegistration, $useFvm)
    Set-Location $dir
    $defineArg = "--dart-define=SKIP_DEVICE_REGISTRATION=$skipDeviceRegistration"
    if ($useFvm) {
        fvm flutter build windows --release $defineArg 2>&1
    } else {
        flutter build windows --release $defineArg 2>&1
    }
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows exited with code $LASTEXITCODE" }
} -ArgumentList $KioskDir, $skipDeviceRegistration, $UseFvm

# Stream progress while waiting
$done = @{}
while ($done.Count -lt 2) {
    Start-Sleep -Seconds 3
    foreach ($job in @($beJob, $flutterJob)) {
        if ($job.State -in @("Completed","Failed") -and -not $done[$job.Name]) {
            $done[$job.Name] = $true
            if ($job.State -eq "Completed") {
                Write-Ok "$($job.Name) build finished."
            } else {
                Write-Fail "$($job.Name) build failed."
                Receive-Job $job -ErrorAction Continue 2>&1 | Write-Host
                Remove-Job $beJob, $flutterJob -Force -ErrorAction SilentlyContinue
                exit 1
            }
        }
    }
}

Remove-Job $beJob, $flutterJob

# ── Verify build outputs exist ────────────────────────────────────────────────
Write-Step "Verifying build outputs..."

$backendExe = "$BeDir\POSBackend.exe"
$kioskExe   = "$KioskDir\build\windows\x64\runner\Release\pos_app.exe"

if (-not (Test-Path $backendExe)) { Write-Fail "POSBackend.exe not found."; exit 1 }
if (-not (Test-Path $kioskExe))   { Write-Fail "pos_app.exe not found.";    exit 1 }

Write-Ok "POSBackend.exe: $([math]::Round((Get-Item $backendExe).Length/1MB,1)) MB"
Write-Ok "pos_app.exe:    $([math]::Round((Get-Item $kioskExe).Length/1MB,1)) MB"

# ── Sanitize installer scripts: strip smart/curly quotes ─────────────────────
# Some editors auto-convert straight quotes to typographic curly quotes.
# This breaks PowerShell (parser error) and Inno Setup (CreateProcess code 2).
# Normalize all installer files here so a stray editor save never ships broken scripts.
Write-Step "Sanitizing installer scripts (normalizing smart quotes)..."
& powershell -NoProfile -ExecutionPolicy Bypass `
    -File "$BeDir\installer\scripts\fix-smart-quotes.ps1" `
    -Dir "$BeDir\installer"
if ($LASTEXITCODE -ne 0) { Write-Fail "Smart-quote sanitization failed."; exit 1 }
Write-Ok "Installer scripts sanitized."

# ── Compile installer ─────────────────────────────────────────────────────────
Write-Step "Compiling installer (LZMA2 - this takes ~2 min)..."

New-Item -ItemType Directory -Force $OutputDir | Out-Null
& $IsccPath "/DMyAppFlavor=$Mode" $IssPath
if ($LASTEXITCODE -ne 0) {
    Write-Fail "ISCC compilation failed (exit $LASTEXITCODE)."
    exit 1
}

# ── Done ──────────────────────────────────────────────────────────────────────
$outFile = Get-ChildItem $OutputDir -Filter "POSKiosk-Setup-*-$Mode.exe" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $outFile) {
    Write-Fail "ISCC succeeded but no POSKiosk-Setup-*-$Mode.exe was found in $OutputDir."
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build complete!" -ForegroundColor Green
Write-Host "  $($outFile.FullName)" -ForegroundColor Green
Write-Host "  Size: $([math]::Round($outFile.Length/1MB,1)) MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
