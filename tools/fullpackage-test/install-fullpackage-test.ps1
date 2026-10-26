# EXPERIMENTAL: install the full (non-sparse) MSIX test package. Run via install-fullpackage-test.cmd.
# It first removes the normal (sparse) ModernMenu7z package: both use the same menu COM class.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    Write-Host '1/4 Removing the normal package and any earlier test package...'
    Get-AppxPackage -Name 'Djon934.ModernMenu7z'     | Remove-AppxPackage
    Get-AppxPackage -Name 'Djon934.ModernMenu7zTest' | Remove-AppxPackage
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host '2/4 Trusting the signing certificate...'
    Import-Certificate -FilePath (Join-Path $here 'ModernMenu7z.cer') -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null

    Write-Host '3/4 Installing the full test package...'
    Add-AppxPackage -Path (Join-Path $here 'ModernMenu7z-FullPackage-Test.msix')

    Write-Host '4/4 Done. Right-click a file or folder and check the 7-Zip item.' -ForegroundColor Green
    Write-Host 'To go back to the normal version run remove-fullpackage-test.cmd'
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Press Enter to close'
}
