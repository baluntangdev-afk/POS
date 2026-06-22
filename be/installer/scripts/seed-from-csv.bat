@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0seed-from-csv.ps1" -AppDir "%~1"
exit /b %errorlevel%
