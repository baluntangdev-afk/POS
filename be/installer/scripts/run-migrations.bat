@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0run-migrations.ps1" -AppDir "%~1"
exit /b %errorlevel%
