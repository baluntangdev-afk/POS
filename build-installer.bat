@echo off
echo ============================================
echo  POS Kiosk - Build Installer
echo ============================================
echo.

set /p VERSION="Enter version (e.g. 1.0.1) or press Enter to keep current: "

echo.
echo Build mode:
echo   1. Online  (device registration required)
echo   2. Offline (skip device registration)
choice /c 12 /n /m "Select mode [1/2]: "
if errorlevel 2 (
    set MODE=Offline
) else (
    set MODE=Online
)
echo Building %MODE% installer...
echo.

if "%VERSION%"=="" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-installer.ps1" -Mode "%MODE%"
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-installer.ps1" -Version "%VERSION%" -Mode "%MODE%"
)

echo.
if %ERRORLEVEL% NEQ 0 (
    echo [FAILED] Build failed. See errors above.
) else (
    echo [DONE] Installer built successfully.
)

echo.
pause
