@echo off
if "%~2"=="" (
    echo Usage: restore-database.bat "C:\POSKiosk" "C:\POSKiosk\Backups\pos_db_20260810_020000.dump"
    exit /b 1
)
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0restore-database.ps1" -AppDir "%~1" -DumpFile "%~2"
exit /b %errorlevel%
