# Uninstall ModernMenu7z. Run via uninstall.cmd. Administrator rights are required.
$ErrorActionPreference = 'Stop'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    Get-AppxPackage -Name 'Djon934.ModernMenu7z'           | Remove-AppxPackage
    Get-AppxPackage -Name 'Community.SevenZipModernMenu'   | Remove-AppxPackage
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Remove-Item (Join-Path $env:ProgramFiles 'ModernMenu7z')        -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:ProgramFiles 'SevenZipModernMenu')  -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Removed.' -ForegroundColor Green
    Write-Host 'The signing certificate was left in "Trusted People" on purpose: it may be used by other software'
    Write-Host 'signed with the same key. To remove it: Win+R -> certlm.msc -> Trusted People -> Certificates.'
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Press Enter to close'
}
