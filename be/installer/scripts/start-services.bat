@echo off
REM ---------------------------------------------------------------------------
REM  POS Kiosk - start services manually
REM  Starts PostgreSQL, waits until it accepts connections, then starts the
REM  NestJS backend service. Counterpart to stop-services.bat.
REM
REM  MUST be run as Administrator (starting Windows services requires it).
REM  Right-click this file -> "Run as administrator".
REM ---------------------------------------------------------------------------
setlocal
set "APPDIR=C:\POSKiosk"

REM --- Verify we are elevated -------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] This script must be run as Administrator.
    echo         Right-click start-services.bat and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo ============================================
echo  POS Kiosk - Start Services
echo  App dir: %APPDIR%
echo ============================================
echo.

powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0start-services.ps1" -AppDir "%APPDIR%"
set "RC=%errorlevel%"

echo.
sc query POSPostgres        2>nul | findstr /C:"STATE"
sc query POSBackendService  2>nul | findstr /C:"STATE"
echo ============================================
echo.
pause
exit /b %RC%
