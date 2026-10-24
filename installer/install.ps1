# Установка. Запускайте через install.cmd (двойной щелчок). Нужны права администратора.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    $pkgName = 'Community.SevenZipModernMenu'
    $dir = Join-Path $env:ProgramFiles 'SevenZipModernMenu'

    if (-not (Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\7-Zip')) {
        Write-Warning 'Классическое меню 7-Zip не найдено в реестре. Установите 7-Zip (x64) и включите интеграцию с оболочкой.'
    }

    Write-Host '1/5 Удаляю предыдущую версию (если была)...'
    Get-AppxPackage -Name $pkgName | Remove-AppxPackage

    Write-Host '2/5 Перезапускаю проводник, чтобы освободить файлы...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "3/5 Копирую файлы в $dir ..."
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item (Join-Path $here 'SevenZipMenuExt.dll') $dir -Force
    Copy-Item (Join-Path $here 'SevenZipModernMenu.exe') $dir -Force

    Write-Host '4/5 Добавляю сертификат в доверенные...'
    Import-Certificate -FilePath (Join-Path $here 'SevenZipModernMenu.cer') -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null

    Write-Host '5/5 Регистрирую пакет...'
    Add-AppxPackage -Path (Join-Path $here 'SevenZipModernMenu.msix') -ExternalLocation $dir

    Write-Host ''
    Write-Host 'Готово. Если пункт 7-Zip не появился, выйдите из учётной записи и войдите снова.' -ForegroundColor Green
}
catch {
    Write-Host ''
    Write-Host "ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Нажмите Enter для выхода'
}
