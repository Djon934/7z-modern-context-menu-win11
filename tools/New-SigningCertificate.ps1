# Creates a personal code-signing certificate (one-time setup).
# Output (on your Desktop, folder "signing-certificate"):
#   <Name>.pfx             PRIVATE KEY. Never publish it. Keep a backup.
#   <Name>.cer             public certificate (safe to share)
#   <Name>.pfx.base64.txt  the same .pfx as text, for the GitHub secret SIGN_PFX_BASE64
param(
    [string]$Name = 'Djon934',
    [string]$Organization = 'Djon934',
    [string]$Country = 'RU',
    [int]$Years = 10
)
$ErrorActionPreference = 'Stop'

function ToPlain($s) {
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    try { [Runtime.InteropServices.Marshal]::PtrToStringAuto($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

$outDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'signing-certificate'
New-Item -ItemType Directory -Force $outDir | Out-Null

Write-Host 'Create a strong password (12+ characters) for the private key file.'
$p1 = Read-Host 'Password' -AsSecureString
$p2 = Read-Host 'Repeat password' -AsSecureString
if ((ToPlain $p1) -ne (ToPlain $p2)) { throw 'Passwords do not match.' }
if ((ToPlain $p1).Length -lt 12) { throw 'Password is too short (need 12+ characters).' }

$subject = "CN=$Name, O=$Organization, C=$Country"
$cert = New-SelfSignedCertificate -Type Custom -Subject $subject `
    -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeyExportPolicy Exportable `
    -KeyUsage DigitalSignature -FriendlyName "$Name code signing" `
    -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears($Years) `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')

$pfx = Join-Path $outDir "$Name.pfx"
$cer = Join-Path $outDir "$Name.cer"
$b64 = Join-Path $outDir "$Name.pfx.base64.txt"
Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $p1 | Out-Null
Export-Certificate    -Cert $cert -FilePath $cer | Out-Null
$text = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfx))
[IO.File]::WriteAllText($b64, $text)

# remove the private key from this PC's certificate store: the .pfx file is the only copy now
try { Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -DeleteKey } catch { }

Write-Host ''
Write-Host "Subject    : $($cert.Subject)"
Write-Host "Thumbprint : $($cert.Thumbprint)"
Write-Host "Valid until: $($cert.NotAfter)"
Write-Host "Files in   : $outDir"
Write-Host ''
Write-Host 'NEXT STEPS' -ForegroundColor Green
Write-Host '1. Make a backup copy of the .pfx file (USB drive, password manager). If it is lost, you cannot sign updates with the same identity.'
Write-Host '2. GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret:'
Write-Host '     SIGN_PFX_BASE64   = full contents of the .pfx.base64.txt file'
Write-Host '     SIGN_PFX_PASSWORD = the password you just typed'
Write-Host '3. NEVER upload the .pfx or .base64.txt files to the repository.'
Set-Clipboard -Value $text
Write-Host ''
Write-Host 'The base64 text is now in your clipboard: paste it into the SIGN_PFX_BASE64 secret.' -ForegroundColor Yellow
