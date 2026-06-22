@echo off
REM ---------------------------------------------------------------------------
REM  POS Kiosk - stop services manually
REM  Stops the kiosk app, the NestJS backend service, and PostgreSQL WITHOUT
REM  removing them. The services stay registered and can be started again.
REM
REM  MUST be run as Administrator (stopping Windows services requires it).
REM  Right-click this file -> "Run as administrator".
REM ---------------------------------------------------------------------------
setlocal
set "APPDIR=C:\POSKiosk"

REM --- Verify we are elevated -------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] This script must be run as Administrator.
    echo         Right-click stop-services.bat and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo ============================================
echo  POS Kiosk - Stop Services
echo  App dir: %APPDIR%
echo ============================================
echo.

powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0stop-services.ps1" -AppDir "%APPDIR%"
set "RC=%errorlevel%"

echo.
sc query POSPostgres        2>nul | findstr /C:"STATE"
sc query POSBackendService  2>nul | findstr /C:"STATE"
echo ============================================
echo.
pause
exit /b %RC%
