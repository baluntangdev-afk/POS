@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0setup-postgres.ps1" -AppDir "%~1"
exit /b %errorlevel%
