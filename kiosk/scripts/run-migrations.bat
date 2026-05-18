@echo off
REM Script to run database migrations
REM This script should be placed in the installer and run after installation

echo Running database migrations...
echo.

cd /d "%~dp0\.."

REM Check if .env file exists
if not exist ".env" (
    echo Error: .env file not found!
    echo Please ensure .env file exists in the application directory.
    pause
    exit /b 1
)

REM Run migrations using the executable with a migration flag
REM Note: You'll need to add migration support to your executable
REM For now, this is a placeholder - you may need to use typeorm CLI or add migration commands to your exe
echo Migration functionality needs to be implemented in your executable.
echo.
echo To run migrations manually, you can:
echo 1. Use TypeORM CLI if Node.js is installed
echo 2. Add migration commands to your executable
echo.
pause
