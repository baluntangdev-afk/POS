@echo off
setlocal

cd /d "%~dp0.."

if not exist ".env" (
    echo Error: .env not found in %cd%
    exit /b 1
)

echo Running database migrations...
POSBackend.exe --migrate

if errorlevel 1 (
    echo ERROR: Migrations failed.
    exit /b 1
)

echo Migrations complete.
endlocal
exit /b 0
