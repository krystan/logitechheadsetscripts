@echo off
:: Run-Logitech-Audio-Harden.cmd
setlocal
set SCRIPT_DIR=%~dp0
set PS1=%SCRIPT_DIR%Harden-LogitechUsbAudio.ps1
where powershell >nul 2>nul || (echo PowerShell not found.& exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%PS1%\"'"
endlocal
