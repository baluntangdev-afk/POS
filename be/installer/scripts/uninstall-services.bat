@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall-services.ps1" -AppDir "%~1"
exit /b %errorlevel%
