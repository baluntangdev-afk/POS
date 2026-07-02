@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0configure-autologon.ps1" -AppDir "%~1"
exit /b %errorlevel%
