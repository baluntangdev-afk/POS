; Inno Setup Script for POS Backend
; Compile this script using Inno Setup Compiler to create the installer
; Script is located in installer/ - source paths are relative to project root (..\)

#define MyAppName "POS Backend"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company Name"
#define MyAppURL "https://www.yourcompany.com"
#define MyAppExeName "pos-backend.exe"
#define MyAppServiceName "POSBackendService"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
AppId={{A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
; Output goes to installer/output/ when script is in installer/
OutputDir=output
OutputBaseFilename=POSBackend-Setup-{#MyAppVersion}
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "installdeps"; Description: "Install Java JDK 17+, PostgreSQL 16, and create database pos_db"; GroupDescription: "Dependencies (requires internet and admin)"; Flags: unchecked
Name: "installservice"; Description: "Install as Windows Service (using NSSM)"; GroupDescription: "Service Options"; Flags: checked
Name: "runmigrations"; Description: "Run database migrations after installation"; GroupDescription: "Database Setup"; Flags: checked

[Files]
; Main executable (relative to script dir: installer/ -> ..\ = project root)
Source: "..\pos-backend.exe"; DestDir: "{app}"; Flags: ignoreversion
; Environment file
Source: "..\.env.prod"; DestDir: "{app}"; DestName: ".env"; Flags: ignoreversion onlyifdoesntexist
; NSSM for service installation (download from https://nssm.cc/download and place in project root nssm folder)
Source: "..\nssm\*"; DestDir: "{app}\nssm"; Flags: ignoreversion recursesubdirs createallsubdirs; Tasks: installservice
; Migration and seed scripts
Source: "..\scripts\run-migrations.bat"; DestDir: "{app}\scripts"; Flags: ignoreversion; Tasks: runmigrations
Source: "..\scripts\run-seeders.bat"; DestDir: "{app}\scripts"; Flags: ignoreversion; Tasks: runmigrations
; Java + PostgreSQL + create DB script (run by installer if task selected)
Source: "scripts\install-deps.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion; Tasks: installdeps
Source: "scripts\install-deps.bat"; DestDir: "{app}\scripts"; Flags: ignoreversion; Tasks: installdeps

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Install Java, PostgreSQL, create pos_db (if selected; runs first so DB exists before app)
Filename: "{app}\scripts\install-deps.bat"; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Installing Java JDK, PostgreSQL, and creating database pos_db..."; Tasks: installdeps
; Install as Windows Service (if selected)
Filename: "{app}\nssm\nssm.exe"; Parameters: "install {#MyAppServiceName} ""{app}\{#MyAppExeName}"""; WorkingDir: "{app}"; Flags: runhidden; StatusMsg: "Installing Windows Service..."; Tasks: installservice
; Set service working directory
Filename: "{app}\nssm\nssm.exe"; Parameters: "set {#MyAppServiceName} AppDirectory ""{app}"""; Flags: runhidden; Tasks: installservice
; Set service to auto-start
Filename: "{app}\nssm\nssm.exe"; Parameters: "set {#MyAppServiceName} Start SERVICE_AUTO_START"; Flags: runhidden; Tasks: installservice
; Set output log file
Filename: "{app}\nssm\nssm.exe"; Parameters: "set {#MyAppServiceName} AppStdout ""{app}\logs\output.log"""; Flags: runhidden; Tasks: installservice
Filename: "{app}\nssm\nssm.exe"; Parameters: "set {#MyAppServiceName} AppStderr ""{app}\logs\error.log"""; Flags: runhidden; Tasks: installservice
; Start the service
Filename: "{app}\nssm\nssm.exe"; Parameters: "start {#MyAppServiceName}"; Flags: runhidden; StatusMsg: "Starting Windows Service..."; Tasks: installservice

[UninstallRun]
; Stop and remove the service before uninstalling
Filename: "{app}\nssm\nssm.exe"; Parameters: "stop {#MyAppServiceName}"; Flags: runhidden
Filename: "{app}\nssm\nssm.exe"; Parameters: "remove {#MyAppServiceName} confirm"; Flags: runhidden

[Code]
procedure InitializeWizard;
begin
  // Create logs directory during installation
  CreateDir(ExpandConstant('{app}\logs'));
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  // Stop service before uninstall
  Exec(ExpandConstant('{app}\nssm\nssm.exe'), 'stop {#MyAppServiceName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
