param(
    [string]$AppDir = "C:\POSKiosk",
    [int]$RetentionDays = 7,
    [switch]$WhatIf
)

# One-off remediation for terminals installed before the logging fixes.
#
# Three things went wrong together:
#   1. .env.prod shipped NODE_ENV=development, so the backend logged every SQL
#      statement -- ~12 GB/day.
#   2. NSSM had AppRotateOnline=0, so rotation only happened at service start
#      and single files reached 84 GB.
#   3. Nothing ever deleted rotated logs.
#
# This reclaims the space and repairs 2 in place. Fixing 1 needs the updated
# installer (or edit backend\.env by hand and restart POSBackendService).
#
# Usage:  powershell -ExecutionPolicy Bypass -File cleanup-logs.ps1
#         ...add -WhatIf to see what it would remove without deleting anything.

$ErrorActionPreference = "Stop"
$logs = "$AppDir\logs"
$nssm = "$AppDir\nssm\nssm.exe"

function Format-Size([double]$bytes) {
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    if ($bytes -ge 1MB) { return "{0:N1} MB" -f ($bytes / 1MB) }
    return "{0:N0} KB" -f ($bytes / 1KB)
}

if (!(Test-Path $logs)) { Write-Host "No log directory at $logs -- nothing to do."; exit 0 }

$before = (Get-ChildItem $logs -File -ErrorAction SilentlyContinue |
           Measure-Object -Property Length -Sum).Sum
Write-Host "Log directory : $logs"
Write-Host "Current size  : $(Format-Size $before)"
Write-Host ""

# -- 1. Rotated backend logs (inactive -- safe to delete at any time) --------
$cutoff = (Get-Date).AddDays(-$RetentionDays)
$rotated = Get-ChildItem "$logs\backend-output-*.log","$logs\backend-error-*.log" -ErrorAction SilentlyContinue |
           Where-Object { $_.LastWriteTime -lt $cutoff }

$freed = 0
foreach ($f in $rotated) {
    Write-Host ("  remove  {0,-46} {1,12}" -f $f.Name, (Format-Size $f.Length))
    $freed += $f.Length
    if (-not $WhatIf) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue }
}
if (-not $rotated) { Write-Host "  (no rotated logs older than $RetentionDays days)" }

# -- 2. Active logs: held open, so truncate rather than delete ---------------
# The kiosk app keeps customer-display-*.log open and the service keeps
# backend-output.log open; deleting them leaves the handle writing to nothing.
Write-Host ""
foreach ($name in @("backend-output.log","backend-error.log","customer-display-host.log","customer-display-receiver.log")) {
    $path = "$logs\$name"
    if (!(Test-Path $path)) { continue }
    $size = (Get-Item $path).Length
    if ($size -lt 10MB) { continue }
    Write-Host ("  truncate {0,-45} {1,12}" -f $name, (Format-Size $size))
    $freed += $size
    if (-not $WhatIf) {
        try { Clear-Content $path -Force -ErrorAction Stop }
        catch { Write-Warning "  could not truncate $name (file locked): $($_.Exception.Message)" }
    }
}

# -- 3. Repair NSSM rotation so this cannot recur ----------------------------
Write-Host ""
if (Test-Path $nssm) {
    $online = (& $nssm get POSBackendService AppRotateOnline 2>$null) -replace "`0","" -replace "`r",""
    if ($online -match "1") {
        Write-Host "NSSM AppRotateOnline already enabled."
    } elseif ($WhatIf) {
        Write-Host "NSSM AppRotateOnline is 0 -- would set to 1."
    } else {
        & $nssm set POSBackendService AppRotateOnline 1 | Out-Null
        & $nssm set POSBackendService AppRotateBytes 10485760 | Out-Null
        Write-Host "NSSM AppRotateOnline set to 1 (takes effect on next service restart)."
    }
} else {
    Write-Warning "nssm.exe not found at $nssm -- skipped rotation repair."
}

Write-Host ""
if ($WhatIf) {
    Write-Host "DRY RUN -- nothing was changed. Would reclaim $(Format-Size $freed)."
} else {
    $after = (Get-ChildItem $logs -File -ErrorAction SilentlyContinue |
              Measure-Object -Property Length -Sum).Sum
    Write-Host "Reclaimed     : $(Format-Size ($before - $after))"
    Write-Host "New size      : $(Format-Size $after)"
    Write-Host ""
    Write-Host "NOTE: the backend keeps logging every SQL statement until"
    Write-Host "      $AppDir\backend\.env has NODE_ENV=production and"
    Write-Host "      POSBackendService is restarted."
}
