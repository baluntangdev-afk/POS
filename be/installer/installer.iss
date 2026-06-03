; POS Kiosk — Inno Setup Installer Script
; Bundles: Flutter kiosk app + NestJS backend (POSBackend.exe) + Portable PostgreSQL 16
;
; ═══════════════════════════════════════════════════════════════════════
; BEFORE COMPILING — complete all steps in this order:
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
;      (already downloaded — contains bin\, lib\, share\, etc.)
;
;   5. Install Inno Setup 6 and run:
;      ISCC.exe be\installer\installer.iss
;      Output: be\installer\output\POSKiosk-Setup-1.0.0.exe
;
; ── What the installer does ────────────────────────────────────────────
;   1. Extracts Flutter app, backend exe, PostgreSQL binaries, NSSM
;   2. Initializes PostgreSQL data at C:\posdata (no spaces = no quoting issues)
;   3. Registers PostgreSQL as a native Windows service via pg_ctl
;      (runs as NT AUTHORITY\NetworkService — PostgreSQL rejects admin accounts)
;   4. Waits for PostgreSQL to be ready, then creates pos_db
;   5. Runs TypeORM migrations
;   6. Optionally seeds initial data
;   7. Installs NestJS backend as a Windows service via NSSM
;   8. Creates desktop shortcut and offers to launch the kiosk
;
; ── Install location ───────────────────────────────────────────────────
;   App : C:\POSKiosk      (no spaces — required for pg_ctl service registration)
;   Data: C:\posdata        (no spaces — avoids postgres argument-splitting bug)
;   Logs: C:\POSKiosk\logs\ (setup-postgres-install.log, run-migrations-install.log,
;                             install-backend-service-install.log,
;                             backend-output.log, backend-error.log)
; ═══════════════════════════════════════════════════════════════════════

#define MyAppName    "POS Kiosk"
#define MyAppVersion "1.0.0"
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
; No spaces in install path — required so pg_ctl can register postgres.exe as a service
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
Name: "runseeds";    Description: "Seed initial data (products, menus, users)"; GroupDescription: "First-time setup:"; Flags: unchecked

[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"

[Files]
; ── Flutter kiosk app ──────────────────────────────────────────────────
Source: "..\..\kiosk\build\windows\x64\runner\Release\{#KioskExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\*.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\data\*";       DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── NestJS backend ─────────────────────────────────────────────────────
Source: "..\{#BackendExe}"; DestDir: "{app}\backend"; Flags: ignoreversion
; .env.prod copied as .env — onlyifdoesntexist preserves custom config on upgrades
Source: "..\.env.prod"; DestDir: "{app}\backend"; DestName: ".env"; Flags: ignoreversion onlyifdoesntexist

; ── Visual C++ 2015-2022 Redistributable (x64) ────────────────────────
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall

; ── NSSM (service manager for the NestJS backend) ─────────────────────
Source: "C:\nssm\nssm.exe"; DestDir: "{app}\nssm"; Flags: ignoreversion

; ── Portable PostgreSQL 16 (bin/lib/share only — no pgAdmin) ──────────
; pg_ctl registers postgres.exe as a Windows service; the install path must
; have no spaces or the SCM binary-path entry will be malformed.
Source: "C:\pgsql\bin\*";   DestDir: "{app}\pgsql\bin";   Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\pgsql\lib\*";   DestDir: "{app}\pgsql\lib";   Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\pgsql\share\*"; DestDir: "{app}\pgsql\share"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── Installer helper scripts ───────────────────────────────────────────
Source: "scripts\setup-postgres.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\setup-postgres.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\run-migrations.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\run-migrations.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\install-backend-service.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\install-backend-service.bat"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\uninstall-services.ps1";      DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\uninstall-services.bat";      DestDir: "{app}\scripts"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";                       Filename: "{app}\{#KioskExe}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";                 Filename: "{app}\{#KioskExe}"; Tasks: desktopicon

[Run]
; Step 0 — Visual C++ 2015-2022 Redistributable (silent, skips if already installed)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated; StatusMsg: "Installing Visual C++ runtime..."

; Step 1 — Initialize PostgreSQL data dir, register + start service, create pos_db
;           Logs to: {app}\logs\setup-postgres-install.log
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NonInteractive -File ""{app}\scripts\setup-postgres.ps1"" -AppDir ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Setting up database (this may take a minute)..."

; Step 3 — Seed initial data (optional, unchecked by default)
Filename: "{app}\backend\{#BackendExe}"; Parameters: "--seed"; WorkingDir: "{app}\backend"; Flags: runhidden waituntilterminated; StatusMsg: "Seeding initial data..."; Tasks: runseeds

; Step 4 — Install NestJS backend as auto-start Windows service
;           Logs to: {app}\logs\install-backend-service-install.log
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NonInteractive -File ""{app}\scripts\install-backend-service.ps1"" -AppDir ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Installing backend service..."

; Step 5 — Offer to launch the kiosk
Filename: "{app}\{#KioskExe}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NonInteractive -File ""{app}\scripts\uninstall-services.ps1"" -AppDir ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated

[UninstallDelete]
; Remove PostgreSQL data directory on uninstall
Type: filesandordirs; Name: "C:\posdata"

[Code]
var
  KioskNoPage: TInputQueryWizardPage;

// Runs before file extraction — stops running services so locked files
// can be overwritten. This makes in-place upgrades work without uninstalling.
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  Exec('sc.exe',      'stop POSBackendService',    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill.exe','/F /IM pos_app.exe /T',     '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(2000);
end;

procedure InitializeWizard;
begin
  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1–999) for this machine. ' +
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
      'If the app cannot connect, check the install logs at:' + #13#10 +
      ExpandConstant('{app}\logs\'),
      mbInformation, MB_OK
    );
  end;
end;
