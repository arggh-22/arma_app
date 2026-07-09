; Inno Setup script for Arma VPN (Windows).
; Produces a Setup.exe from the Flutter release bundle. Invoked by CI:
;   ISCC /DMyAppVersion=1.2.3 /DTargetArch=x64compatible /DArchTag=x64 installer.iss
;   ISCC /DMyAppVersion=1.2.3 /DTargetArch=arm64        /DArchTag=arm64 installer.iss
; Relative paths resolve from this script's dir (packaging\windows).

#define MyAppName "Arma VPN"
#define MyAppPublisher "Arma VPN"
#define MyAppExeName "arma_proxy_vpn_client.exe"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef TargetArch
  #define TargetArch "x64compatible"
#endif
#ifndef ArchTag
  #define ArchTag "x64"
#endif
; Flutter's release bundle dir differs by arch (build\windows\x64\... vs
; \arm64\...); CI passes the resolved path.
#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; Stable AppId so upgrades replace the same install / uninstall entry.
AppId={{7B2E9C10-4A6F-4B3D-9C2E-1F5A8D3B6E20}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\ArmaVPN
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\..\dist
OutputBaseFilename=ArmaVPN-{#MyAppVersion}-windows-{#ArchTag}-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed={#TargetArch}
ArchitecturesInstallIn64BitMode={#TargetArch}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The entire Flutter release bundle (exe + DLLs + data\).
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
