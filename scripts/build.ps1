# Build: DLL + stub + sparse MSIX package + signing. Run in Windows PowerShell 5.1.
param(
    [Parameter(Mandatory)][string]$Version,
    [ValidateSet('x64','arm64')][string]$Arch = 'x64',
    [switch]$FullPackage,   # also build the experimental full (non-sparse) test package
    [switch]$StorePackage   # also build the unsigned package for Microsoft Store (Partner Center signs it)
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$out   = Join-Path $root 'out'
$dist  = Join-Path $root 'dist'
$stage = Join-Path $out 'pkg'
Remove-Item $out, $dist -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $out, $dist, $stage, "$stage\Assets" | Out-Null

function Assert-Ok($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed with exit code $LASTEXITCODE" } }

# --- 1. MSVC environment (arm64 is cross-compiled on the x64 host)
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$component = if ($Arch -eq 'arm64') { 'Microsoft.VisualStudio.Component.VC.Tools.ARM64' } else { 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64' }
$vs = & $vswhere -latest -products * -requires $component -property installationPath
if (-not $vs) { throw "Visual Studio with C++ tools for $Arch not found (component $component)" }
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvarsall.bat'
$vcArg = if ($Arch -eq 'arm64') { 'x64_arm64' } else { 'x64' }
Write-Host "=== Building for $Arch (vcvarsall $vcArg) ==="
cmd /c "`"$vcvars`" $vcArg >nul && set" | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
}

# --- 2. Version, icon and version-info resources
$run  = if ($env:GITHUB_RUN_NUMBER) { $env:GITHUB_RUN_NUMBER } else { '0' }
$ver4 = ($Version -replace '-.*$', '') + '.' + $run
$vcomma = $ver4.Replace('.', ',')
Copy-Item "$root\assets\icon.ico" $out

function New-ResourceFile($name, $fileName, $fileType) {
    $rc = @"
#include <winver.h>
1 ICON "icon.ico"
VS_VERSION_INFO VERSIONINFO
 FILEVERSION $vcomma
 PRODUCTVERSION $vcomma
 FILEFLAGSMASK 0x3fL
 FILEFLAGS 0x0L
 FILEOS VOS_NT_WINDOWS32
 FILETYPE $fileType
 FILESUBTYPE VFT2_UNKNOWN
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "040904B0"
    BEGIN
      VALUE "CompanyName", "Djon934"
      VALUE "FileDescription", "Modern context menu for 7-Zip"
      VALUE "FileVersion", "$Version"
      VALUE "InternalName", "ModernMenu7z"
      VALUE "LegalCopyright", "Copyright (c) 2026 Djon934. MIT License."
      VALUE "OriginalFilename", "$fileName"
      VALUE "ProductName", "Modern context menu for 7-Zip"
      VALUE "ProductVersion", "$Version"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1200
  END
END
"@
    Set-Content -Path "$out\$name.rc" -Value $rc -Encoding Ascii
    Push-Location $out
    try { & rc /nologo /fo "$name.res" "$name.rc"; Assert-Ok "Resource compile ($name)" } finally { Pop-Location }
}
New-ResourceFile 'dll' 'ModernMenu7z.dll' 'VFT_DLL'
New-ResourceFile 'exe' 'ModernMenu7z.exe' 'VFT_APP'

# --- 3. Compile
Push-Location $out
try {
    & cl /nologo /std:c++17 /EHsc /O2 /MT /GS /W3 /DUNICODE /D_UNICODE /LD "$root\src\dllmain.cpp" `
        /Fe:ModernMenu7z.dll /link "/DEF:$root\src\exports.def" /DYNAMICBASE /NXCOMPAT /GUARD:CF dll.res
    Assert-Ok 'DLL compile'
    & cl /nologo /O1 /MT "$root\src\stub.cpp" /Fe:ModernMenu7z.exe /link exe.res
    Assert-Ok 'Stub compile'
    # Make sure the binaries really are for the requested architecture
    $want = if ($Arch -eq 'arm64') { 'ARM64' } else { 'x64' }
    foreach ($f in 'ModernMenu7z.dll', 'ModernMenu7z.exe') {
        $line = (& dumpbin /headers $f | Select-String 'machine \(' | Select-Object -First 1).ToString().Trim()
        Write-Host "$f : $line"
        if ($line -notmatch [regex]::Escape("($want)")) { throw "$f was not built for $want" }
    }
} finally { Pop-Location }

# --- Package images (own icon from assets/, unrelated to 7-Zip)
Copy-Item "$root\assets\StoreLogo.png", "$root\assets\Square44x44Logo.png", "$root\assets\Square150x150Logo.png" "$stage\Assets"

# --- 4. Signing certificate
$pfx = Join-Path $out 'sign.pfx'
$cer = Join-Path $dist 'ModernMenu7z.cer'
if ($env:SIGN_PFX_BASE64) {
    # permanent certificate from repository secrets
    $pfxPass = $env:SIGN_PFX_PASSWORD
    [IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:SIGN_PFX_BASE64))
    $c = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $pfx, $pfxPass
    [IO.File]::WriteAllBytes($cer, $c.Export('Cert'))
    $publisher = $c.Subject
    Write-Host "Signing with permanent certificate: $publisher"
} else {
    # temporary self-signed certificate (test builds, forks without secrets)
    $pfxPass = [guid]::NewGuid().ToString('N')
    $publisher = 'CN=ModernMenu7z-Test'
    $c = New-SelfSignedCertificate -Type Custom -Subject $publisher -KeyUsage DigitalSignature `
        -FriendlyName 'ModernMenu7z (test)' -CertStoreLocation 'Cert:\CurrentUser\My' `
        -NotAfter (Get-Date).AddYears(3) `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
    Export-PfxCertificate -Cert $c -FilePath $pfx -Password (ConvertTo-SecureString $pfxPass -AsPlainText -Force) | Out-Null
    Export-Certificate -Cert $c -FilePath $cer | Out-Null
    Write-Host "Signing with TEMPORARY test certificate: $publisher"
}

# --- 5. Manifest
$tpl  = Get-Content "$root\packaging\AppxManifest.xml.template" -Raw -Encoding UTF8
$tpl  = $tpl.Replace('{{PUBLISHER}}', $publisher).Replace('{{VERSION4}}', $ver4).Replace('{{ARCH}}', $Arch).Replace('{{EXTRA_ITEMTYPES}}', '')

# --- 6. Pack and sign
function Find-SdkTool($name) {
    $f = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.*\x64\$name" -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.FullName -replace '^.*\\bin\\(10\.[\d.]+)\\.*$', '$1') } -Descending | Select-Object -First 1
    if (-not $f) { throw "$name not found in Windows SDK" }
    $f.FullName
}
$makeappx = Find-SdkTool 'makeappx.exe'
$signtool = Find-SdkTool 'signtool.exe'
$msix = Join-Path $dist 'ModernMenu7z.msix'

[IO.File]::WriteAllText("$stage\AppxManifest.xml", $tpl, (New-Object Text.UTF8Encoding $false))
& $makeappx pack /d $stage /p $msix /nv /o
Assert-Ok 'makeappx'
& $signtool sign /fd SHA256 /f $pfx /p $pfxPass $msix
Assert-Ok 'signtool'

# --- 7. Final file set
Copy-Item "$out\ModernMenu7z.dll", "$out\ModernMenu7z.exe" $dist
# Package images must also sit next to the DLL: for a sparse package Windows reads them from the install folder
New-Item -ItemType Directory -Force "$dist\Assets" | Out-Null
Copy-Item "$root\assets\StoreLogo.png", "$root\assets\Square44x44Logo.png", "$root\assets\Square150x150Logo.png" "$dist\Assets"
Copy-Item "$root\installer\*" $dist
Set-Content -Path "$dist\arch.txt" -Value $Arch -Encoding Ascii
if ($FullPackage) {
    Write-Host '=== Building the experimental FULL test package ==='
    $stageFull = Join-Path $out 'pkgfull'
    New-Item -ItemType Directory -Force $stageFull, "$stageFull\Assets" | Out-Null
    Copy-Item "$out\ModernMenu7z.dll", "$out\ModernMenu7z.exe" $stageFull
    Copy-Item "$root\assets\StoreLogo.png", "$root\assets\Square44x44Logo.png", "$root\assets\Square150x150Logo.png" "$stageFull\Assets"
    $tplFull = (Get-Content "$root\packaging\AppxManifest.full.xml.template" -Raw -Encoding UTF8).Replace('{{PUBLISHER}}', $publisher).Replace('{{VERSION4}}', $ver4).Replace('{{ARCH}}', $Arch).Replace('{{EXTRA_ITEMTYPES}}', '')
    [IO.File]::WriteAllText("$stageFull\AppxManifest.xml", $tplFull, (New-Object Text.UTF8Encoding $false))
    $msixFull = Join-Path $dist 'ModernMenu7z-FullPackage-Test.msix'
    & $makeappx pack /d $stageFull /p $msixFull /nv /o
    Assert-Ok 'makeappx (full package)'
    & $signtool sign /fd SHA256 /f $pfx /p $pfxPass $msixFull
    Assert-Ok 'signtool (full package)'
    Copy-Item "$root\tools\fullpackage-test\*" $dist
}
if ($StorePackage) {
    Write-Host '=== Building the Microsoft Store package (unsigned) ==='
    $stageStore = Join-Path $out 'pkgstore'
    New-Item -ItemType Directory -Force $stageStore, "$stageStore\Assets" | Out-Null
    Copy-Item "$out\ModernMenu7z.dll", "$out\ModernMenu7z.exe" $stageStore
    Copy-Item "$root\assets\StoreLogo.png", "$root\assets\Square44x44Logo.png", "$root\assets\Square150x150Logo.png" "$stageStore\Assets"
    # Store reserves the 4th number of the version: it must be 0
    $ver3 = ($Version -replace '-.*$', '') + '.0'
    $tplStore = (Get-Content "$root\packaging\AppxManifest.store.xml.template" -Raw -Encoding UTF8).Replace('{{VERSION4}}', $ver3).Replace('{{ARCH}}', $Arch)
    [IO.File]::WriteAllText("$stageStore\AppxManifest.xml", $tplStore, (New-Object Text.UTF8Encoding $false))
    $msixStore = Join-Path $dist "ModernMenu7z-Store-$Version-$Arch.msix"
    & $makeappx pack /d $stageStore /p $msixStore /o
    Assert-Ok 'makeappx (Store package)'
}
Remove-Item $pfx -Force
Get-ChildItem $dist | Format-Table Name, Length
