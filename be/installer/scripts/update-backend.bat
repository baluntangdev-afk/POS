@echo off
:: update-backend.bat — swap POSBackend.exe, sync static assets, apply migrations
::
:: Usage:
::   update-backend.bat                                       -- run migrations in-place (no exe swap)
::   update-backend.bat "C:\path\to\new.exe"                  -- swap exe then run migrations
::   update-backend.bat "C:\path\to\new.exe" "C:\path\public" -- swap exe, sync images, run migrations
::
:: All forms stop POSBackendService, apply migrations, then restart it.
:: Logs: C:\POSKiosk\logs\update-backend.log

setlocal

set APP_DIR=C:\POSKiosk
set NEW_EXE=%~1
set PUBLIC_DIR=%~2

set PS_ARGS=-AppDir "%APP_DIR%"
if not "%NEW_EXE%"=="" set PS_ARGS=%PS_ARGS% -ExePath "%NEW_EXE%"
if not "%PUBLIC_DIR%"=="" set PS_ARGS=%PS_ARGS% -PublicDir "%PUBLIC_DIR%"

%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe ^
    -ExecutionPolicy Bypass -NonInteractive ^
    -File "%~dp0update-backend.ps1" %PS_ARGS%

exit /b %errorlevel%
