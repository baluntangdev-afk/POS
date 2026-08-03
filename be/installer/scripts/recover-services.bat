@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  POS Kiosk — service recovery
REM  Re-runs the database + backend setup when the installer's [Run] steps did
REM  not complete (e.g. a failed install left no POSPostgres/POSBackendService).
REM
REM  MUST be run as Administrator (registering Windows services requires it).
REM  Right-click this file -> "Run as administrator".
REM ─────────────────────────────────────────────────────────────────────────
setlocal
set "APPDIR=C:\POSKiosk"

REM --- Verify we are elevated -------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] This script must be run as Administrator.
    echo         Right-click recover-services.bat and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo ============================================
echo  POS Kiosk - Service Recovery
echo  App dir: %APPDIR%
echo ============================================
echo.

echo [1/2] Setting up PostgreSQL (init data, register service, create DB, migrate, seed)...
call "%~dp0setup-postgres.bat" "%APPDIR%"
if %errorlevel% neq 0 (
    echo.
    echo [FAILED] PostgreSQL setup failed. See %APPDIR%\logs\setup-postgres-install.log
    pause
    exit /b 1
)
echo     [OK] PostgreSQL ready.
echo.

echo [2/2] Installing backend service...
call "%~dp0install-backend-service.bat" "%APPDIR%"
if %errorlevel% neq 0 (
    echo.
    echo [FAILED] Backend service install failed. See %APPDIR%\logs\install-backend-service-install.log
    pause
    exit /b 1
)
echo     [OK] Backend service installed.
echo.
echo NOTE: Product catalog is imported in-app via Inventory Management ^> Import CSV.
echo.

echo ============================================
echo  Recovery complete. Services:
sc query POSPostgres        | findstr /C:"STATE"
sc query POSBackendService  | findstr /C:"STATE"
echo ============================================
echo  You can now launch the POS Kiosk.
echo.
pause
