; POS Kiosk â€" Inno Setup Installer Script
; Bundles: Flutter kiosk app + NestJS backend (POSBackend.exe) + Portable PostgreSQL 16
;
; â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
; BEFORE COMPILING â€" complete all steps in this order:
;
;   0. Verify migrations and seeders are up to date  (cd be)
;      npm run migration:sync-index       <- sync migrations-index.ts with all migration files
;      npm run seed:sync-index            <- sync seeders-index.ts with all seeder files
;      npm run migration:show             <- confirm all migrations show [X] (none pending)
;      npm run build                      <- confirm both index files compile cleanly
;      See: be\docs\pre-installer-checklist.md for full details
;
;   1. Build backend executable
;      cd be
;      copy .env.example .env.prod        <- fill in prod values (JWT secrets etc.)
;      npm run build:sea                  -> produces be\POSBackend.exe
;
;   2. Build Flutter Windows app
;      cd kiosk
;      flutter build windows --release
;                                         -> kiosk\build\windows\x64\runner\Release\
;
;   3. NSSM is at C:\nssm\nssm.exe (already in place)
;
;   4. Portable PostgreSQL 16 binaries are at C:\pgsql\
;      (already downloaded â€" contains bin\, lib\, share\, etc.)
;
;   5. Install Inno Setup 6 and run:
;      ISCC.exe be\installer\installer.iss
;      Output: be\installer\output\POSKiosk-Setup-1.0.0.exe
;
; â"€â"€ What the installer does â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
;   1. Extracts Flutter app, backend exe, PostgreSQL binaries, NSSM
;   2. Initializes PostgreSQL data at C:\posdata (no spaces = no quoting issues)
;   3. Registers PostgreSQL as a native Windows service via pg_ctl
;      (runs as NT AUTHORITY\NetworkService â€" PostgreSQL rejects admin accounts)
;   4. Waits for PostgreSQL to be ready, then creates pos_db
;   5. Runs TypeORM migrations
;   6. Seeds initial data (admin user + reference data; idempotent, always runs)
;   7. Installs NestJS backend as a Windows service via NSSM
;   8. Creates desktop shortcut and offers to launch the kiosk
;
; â"€â"€ Install location â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
;   App : C:\POSKiosk      (no spaces â€" required for pg_ctl service registration)
;   Data: C:\posdata        (no spaces â€" avoids postgres argument-splitting bug)
;   Logs: C:\POSKiosk\logs\ (setup-postgres-install.log, run-migrations-install.log,
;                             install-backend-service-install.log,
;                             backend-output.log, backend-error.log)
; â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

#define MyAppName    "POS Kiosk"
#define MyAppVersion "1.1.8"
#define MyAppPublisher "Your Company"
#define KioskExe     "pos_app.exe"
#define BackendExe   "POSBackend.exe"
#define BackendSvc   "POSBackendService"
#define PostgresSvc  "POSPostgres"

[Setup]
AppId={{B2C3D4E5-F6A7-4B5C-9D0E-1F2A3B4C5D6E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
; No spaces in install path â€" required so pg_ctl can register postgres.exe as a service
DefaultDirName=C:\POSKiosk
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=output
OutputBaseFilename=POSKiosk-Setup-{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"

[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"

[Files]
; â"€â"€ Flutter kiosk app â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "..\..\kiosk\build\windows\x64\runner\Release\{#KioskExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\*.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\data\*";       DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; â"€â"€ NestJS backend â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "..\{#BackendExe}"; DestDir: "{app}\backend"; Flags: ignoreversion
; .env.prod copied as .env â€" onlyifdoesntexist preserves custom config on upgrades
Source: "..\.env.prod"; DestDir: "{app}\backend"; DestName: ".env"; Flags: ignoreversion onlyifdoesntexist

; â"€â"€ Visual C++ 2015-2022 Redistributable (x64) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall

; â"€â"€ NSSM (service manager for the NestJS backend) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "C:\nssm\nssm.exe"; DestDir: "{app}\nssm"; Flags: ignoreversion

; â"€â"€ Portable PostgreSQL 16 (bin/lib/share only â€" no pgAdmin) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
; pg_ctl registers postgres.exe as a Windows service; the install path must
; have no spaces or the SCM binary-path entry will be malformed.
Source: "C:\pgsql\bin\*";   DestDir: "{app}\pgsql\bin";   Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\pgsql\lib\*";   DestDir: "{app}\pgsql\lib";   Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\pgsql\share\*"; DestDir: "{app}\pgsql\share"; Flags: ignoreversion recursesubdirs createallsubdirs

; â"€â"€ Installer helper scripts â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "scripts\setup-postgres.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\setup-postgres.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\run-migrations.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\run-migrations.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\install-backend-service.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\install-backend-service.bat"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\uninstall-services.ps1";      DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\uninstall-services.bat";      DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\update-backend.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\update-backend.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\recover-services.bat";        DestDir: "{app}\scripts"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";                       Filename: "{app}\{#KioskExe}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";                 Filename: "{app}\{#KioskExe}"; Tasks: desktopicon

[Run]
; Step 0 — Visual C++ 2015-2022 Redistributable (silent, skips if already installed)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated; StatusMsg: "Installing Visual C++ runtime..."

; Step 1 — Initialize PostgreSQL data dir, register + start service, create pos_db
;           Logs to: {app}\logs\setup-postgres-install.log
;           Uses cmd.exe → .bat wrapper so powershell.exe is found via PATH (avoids
;           {sys} resolving to SysWOW64 in 32-bit installer processes).
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\setup-postgres.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Setting up database (this may take a minute)..."

; Step 2 — Run TypeORM migrations
;           Logs to: {app}\logs\run-migrations-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\run-migrations.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Running database migrations..."

; NOTE: Seeding is no longer a separate optional step. setup-postgres.ps1 (Step 1,
;       and recover-services.bat) now always seeds after migrations. Seeders are
;       idempotent, so this guarantees the admin user / reference data exist on every
;       install and every recovery without the user having to tick a checkbox.

; Step 4 — Install NestJS backend as auto-start Windows service
;           Logs to: {app}\logs\install-backend-service-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\install-backend-service.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Installing backend service..."

; Step 5 — Offer to launch the kiosk
Filename: "{app}\{#KioskExe}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\uninstall-services.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated

[UninstallDelete]
; Remove PostgreSQL data directory on uninstall
Type: filesandordirs; Name: "C:\posdata"

[Code]
var
  KioskNoPage: TInputQueryWizardPage;

// Guard for the optional seeding step — skips silently if the exe wasn't extracted.
function BackendExeExists(): Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\backend\{#BackendExe}'));
end;

// Runs before file extraction — stops running services so locked files
// can be overwritten. This makes in-place upgrades work without uninstalling.
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  Exec('sc.exe',      'stop POSBackendService',    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe',      'stop POSPostgres',          '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill.exe','/F /IM pos_app.exe /T',     '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(3000);
end;

procedure InitializeWizard;
begin
  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1â€"999) for this machine. ' +
    'It appears in all sales order numbers generated here, e.g. SO-001-2026-0001.'
  );
  KioskNoPage.Add('Kiosk Number:', False);
  KioskNoPage.Values[0] := '1';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  KioskNo: String;
  Val: Integer;
begin
  Result := True;
  if CurPageID = KioskNoPage.ID then begin
    KioskNo := Trim(KioskNoPage.Values[0]);
    if KioskNo = '' then begin
      MsgBox('Please enter a kiosk number.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    Val := StrToIntDef(KioskNo, 0);
    if (Val < 1) or (Val > 999) then begin
      MsgBox('Kiosk number must be a whole number between 1 and 999.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsPath: String;
begin
  if CurStep = ssPostInstall then begin
    SettingsPath := ExpandConstant('{app}\settings.txt');
    SaveStringToFile(SettingsPath, 'kiosk.no=' + Trim(KioskNoPage.Values[0]), False);
  end;

  if CurStep = ssDone then begin
    MsgBox(
      'Installation complete.' + #13#10 + #13#10 +
      'IMPORTANT: A full system restart is required for all services' + #13#10 +
      'to start correctly. Please restart this computer before' + #13#10 +
      'launching the kiosk.' + #13#10 + #13#10 +
      'If the app cannot connect after restarting, check the install' + #13#10 +
      'logs at:' + #13#10 +
      ExpandConstant('{app}\logs\'),
      mbInformation, MB_OK
    );
  end;
end;

function NeedRestart(): Boolean;
begin
  Result := True;
end;



















