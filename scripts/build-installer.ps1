# Build the universal Setup.exe (x64 + ARM64) with Inno Setup. Run in Windows PowerShell 5.1.
# PayloadDir must contain two folders: x64 and arm64 (the "dist" folders of both builds).
param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$PayloadDir,
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $OutDir) { $OutDir = Join-Path $root 'release' }
New-Item -ItemType Directory -Force $OutDir | Out-Null

foreach ($a in 'x64', 'arm64') {
    foreach ($f in 'ModernMenu7z.dll', 'ModernMenu7z.msix', 'arch.txt', 'install.ps1') {
        $p = Join-Path (Join-Path $PayloadDir $a) $f
        if (-not (Test-Path -LiteralPath $p)) { throw "Payload file not found: $p" }
    }
}

# Inno Setup is preinstalled on GitHub Windows runners (for now); install it only if missing
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (-not (Test-Path -LiteralPath $iscc)) {
    Write-Host 'Inno Setup not found, installing with Chocolatey...'
    & choco install innosetup -y --no-progress
    if ($LASTEXITCODE -ne 0) { throw "choco install innosetup failed with exit code $LASTEXITCODE" }
}
if (-not (Test-Path -LiteralPath $iscc)) { throw "ISCC.exe not found at $iscc" }

$vnum = ($Version -replace '-.*$', '') + '.0'
& $iscc /Q "/DVersion=$Version" "/DVersionNum=$vnum" "/DPayload=$PayloadDir" "/DOutDir=$OutDir" "/DRoot=$root" "$root\packaging\ModernMenu7z.iss"
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }
Get-ChildItem $OutDir -Filter *.exe | Format-Table Name, Length
