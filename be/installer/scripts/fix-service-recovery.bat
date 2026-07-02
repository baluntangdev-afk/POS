@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  POS Kiosk — patch already-installed services with failure recovery
REM  MUST be run as Administrator.
REM ─────────────────────────────────────────────────────────────────────────
setlocal

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Must be run as Administrator.
    echo Right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

echo ============================================
echo  POS Kiosk - Apply service recovery settings
echo ============================================
echo.

REM ── POSPostgres ──────────────────────────────────────────────────────────
echo [1/4] Switching POSPostgres to auto start...
sc.exe config POSPostgres start= auto
if %errorlevel% neq 0 ( echo [WARN] Could not set auto start on POSPostgres )

echo [2/4] Configuring POSPostgres failure recovery...
sc.exe failure POSPostgres reset= 86400 actions= restart/5000/restart/15000/restart/30000
if %errorlevel% neq 0 ( echo [WARN] Could not set failure recovery on POSPostgres )

REM ── POSBackendService ─────────────────────────────────────────────────────
echo [3/4] Switching POSBackendService to auto start...
sc.exe config POSBackendService start= auto
if %errorlevel% neq 0 ( echo [WARN] Could not set auto start on POSBackendService )

echo [4/4] Configuring POSBackendService failure recovery...
sc.exe failure POSBackendService reset= 86400 actions= restart/5000/restart/15000/restart/30000
if %errorlevel% neq 0 ( echo [WARN] Could not set failure recovery on POSBackendService )

echo.
echo ── Starting services ────────────────────────────────────────────────────
echo Starting POSPostgres...
sc.exe start POSPostgres
timeout /t 8 /nobreak >nul

echo Starting POSBackendService...
sc.exe start POSBackendService
timeout /t 5 /nobreak >nul

echo.
echo ── Current status ───────────────────────────────────────────────────────
sc.exe query POSPostgres       | findstr /C:"STATE"
sc.exe query POSBackendService | findstr /C:"STATE"
echo.
echo Done. Both services now have auto-restart on failure and auto start.
echo.
pause
