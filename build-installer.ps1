# build-installer.ps1
# One-click build: backend + Flutter (parallel) → compile installer
#
# Usage:
#   .\build-installer.ps1                  # build with current version
#   .\build-installer.ps1 -Version 1.1.0   # bump version then build

param(
    [string]$Version = ""
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
Write-Ok "All prerequisites present."

# ── Optional version bump ─────────────────────────────────────────────────────
if ($Version -ne "") {
    Write-Step "Bumping version to $Version..."
    $iss = Get-Content $IssPath -Raw
    $iss = $iss -replace '(#define MyAppVersion\s+")[^"]+(")', "`${1}$Version`$2"
    Set-Content $IssPath $iss -Encoding UTF8
    Write-Ok "installer.iss updated to version $Version."
}

# ── Read current version ──────────────────────────────────────────────────────
$currentVersion = (Get-Content $IssPath | Select-String '#define MyAppVersion').ToString() -replace '.*"([^"]+)".*','$1'
Write-Host "`nBuilding version: $currentVersion" -ForegroundColor Yellow

# ── Flutter pre-build setup (must run before jobs) ───────────────────────────
Write-Step "Preparing Flutter environment..."
Push-Location $KioskDir
fvm flutter config --enable-native-assets | Out-Null
fvm flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Fail "flutter pub get failed."; exit 1 }
fvm dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Fail "build_runner failed."; exit 1 }
Pop-Location
Write-Ok "Flutter code generation done."

# ── Build backend + Flutter in parallel ──────────────────────────────────────
Write-Step "Building backend (npm run build:sea) and Flutter app in parallel..."

$beJob = Start-Job -Name "Backend" -ScriptBlock {
    param($dir)
    Set-Location $dir
    npm run build:sea 2>&1
} -ArgumentList $BeDir

$flutterJob = Start-Job -Name "Flutter" -ScriptBlock {
    param($dir)
    Set-Location $dir
    fvm flutter build windows 2>&1
} -ArgumentList $KioskDir

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
                Receive-Job $job | Write-Host
                Remove-Job $beJob, $flutterJob -Force -ErrorAction SilentlyContinue
                exit 1
            }
        }
    }
}

# Collect output — surface any errors
$beOut     = Receive-Job $beJob
$flutterOut = Receive-Job $flutterJob
Remove-Job $beJob, $flutterJob

if ($beOut -match "error|Error|FAIL") {
    Write-Fail "Backend build reported errors:"
    $beOut | Where-Object { $_ -match "error|Error|FAIL" } | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
if ($flutterOut -match "Error|FAIL" -and $flutterOut -notmatch "Built build\\windows") {
    Write-Fail "Flutter build reported errors:"
    $flutterOut | Where-Object { $_ -match "Error|FAIL" } | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}

# ── Verify build outputs exist ────────────────────────────────────────────────
Write-Step "Verifying build outputs..."

$backendExe = "$BeDir\POSBackend.exe"
$kioskExe   = "$KioskDir\build\windows\x64\runner\Release\pos_app.exe"

if (-not (Test-Path $backendExe)) { Write-Fail "POSBackend.exe not found."; exit 1 }
if (-not (Test-Path $kioskExe))   { Write-Fail "pos_app.exe not found.";    exit 1 }

Write-Ok "POSBackend.exe: $([math]::Round((Get-Item $backendExe).Length/1MB,1)) MB"
Write-Ok "pos_app.exe:    $([math]::Round((Get-Item $kioskExe).Length/1MB,1)) MB"

# ── Compile installer ─────────────────────────────────────────────────────────
Write-Step "Compiling installer (LZMA2 - this takes ~2 min)..."

New-Item -ItemType Directory -Force $OutputDir | Out-Null
& $IsccPath $IssPath
if ($LASTEXITCODE -ne 0) {
    Write-Fail "ISCC compilation failed (exit $LASTEXITCODE)."
    exit 1
}

# ── Done ──────────────────────────────────────────────────────────────────────
$outFile = Get-ChildItem $OutputDir -Filter "POSKiosk-Setup-*.exe" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build complete!" -ForegroundColor Green
Write-Host "  $($outFile.FullName)" -ForegroundColor Green
Write-Host "  Size: $([math]::Round($outFile.Length/1MB,1)) MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
