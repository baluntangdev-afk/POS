@echo off
REM Script to run database seeders
REM This script should be placed in the installer and run after installation

echo Running database seeders...
echo.

cd /d "%~dp0\.."

REM Check if .env file exists
if not exist ".env" (
    echo Error: .env file not found!
    echo Please ensure .env file exists in the application directory.
    pause
    exit /b 1
)

REM Run seeders using the executable with a seeder flag
REM Note: You'll need to add seeder support to your executable
REM For now, this is a placeholder - you may need to use a custom script or add seeder commands to your exe
echo Seeder functionality needs to be implemented in your executable.
echo.
echo To run seeders manually, you can:
echo 1. Add seeder commands to your executable
echo 2. Create a separate seeder script
echo.
pause
