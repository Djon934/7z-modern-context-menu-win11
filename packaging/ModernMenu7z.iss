; Inno Setup script: one Setup.exe for x64 and ARM64 Windows.
; Compiled by scripts/build-installer.ps1 (defines: Version, VersionNum, Payload, OutDir, Root).
; Payload layout: {#Payload}\x64\*  and  {#Payload}\arm64\*  (the "dist" folders of both builds).
; The installer only copies files; registration is done by install.ps1 -Silent (same logic as the zip package).

#ifndef Version
  #define Version "0.0.0"
#endif
#ifndef VersionNum
  #define VersionNum "0.0.0.0"
#endif
#ifndef Payload
  #define Payload "..\payload"
#endif
#ifndef OutDir
  #define OutDir "..\release"
#endif
#ifndef Root
  #define Root ".."
#endif

[Setup]
AppId={{B07486BB-5438-425E-8932-ADB77F05AC10}
AppName=Modern context menu for 7-Zip
AppVersion={#Version}
AppPublisher=Djon934
AppPublisherURL=https://github.com/Djon934/7z-modern-context-menu-win11
AppSupportURL=https://github.com/Djon934/7z-modern-context-menu-win11/issues
AppUpdatesURL=https://github.com/Djon934/7z-modern-context-menu-win11/releases
VersionInfoVersion={#VersionNum}
VersionInfoCompany=Djon934
VersionInfoDescription=Modern context menu for 7-Zip (setup)
DefaultDirName={commonpf64}\ModernMenu7z
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutDir}
OutputBaseFilename=ModernMenu7z-{#Version}-Setup
SetupIconFile={#Root}\assets\icon.ico
UninstallDisplayIcon={app}\ModernMenu7z.exe
UninstallDisplayName=Modern context menu for 7-Zip
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=no
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; x64
Source: "{#Payload}\x64\ModernMenu7z.dll";  DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\ModernMenu7z.exe";  DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\ModernMenu7z.msix"; DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\ModernMenu7z.cer";  DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\arch.txt";          DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\install.ps1";       DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\uninstall.ps1";     DestDir: "{app}"; Flags: ignoreversion; Check: not IsArm64
Source: "{#Payload}\x64\Assets\*";          DestDir: "{app}\Assets"; Flags: ignoreversion recursesubdirs; Check: not IsArm64
; ARM64
Source: "{#Payload}\arm64\ModernMenu7z.dll";  DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\ModernMenu7z.exe";  DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\ModernMenu7z.msix"; DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\ModernMenu7z.cer";  DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\arch.txt";          DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\install.ps1";       DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\uninstall.ps1";     DestDir: "{app}"; Flags: ignoreversion; Check: IsArm64
Source: "{#Payload}\arm64\Assets\*";          DestDir: "{app}\Assets"; Flags: ignoreversion recursesubdirs; Check: IsArm64

[Code]
function PowerShellExe(): String;
begin
  // 64-bit install mode: {sys} is the native System32 (ARM64 PowerShell on ARM64 Windows)
  Result := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
end;

function RunPs(const Args: String): Integer;
var
  rc: Integer;
begin
  if not Exec(PowerShellExe(), '-NoProfile -ExecutionPolicy Bypass ' + Args, ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, rc) then
    rc := -1;
  Result := rc;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if IsArm64 and (not WizardSilent) then
    MsgBox('This is the ARM64 build. It is a beta: it has not been tested on real ARM64 hardware yet.' + #13#10 +
           'It needs 7-Zip for ARM64 with "Integrate 7-Zip to shell context menu" enabled.', mbInformation, MB_OK);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  // Unregister a previous version and restart Explorer so the old files are not locked
  RunPs('-Command "Get-AppxPackage -Name Djon934.ModernMenu7z | Remove-AppxPackage; Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2"');
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if RunPs('-File "' + ExpandConstant('{app}\install.ps1') + '" -Silent') <> 0 then
    begin
      RunPs('-File "' + ExpandConstant('{app}\uninstall.ps1') + '" -Silent');
      RaiseException('Could not register the Windows package. See the log: ' + ExpandConstant('{%TEMP}\ModernMenu7z-install.log'));
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RunPs('-File "' + ExpandConstant('{app}\uninstall.ps1') + '" -Silent');
end;
