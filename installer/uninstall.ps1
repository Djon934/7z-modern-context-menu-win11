# Удаление. Запускайте через uninstall.cmd.
$ErrorActionPreference = 'Stop'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    $dir = Join-Path $env:ProgramFiles 'SevenZipModernMenu'
    Get-AppxPackage -Name 'Community.SevenZipModernMenu' | Remove-AppxPackage
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Get-ChildItem 'Cert:\LocalMachine\TrustedPeople' | Where-Object { $_.Subject -eq 'CN=SevenZipModernMenu' } | Remove-Item
    Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Удалено.' -ForegroundColor Green
}
catch {
    Write-Host "ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Нажмите Enter для выхода'
}
