@echo off
:: update-backend.bat — swap POSBackend.exe and apply pending migrations
::
:: Usage:
::   update-backend.bat                          -- run migrations in-place (no exe swap)
::   update-backend.bat "C:\path\to\new.exe"    -- swap exe then run migrations
::
:: Both forms stop POSBackendService, apply migrations, then restart it.
:: Logs: C:\POSKiosk\logs\update-backend.log

setlocal

set APP_DIR=C:\POSKiosk
set NEW_EXE=%~1

if "%NEW_EXE%"=="" (
    %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe ^
        -ExecutionPolicy Bypass -NonInteractive ^
        -File "%~dp0update-backend.ps1" ^
        -AppDir "%APP_DIR%"
) else (
    %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe ^
        -ExecutionPolicy Bypass -NonInteractive ^
        -File "%~dp0update-backend.ps1" ^
        -AppDir "%APP_DIR%" ^
        -ExePath "%NEW_EXE%"
)

exit /b %errorlevel%
