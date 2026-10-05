@echo off
REM Reclaims disk space from the service log folder and repairs NSSM rotation.
REM Run as administrator. Pass -WhatIf to preview without deleting anything.
REM Defaults to C:\POSKiosk when no path is given, so a double-click works.
setlocal
set "APPDIR=%~1"
if "%APPDIR%"=="" set "APPDIR=%~dp0.."
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "%~dp0cleanup-logs.ps1" -AppDir "%APPDIR%" %2 %3
exit /b %errorlevel%
