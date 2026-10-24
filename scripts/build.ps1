# ЗАГЛУШКА: здесь появится сборка DLL (IExplorerCommand), sparse-пакета и установщика.
param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force dist | Out-Null
"placeholder build $Version" | Set-Content "dist/placeholder-$Version.txt"
