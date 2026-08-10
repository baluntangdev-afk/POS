@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0backup-database.ps1" -AppDir "%~1"
exit /b %errorlevel%
