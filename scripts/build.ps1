# Build: DLL + stub + sparse MSIX package + signing. Run in Windows PowerShell 5.1.
param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$out   = Join-Path $root 'out'
$dist  = Join-Path $root 'dist'
$stage = Join-Path $out 'pkg'
Remove-Item $out, $dist -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $out, $dist, $stage, "$stage\Assets" | Out-Null

function Assert-Ok($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed with exit code $LASTEXITCODE" } }

# --- 1. MSVC environment
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with C++ tools not found' }
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
cmd /c "`"$vcvars`" >nul && set" | ForEach-Object {
    if ($_ -match '^(.*?)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
}

# --- 2. Compile
Push-Location $out
try {
    & cl /nologo /std:c++17 /EHsc /O2 /MT /GS /W3 /DUNICODE /D_UNICODE /LD "$root\src\dllmain.cpp" `
        /Fe:ModernMenu7z.dll /link "/DEF:$root\src\exports.def" /DYNAMICBASE /NXCOMPAT /GUARD:CF
    Assert-Ok 'DLL compile'
    & cl /nologo /O1 /MT "$root\src\stub.cpp" /Fe:ModernMenu7z.exe
    Assert-Ok 'Stub compile'
} finally { Pop-Location }

# --- 3. Package icons (own simple icons, unrelated to 7-Zip)
Add-Type -AssemblyName System.Drawing
function New-Logo($path, $size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(255, 45, 92, 160))
    $font = New-Object System.Drawing.Font('Segoe UI', [single]($size * 0.38), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString('MM', $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, 0, $size, $size), $fmt)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}
New-Logo "$stage\Assets\StoreLogo.png" 50
New-Logo "$stage\Assets\Square44x44Logo.png" 44
New-Logo "$stage\Assets\Square150x150Logo.png" 150

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
$run  = if ($env:GITHUB_RUN_NUMBER) { $env:GITHUB_RUN_NUMBER } else { '0' }
$ver4 = ($Version -replace '-.*$', '') + '.' + $run
$tpl  = Get-Content "$root\packaging\AppxManifest.xml.template" -Raw -Encoding UTF8
$tpl  = $tpl.Replace('{{PUBLISHER}}', $publisher).Replace('{{VERSION4}}', $ver4)
[IO.File]::WriteAllText("$stage\AppxManifest.xml", $tpl, (New-Object Text.UTF8Encoding $false))

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
& $makeappx pack /d $stage /p $msix /nv /o
Assert-Ok 'makeappx'
& $signtool sign /fd SHA256 /f $pfx /p $pfxPass $msix
Assert-Ok 'signtool'

# --- 7. Final file set
Copy-Item "$out\ModernMenu7z.dll", "$out\ModernMenu7z.exe" $dist
Copy-Item "$root\installer\*" $dist
Remove-Item $pfx -Force
Get-ChildItem $dist | Format-Table Name, Length
