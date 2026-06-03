@echo off
echo ============================================
echo  POS Kiosk - Build Installer
echo ============================================
echo.

set /p VERSION="Enter version (e.g. 1.0.1) or press Enter to keep current: "

if "%VERSION%"=="" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-installer.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-installer.ps1" -Version "%VERSION%"
)

echo.
if %ERRORLEVEL% NEQ 0 (
    echo [FAILED] Build failed. See errors above.
) else (
    echo [DONE] Installer built successfully.
)

echo.
pause
