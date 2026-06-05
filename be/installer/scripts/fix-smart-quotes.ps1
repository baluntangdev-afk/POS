# Replaces smart/curly quotes with straight quotes in installer scripts.
# Use in source: 'npm run fix:quotes'
# Use on a broken installed device: run this directly pointing at C:\POSKiosk\scripts\
param([string]$Dir = "$PSScriptRoot\..")

$files = Get-ChildItem (Resolve-Path $Dir) -Recurse -Include "*.ps1","*.bat","*.iss"
$fixedCount = 0

foreach ($file in $files) {
    $original = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $fixed = $original `
        -replace [char]0x201C, '"' `
        -replace [char]0x201D, '"' `
        -replace [char]0x2018, "'" `
        -replace [char]0x2019, "'"
    if ($fixed -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $fixed, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "Fixed: $($file.FullName)"
        $fixedCount++
    }
}

if ($fixedCount -eq 0) {
    Write-Host "Nothing to fix - all files already clean."
} else {
    Write-Host ""
    Write-Host "$fixedCount file(s) fixed."
}
