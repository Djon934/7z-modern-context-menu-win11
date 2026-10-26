# Install ModernMenu7z. Run via install.cmd. Administrator rights are required.
# -Silent: used by the Setup.exe installer (no prompts, no elevation, exit code 1 on error, log in %TEMP%).
param([switch]$Silent)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($Silent) { Write-Host 'Administrator rights are required.'; exit 1 }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
$failed = $false
if ($Silent) { try { Start-Transcript -Path (Join-Path $env:TEMP 'ModernMenu7z-install.log') -Force | Out-Null } catch { } }
try {
    # The package must match the Windows architecture (Explorer loads only native DLLs)
    $osArch  = [string][Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $want    = if ($osArch -eq 'Arm64') { 'arm64' } elseif ($osArch -eq 'X64') { 'x64' } else { $osArch.ToLower() }
    $zipSuffix = if ($want -eq 'arm64') { 'arm64-beta' } else { $want }
    $archFile = Join-Path $here 'arch.txt'
    if (Test-Path -LiteralPath $archFile) {
        $pkgArch = (Get-Content -LiteralPath $archFile -Raw).Trim()
        if ($pkgArch -ne $want) {
            throw "This package is for $pkgArch, but your Windows is $osArch. Download the $want package (ModernMenu7z-<version>-$zipSuffix.zip) instead."
        }
    }

    $pkgName   = 'Djon934.ModernMenu7z'
    $dir       = Join-Path $env:ProgramFiles 'ModernMenu7z'
    $legacyPkg = 'Community.SevenZipModernMenu'      # name used by early test builds
    $legacyDir = Join-Path $env:ProgramFiles 'SevenZipModernMenu'

    if (-not (Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\7-Zip')) {
        Write-Warning "The classic 7-Zip shell integration was not found. Install 7-Zip for your architecture ($want) and enable 'Integrate 7-Zip to shell context menu' in its settings."
    }

    Write-Host '1/5 Removing previous version (if any)...'
    Get-AppxPackage -Name $pkgName   | Remove-AppxPackage
    Get-AppxPackage -Name $legacyPkg | Remove-AppxPackage

    Write-Host '2/5 Restarting Windows Explorer to release files...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # When started by Setup.exe the files are already in place (same folder): nothing to copy
    $inPlace = ($here.TrimEnd('\') -eq $dir.TrimEnd('\'))
    if ($inPlace) {
        Write-Host "3/5 Files are already in $dir"
    } else {
        Write-Host "3/5 Copying files to $dir ..."
        New-Item -ItemType Directory -Force $dir | Out-Null
        Copy-Item (Join-Path $here 'ModernMenu7z.dll') $dir -Force
        Copy-Item (Join-Path $here 'ModernMenu7z.exe') $dir -Force
        Copy-Item (Join-Path $here 'Assets') $dir -Recurse -Force
    }
    if (Test-Path $legacyDir) { Remove-Item $legacyDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host '4/5 Trusting the package signing certificate...'
    Import-Certificate -FilePath (Join-Path $here 'ModernMenu7z.cer') -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null

    Write-Host '5/5 Registering the package...'
    Add-AppxPackage -Path (Join-Path $here 'ModernMenu7z.msix') -ExternalLocation $dir

    Write-Host ''
    Write-Host 'Done. If the 7-Zip item does not appear, sign out of Windows and sign in again.' -ForegroundColor Green
}
catch {
    $failed = $true
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    if ($Silent) { try { Stop-Transcript | Out-Null } catch { } }
    else { Read-Host 'Press Enter to close' }
}
if ($failed) { exit 1 }
