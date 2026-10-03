#define AppName "LyraERP"
#define AppVersion "0.1.0"
#define AppPublisher "LyraERP"

[Setup]
AppId={{B3D4C6F1-1D39-4D62-9A43-2F1E2A4A0F11}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\LyraERP
DefaultGroupName=LyraERP
OutputDir=output
OutputBaseFilename=LyraERP-Setup
Compression=lzma2/max
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
Uninstallable=yes
DisableProgramGroupPage=yes

[Files]
Source: "app\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "php\*"; DestDir: "{app}\php"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "tools\nssm.exe"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\LyraERP"; Filename: "{app}\LyraERP.cmd"
Name: "{commondesktop}\LyraERP"; Filename: "{app}\LyraERP.cmd"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install.ps1"" -Config ""{app}\install-config.ini"""; Flags: runhidden waituntilterminated
Filename: "{sys}\cmd.exe"; Parameters: "/c start ""LyraERP"" ""http://127.0.0.1:8090"""; Description: "Launch LyraERP"; Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "{app}\tools\nssm.exe"; Parameters: "stop LyraERP confirm"; Flags: runhidden
Filename: "{app}\tools\nssm.exe"; Parameters: "remove LyraERP confirm"; Flags: runhidden

[Code]
var
  AdminPage: TInputQueryWizardPage;
  PasswordPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  AdminPage := CreateInputQueryPage(wpSelectDir, 'LyraERP administrator', 'Create the first administrator account', 'Enter the email address for the first administrator account.');
  AdminPage.Add('Email:', False);
  PasswordPage := CreateInputQueryPage(AdminPage.ID, 'Administrator password', 'Choose a password', 'Use at least 8 characters.');
  PasswordPage.Add('Password:', True);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var ConfigPath: String;
begin
  Result := True;
  if CurPageID = PasswordPage.ID then
  begin
    if Length(PasswordPage.Values[0]) < 8 then
    begin
      MsgBox('The administrator password must contain at least 8 characters.', mbError, MB_OK);
      Result := False;
      exit;
    end;
    if Trim(AdminPage.Values[0]) = '' then
    begin
      MsgBox('Please enter an administrator email address.', mbError, MB_OK);
      Result := False;
      exit;
    end;
    ConfigPath := ExpandConstant('{app}\install-config.ini');
    SetIniString('LyraERP', 'AdminName', 'Administrator', ConfigPath);
    SetIniString('LyraERP', 'AdminEmail', AdminPage.Values[0], ConfigPath);
    SetIniString('LyraERP', 'AdminPassword', PasswordPage.Values[0], ConfigPath);
  end;
end;
