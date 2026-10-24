@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0New-SigningCertificate.ps1"
pause
