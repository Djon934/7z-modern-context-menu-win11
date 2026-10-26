# Remove the full MSIX test package and restore the normal (sparse) installation if it is present.
$ErrorActionPreference = 'Stop'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
try {
    Get-AppxPackage -Name 'Djon934.ModernMenu7zTest' | Remove-AppxPackage
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host 'Test package removed.' -ForegroundColor Green

    $dir = Join-Path $env:ProgramFiles 'ModernMenu7z'
    $inst = Join-Path $dir 'install.ps1'
    if ((Test-Path -LiteralPath $inst) -and (Test-Path -LiteralPath (Join-Path $dir 'ModernMenu7z.msix'))) {
        Write-Host 'Restoring the normal version from Program Files...'
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $inst -Silent
        if ($LASTEXITCODE -eq 0) { Write-Host 'Normal version restored.' -ForegroundColor Green }
        else { Write-Host 'Restore failed: run ModernMenu7z Setup.exe again.' -ForegroundColor Yellow }
    } else {
        Write-Host 'The normal version was not found in Program Files: run ModernMenu7z Setup.exe to install it.'
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
    Read-Host 'Press Enter to close'
}
