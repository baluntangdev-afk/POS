; POS Kiosk — Inno Setup Installer Script
; Bundles: Flutter kiosk app + NestJS backend (POSBackend.exe) + Portable PostgreSQL 16
;
; ═══════════════════════════════════════════════════════════════════════
; BEFORE COMPILING — the normal path is the one-click builder from the repo root,
; which does steps 1, 2 and 5 below (and checks the rest):
;      .\build-installer.bat
;      .\build-installer.ps1 -Version 1.1.0 -Mode Offline
;
; Manual steps, in this order:
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
;      flutter build windows --release --dart-define=SKIP_DEVICE_REGISTRATION=false
;                                         -> kiosk\build\windows\x64\runner\Release\
;      (true for the Offline flavor; kiosk\.env is compiled into the binary)
;
;   3. NSSM is at C:\nssm\nssm.exe (already in place)
;
;   4. Portable PostgreSQL 16 binaries are at C:\pgsql\
;      (already downloaded — contains bin\, lib\, share\, etc.)
;
;   5. Install Inno Setup 6 and run:
;      ISCC.exe /DMyAppFlavor=Online be\installer\installer.iss
;      Output: be\installer\output\POSKiosk-Setup-<version>-<Online|Offline>.exe
;
; ── What the installer does ────────────────────────────────────────────
;   1. Extracts Flutter app, backend exe, PostgreSQL binaries, NSSM
;   2. Initializes PostgreSQL data at C:\posdata (no spaces = no quoting issues)
;   3. Registers PostgreSQL as a native Windows service via pg_ctl
;      (runs as NT AUTHORITY\NetworkService — PostgreSQL rejects admin accounts)
;   4. Waits for PostgreSQL to be ready, then creates pos_db
;   5. Runs TypeORM migrations
;   6. Seeds initial data (admin user + reference data; idempotent, always runs)
;   7. Installs NestJS backend as a Windows service via NSSM
;   8. Registers a daily 2 AM Scheduled Task that backs up pos_db + config to
;      {app}\Backups (see backup-database.ps1 / register-backup-task.ps1)
;   9. Creates desktop shortcut and offers to launch the kiosk
;
; ── Install location ───────────────────────────────────────────────────
;   App : C:\POSKiosk      (no spaces — required for pg_ctl service registration)
;   Data: C:\posdata        (no spaces — avoids postgres argument-splitting bug)
;   Logs: C:\POSKiosk\logs\ (setup-postgres-install.log, run-migrations-install.log,
;                             install-backend-service-install.log,
;                             backend-output.log, backend-error.log)
; ═══════════════════════════════════════════════════════════════════════

#define MyAppName    "POS Kiosk"
#define MyAppVersion "4.0.0"
#define MyAppPublisher "Your Company"
#define KioskExe     "pos_app.exe"
#define BackendExe   "POSBackend.exe"
#define BackendSvc   "POSBackendService"
#define PostgresSvc  "POSPostgres"
; Build flavor - passed by build-installer.ps1 as /DMyAppFlavor=Offline|Online.
; Only affects the output filename; the Flutter binary is compiled per flavor.
#ifndef MyAppFlavor
  #define MyAppFlavor "Online"
#endif

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
OutputBaseFilename=POSKiosk-Setup-{#MyAppVersion}-{#MyAppFlavor}
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
Name: "autologon";   Description: "Automatically sign in and launch the kiosk after every restart (recommended for dedicated POS terminals)"

[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"
Name: "{app}\data\csv"
Name: "{app}\backend\public"
; Daily pos_db backups (backup-database.ps1) + kiosk transaction/report PDF archive.
; Deliberately NOT listed in [UninstallDelete] -- see the note there.
Name: "{app}\Backups\config"
Name: "{app}\History"

[Files]
; ── Flutter kiosk app ──────────────────────────────────────────────────
Source: "..\..\kiosk\build\windows\x64\runner\Release\{#KioskExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\*.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\data\*";       DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── NestJS backend ─────────────────────────────────────────────────────
Source: "..\{#BackendExe}"; DestDir: "{app}\backend"; Flags: ignoreversion
; .env.prod copied as .env — onlyifdoesntexist preserves custom config on upgrades
Source: "..\.env.prod"; DestDir: "{app}\backend"; DestName: ".env"; Flags: ignoreversion onlyifdoesntexist
; On upgrades the existing .env is kept, so append any keys added to .env.prod
; since then (existing values are never touched). Must stay after the entry above.
Source: "..\.env.prod"; DestDir: "{tmp}"; DestName: "env.prod.template"; Flags: ignoreversion deleteafterinstall; AfterInstall: MergeMissingEnvKeys
; Static assets (product images) served by the backend at /static/*. AppDirectory
; for POSBackendService is {app}\backend, so process.cwd()\public resolves here.
Source: "..\public\*"; DestDir: "{app}\backend\public"; Flags: ignoreversion recursesubdirs createallsubdirs

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
Source: "scripts\update-backend.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\update-backend.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\recover-services.bat";        DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\fix-service-recovery.bat";   DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\configure-security.ps1";      DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\configure-autologon.ps1";     DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\configure-autologon.bat";     DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\seed-from-csv.ps1";           DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\seed-from-csv.bat";           DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\stop-services.ps1";           DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\stop-services.bat";           DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\start-services.ps1";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\start-services.bat";          DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\backup-database.ps1";         DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\backup-database.bat";         DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\register-backup-task.ps1";    DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\register-backup-task.bat";    DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\restore-database.ps1";        DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\restore-database.bat";        DestDir: "{app}\scripts"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";                       Filename: "{app}\{#KioskExe}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";                 Filename: "{app}\{#KioskExe}"; Tasks: desktopicon
; Auto-launch the kiosk UI for every user who logs in (backend/DB services already
; auto-start on their own; this makes the visible app come up too, so a machine
; reboot ends with the kiosk on screen instead of just background services running).
Name: "{commonstartup}\{#MyAppName}";                Filename: "{app}\{#KioskExe}"

[Run]
; Step 0 — Visual C++ 2015-2022 Redistributable (silent, skips if already installed)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated; StatusMsg: "Installing Visual C++ runtime..."

; Step 0b — Firewall rule + Windows Defender exclusion
;            Adds an inbound TCP rule for port 3000 and excludes {app} from
;            real-time scanning so the unsigned backend exe is never quarantined
;            or scan-locked on first launch (the most common cause of the kiosk
;            staying stuck on "Starting up..." on a fresh machine).
;            Logs to: {app}\logs\configure-security-install.log
Filename: "{cmd}"; Parameters: "/c powershell.exe -ExecutionPolicy Bypass -NonInteractive -File ""{app}\scripts\configure-security.ps1"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Configuring Windows Firewall and Defender..."

; Step 0b2 — Best-effort: disable the "TabletInputService" (Touch Keyboard and
;            Handwriting Panel Service) for Windows builds where it still
;            exists (older Windows 10/11). Confirmed via `sc query` on a
;            Windows 11 23H2 (build 22631) test machine that this service no
;            longer exists there at all (error 1060) — Microsoft has removed
;            it on newer builds, and TextInputHost.exe launches through some
;            other path that doesn't depend on it. Left in as a no-op-when-
;            absent defense layer for any older machines in the fleet; the
;            IFEO block below (Step 0b3) is what actually stops it on 23H2+.
Filename: "{cmd}"; Parameters: "/c sc stop TabletInputService & sc config TabletInputService start= disabled"; Flags: runhidden waituntilterminated; StatusMsg: "Disabling Windows touch keyboard (legacy path)..."

; Step 0b3 — Block TextInputHost.exe (and legacy TabTip.exe) from ever
;            launching at all, via Image File Execution Options "Debugger"
;            redirection. Whatever internal mechanism this Windows build
;            uses to decide when to show the OS touch keyboard (heuristic,
;            TSF connection, raw touch event, service, or something else
;            entirely — confirmed on this fleet's Windows 11 23H2 machines
;            that it is NOT gated by TabletInputService any more), all of
;            those paths ultimately do the same thing: ask the OS loader to
;            start the TextInputHost.exe/TabTip.exe process. IFEO is
;            enforced by the loader itself for any process with that image
;            name, regardless of caller, so pointing "Debugger" at a path
;            that does not exist makes every such launch attempt fail
;            immediately and silently — nothing to race, nothing to poll for,
;            because the process itself never starts. This is what finally
;            replaces every prior reactive layer (SW_HIDE/SC_CLOSE window
;            tricks, the focus-driven native poll-and-close guard,
;            EnableDesktopModeAutoInvoke=0, and the TabletInputService
;            disable above) that could only ever race Windows' own decision
;            to show it and kept losing that race. Safe on a dedicated kiosk
;            terminal: this app draws its own on-screen keyboard (see
;            kiosk\lib\widgets\onscreen_keyboard\) and never needs the emoji
;            panel or clipboard-history flyout TextInputHost.exe also hosts.
Filename: "{cmd}"; Parameters: "/c reg add ""HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TextInputHost.exe"" /v Debugger /t REG_SZ /d ""{app}\blocked-by-kiosk.exe"" /f & reg add ""HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TabTip.exe"" /v Debugger /t REG_SZ /d ""{app}\blocked-by-kiosk.exe"" /f & taskkill /F /IM TextInputHost.exe /T & taskkill /F /IM TabTip.exe /T"; Flags: runhidden waituntilterminated; StatusMsg: "Blocking Windows touch keyboard..."

; Step 0c — Create a dedicated kiosk Windows account and configure auto sign-in,
;            so the machine comes all the way back up (services + the visible
;            app, via the {commonstartup} shortcut below) after an unattended
;            reboot. Opt-in via the "autologon" task selected during setup.
;            Logs to: {app}\logs\configure-autologon-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\configure-autologon.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Configuring automatic sign-in..."; Tasks: autologon

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
;       Product catalog import moved in-app (Inventory Management > Import CSV) —
;       see recover-services.bat / seed-from-csv.bat for the disaster-recovery path.

; Step 3 — Install NestJS backend as auto-start Windows service
;           Logs to: {app}\logs\install-backend-service-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\install-backend-service.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Installing backend service..."

; Step 3b — Register the daily database backup Scheduled Task
;           (POSKioskDatabaseBackup, runs backup-database.bat at 2:00 AM as SYSTEM)
;           Logs to: {app}\logs\register-backup-task-install.log
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\register-backup-task.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Scheduling daily database backups..."

; Step 4 — Offer to launch the kiosk
Filename: "{app}\{#KioskExe}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\uninstall-services.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated

[InstallDelete]
; Wipe the scripts folder before extraction so removed/renamed scripts never linger
Type: filesandordirs; Name: "{app}\scripts"

[UninstallDelete]
; Remove PostgreSQL data directory on uninstall
Type: filesandordirs; Name: "C:\posdata"
; Remove CSV recovery files dropped into {app}\data\csv at runtime (not logged
; by Inno Setup since they're not part of [Files], so they'd otherwise linger)
Type: filesandordirs; Name: "{app}\data"
; Do NOT add {app}\Backups or {app}\History here. Uninstalling (e.g. for a "clean
; reinstall" during troubleshooting) already wipes C:\posdata above -- the backups
; and the transaction/report PDF archive are exactly what should survive that.

[Code]
var
  KioskNoPage: TInputQueryWizardPage;
  KioskNoPrefilled: Boolean;

// Reads "kiosk.no=<n>" from an existing {app}\settings.txt (upgrade/reinstall).
// Returns '' on a fresh install. Only valid once {app} is known (after wpSelectDir).
function ReadExistingKioskNo(): String;
var
  Lines: TArrayOfString;
  i: Integer;
  Line: String;
begin
  Result := '';
  if not LoadStringsFromFile(ExpandConstant('{app}\settings.txt'), Lines) then Exit;
  for i := 0 to GetArrayLength(Lines) - 1 do
  begin
    Line := Trim(Lines[i]);
    if Pos('kiosk.no=', Lowercase(Line)) = 1 then
    begin
      Result := Trim(Copy(Line, Length('kiosk.no=') + 1, Length(Line)));
      Exit;
    end;
  end;
end;

// Pre-fills the kiosk number with the machine's current one so clicking through
// an upgrade can't silently renumber the terminal (order numbers embed it).
procedure PrefillKioskNo();
var
  Existing: String;
begin
  if KioskNoPrefilled then Exit;
  KioskNoPrefilled := True;
  Existing := ReadExistingKioskNo();
  if Existing <> '' then
    KioskNoPage.Values[0] := Existing;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = KioskNoPage.ID then
    PrefillKioskNo();
end;

// Returns the KEY part of a "KEY=value" line, or '' for comments/blank lines.
function EnvLineKey(Line: String): String;
var
  EqPos: Integer;
begin
  Result := '';
  Line := Trim(Line);
  if (Line = '') or (Copy(Line, 1, 1) = '#') then Exit;
  EqPos := Pos('=', Line);
  if EqPos > 1 then
    Result := Trim(Copy(Line, 1, EqPos - 1));
end;

// AfterInstall for the env.prod.template entry: appends every key present in
// the bundled .env.prod but missing from the installed {app}\backend\.env.
// Existing keys/values are left exactly as they are.
procedure MergeMissingEnvKeys();
var
  EnvPath: String;
  Template, Existing, ToAppend: TArrayOfString;
  i, j, Count: Integer;
  Key: String;
  Found: Boolean;
begin
  EnvPath := ExpandConstant('{app}\backend\.env');
  if not LoadStringsFromFile(ExpandConstant('{tmp}\env.prod.template'), Template) then Exit;
  if not LoadStringsFromFile(EnvPath, Existing) then Exit;

  Count := 0;
  for i := 0 to GetArrayLength(Template) - 1 do
  begin
    Key := EnvLineKey(Template[i]);
    if Key = '' then Continue;
    Found := False;
    for j := 0 to GetArrayLength(Existing) - 1 do
      if CompareText(EnvLineKey(Existing[j]), Key) = 0 then
      begin
        Found := True;
        Break;
      end;
    if not Found then
    begin
      if Count = 0 then
      begin
        // Leading blank line guards against an existing file with no trailing newline.
        SetArrayLength(ToAppend, 2);
        ToAppend[0] := '';
        ToAppend[1] := '# Added by installer {#MyAppVersion}';
        Count := 2;
      end;
      SetArrayLength(ToAppend, Count + 1);
      ToAppend[Count] := Trim(Template[i]);
      Count := Count + 1;
    end;
  end;

  if Count > 0 then
    SaveStringsToFile(EnvPath, ToAppend, True);
end;

// Guard for the optional seeding step — skips silently if the exe wasn't extracted.
function BackendExeExists(): Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\backend\{#BackendExe}'));
end;

// Polls until the named service reports STOPPED or the timeout (seconds) expires.
// Uses "sc query | find" — find exits 0 when "STOPPED" appears in the output.
procedure WaitForServiceStopped(ServiceName: String; TimeoutSecs: Integer);
var
  ResultCode, i: Integer;
begin
  for i := 1 to TimeoutSecs do
  begin
    // find exits 0 if "STOPPED" is present in sc query output
    Exec('cmd.exe',
         '/c sc query "' + ServiceName + '" | find "STOPPED" > nul 2>&1',
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    if ResultCode = 0 then Exit;
    // sc.exe exits 1060 when the service does not exist — treat as stopped
    Exec('sc.exe', 'query "' + ServiceName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    if ResultCode = 1060 then Exit;
    Sleep(1000);
  end;
end;

// Runs before file extraction — stops running services so locked files
// can be overwritten. This makes in-place upgrades work without uninstalling.
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  Exec('taskkill.exe', '/F /IM pos_app.exe /T',  '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe',       'stop POSBackendService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  WaitForServiceStopped('POSBackendService', 15);
  Exec('sc.exe',       'stop POSPostgres',       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  // PostgreSQL can take 10-20s to fully release its DLL locks — wait properly.
  WaitForServiceStopped('POSPostgres', 30);
  Sleep(1000);
end;

procedure InitializeWizard;
begin
  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1-999) for this machine. ' +
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

  // ── Kiosk Number validation ───────────────────────────────────────────
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

// Returns True only if the named service exists AND is RUNNING.
// "sc query | find RUNNING" exits 0 when the service is running.
function ServiceIsRunning(ServiceName: String): Boolean;
var
  ResultCode: Integer;
begin
  Exec('cmd.exe',
       '/c sc query "' + ServiceName + '" | find "RUNNING" > nul 2>&1',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsPath: String;
begin
  if CurStep = ssPostInstall then begin
    // Silent installs never show the kiosk page — keep the existing number then.
    PrefillKioskNo();
    SettingsPath := ExpandConstant('{app}\settings.txt');
    SaveStringToFile(SettingsPath, 'kiosk.no=' + Trim(KioskNoPage.Values[0]), False);

    // Verify the database + backend services actually came up. Inno's [Run]
    // steps ignore script exit codes, so without this check a failed DB setup
    // (e.g. a stale service that locked files during initdb) would report a
    // "successful" install while the kiosk hangs forever on "Starting
    // services". Surface it with an actionable recovery instruction instead.
    if (not ServiceIsRunning('POSPostgres')) or (not ServiceIsRunning('POSBackendService')) then begin
      MsgBox(
        'Setup finished, but the database/backend services did not start.' + #13#10 + #13#10 +
        'This is recoverable. After installation closes:' + #13#10 +
        '  1. Open ' + ExpandConstant('{app}\scripts') + #13#10 +
        '  2. Right-click recover-services.bat -> "Run as administrator"' + #13#10 + #13#10 +
        'Details are in ' + ExpandConstant('{app}\logs\') + '.',
        mbError, MB_OK
      );
    end;
  end;

  if CurStep = ssDone then begin
    MsgBox(
      'Installation complete.' + #13#10 + #13#10 +
      'You can now launch the kiosk from the desktop shortcut.' + #13#10 + #13#10 +
      'If the app cannot connect, check the install logs at:' + #13#10 +
      ExpandConstant('{app}\logs\'),
      mbInformation, MB_OK
    );
  end;
end;

function NeedRestart(): Boolean;
begin
  Result := False;
end;


































































































