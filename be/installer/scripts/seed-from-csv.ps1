param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

$backend    = "$AppDir\backend\POSBackend.exe"
$csvDir     = "$AppDir\data\csv"
$logs       = "$AppDir\logs"
$markerFile = "$logs\seed-csv-success.marker"

if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

# Remove stale marker from a previous run
if (Test-Path $markerFile) { Remove-Item $markerFile -Force }

Start-Transcript -Path "$logs\seed-csv-install.log" -Force

try {
    Write-Host "AppDir : $AppDir"
    Write-Host "CsvDir : $csvDir"

    if (!(Test-Path $backend)) {
        Write-Error "POSBackend.exe not found at: $backend"
        exit 1
    }

    if (!(Test-Path $csvDir)) {
        Write-Error "CSV directory not found: $csvDir"
        exit 1
    }

    $csvFiles = Get-ChildItem -Path $csvDir -Filter "*.csv" -File
    if ($csvFiles.Count -eq 0) {
        Write-Error "No CSV files found in: $csvDir"
        exit 1
    }

    Write-Host "Found $($csvFiles.Count) CSV file(s). Running CSV seeder..."
    Set-Location "$AppDir\backend"
    & $backend --seed-csv $csvDir

    if ($LASTEXITCODE -ne 0) {
        Write-Error "CSV seeding failed (exit $LASTEXITCODE)"
        exit 1
    }

    # Write success marker so the Inno Setup post-install check can detect success
    [System.IO.File]::WriteAllText($markerFile, "ok")
    Write-Host "seed-from-csv.ps1 completed successfully."

} catch {
    Write-Error "seed-from-csv.ps1 failed: $_"
    exit 1
} finally {
    Stop-Transcript
}
