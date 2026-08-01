# Scans installer scripts for smart/curly quotes that break PowerShell and Inno Setup.
# Called by .githooks/pre-commit and 'npm run check:quotes'.
param([string]$Dir = "$PSScriptRoot\..")

$files = Get-ChildItem (Resolve-Path $Dir) -Recurse -Include "*.ps1","*.bat","*.iss"
$found = $false

foreach ($file in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    for ($i = 0; $i -lt $bytes.Length - 2; $i++) {
        if ($bytes[$i] -eq 0xe2 -and $bytes[$i+1] -eq 0x80 -and
            $bytes[$i+2] -in @(0x9c, 0x9d, 0x98, 0x99)) {
            $lineNum = ([System.Text.Encoding]::UTF8.GetString($bytes[0..$i]) -split "`n").Count
            Write-Host "SMART QUOTE: $($file.FullName) (line $lineNum)"
            $found = $true
            break
        }
    }
}

if ($found) {
    Write-Host ""
    Write-Host "Smart/curly quotes break PowerShell and Inno Setup. Fix with: npm run fix:quotes"
    exit 1
}

Write-Host "OK - no smart quotes found in installer scripts."
exit 0
