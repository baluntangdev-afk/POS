@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0install-backend-service.ps1" -AppDir "%~1"
exit /b %errorlevel%
