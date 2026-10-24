# Install ModernMenu7z. Run via install.cmd. Administrator rights are required.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    $pkgName   = 'Djon934.ModernMenu7z'
    $dir       = Join-Path $env:ProgramFiles 'ModernMenu7z'
    $legacyPkg = 'Community.SevenZipModernMenu'      # name used by early test builds
    $legacyDir = Join-Path $env:ProgramFiles 'SevenZipModernMenu'

    if (-not (Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\7-Zip')) {
        Write-Warning 'The classic 7-Zip shell integration was not found. Install 7-Zip (x64) and enable "Integrate 7-Zip to shell context menu" in its settings.'
    }

    Write-Host '1/5 Removing previous version (if any)...'
    Get-AppxPackage -Name $pkgName   | Remove-AppxPackage
    Get-AppxPackage -Name $legacyPkg | Remove-AppxPackage

    Write-Host '2/5 Restarting Windows Explorer to release files...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "3/5 Copying files to $dir ..."
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item (Join-Path $here 'ModernMenu7z.dll') $dir -Force
    Copy-Item (Join-Path $here 'ModernMenu7z.exe') $dir -Force
    Copy-Item (Join-Path $here 'Assets') $dir -Recurse -Force
    if (Test-Path $legacyDir) { Remove-Item $legacyDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host '4/5 Trusting the package signing certificate...'
    Import-Certificate -FilePath (Join-Path $here 'ModernMenu7z.cer') -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null

    Write-Host '5/5 Registering the package...'
    Add-AppxPackage -Path (Join-Path $here 'ModernMenu7z.msix') -ExternalLocation $dir

    Write-Host ''
    Write-Host 'Done. If the 7-Zip item does not appear, sign out of Windows and sign in again.' -ForegroundColor Green
}
catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Press Enter to close'
}
