@echo off
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0register-backup-task.ps1" -AppDir "%~1"
exit /b %errorlevel%
