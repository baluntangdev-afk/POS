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
#define MyAppVersion "2.0.1"
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
Name: "autologon";   Description: "Automatically sign in and launch the kiosk after every restart (recommended for dedicated POS terminals)"

[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\pgsql"
Name: "{app}\nssm"
Name: "{app}\scripts"
Name: "{app}\data\csv"
Name: "{app}\backend\public"

[Files]
; â"€â"€ Flutter kiosk app â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "..\..\kiosk\build\windows\x64\runner\Release\{#KioskExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\*.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\kiosk\build\windows\x64\runner\Release\data\*";       DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; â"€â"€ NestJS backend â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
Source: "..\{#BackendExe}"; DestDir: "{app}\backend"; Flags: ignoreversion
; .env.prod copied as .env â€" onlyifdoesntexist preserves custom config on upgrades
Source: "..\.env.prod"; DestDir: "{app}\backend"; DestName: ".env"; Flags: ignoreversion onlyifdoesntexist
; Static assets (product images) served by the backend at /static/*. AppDirectory
; for POSBackendService is {app}\backend, so process.cwd()\public resolves here.
Source: "..\public\*"; DestDir: "{app}\backend\public"; Flags: ignoreversion recursesubdirs createallsubdirs

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

; ── CSV template (reference only — kept OUT of {app}\data\csv so it is not seeded) ──
Source: "products-template.csv"; DestDir: "{app}\data"; Flags: ignoreversion onlyifdoesntexist

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

; Step 3 - Seed store catalog from imported CSV files
;           Logs to: {app}\logs\seed-csv-install.log

;           Check: only runs on a fresh install — upgrades keep the existing catalog.
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\seed-from-csv.bat"" ""{app}"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Importing product catalog from CSV..."; Check: ShouldSeedCsv

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

[InstallDelete]
; Wipe the scripts folder before extraction so removed/renamed scripts never linger
Type: filesandordirs; Name: "{app}\scripts"

[UninstallDelete]
; Remove PostgreSQL data directory on uninstall
Type: filesandordirs; Name: "C:\posdata"
; Remove imported CSV seed files and the reference template (copied in at runtime,
; so Inno Setup did not log them and would otherwise leave them behind)
Type: filesandordirs; Name: "{app}\data"

[Code]
var
  KioskNoPage: TInputQueryWizardPage;
  CsvImportPage: TWizardPage;
  CsvListBox: TListBox;
  CsvStatusLabel: TLabel;
  CsvFullPaths: TStringList;
  // True when an initialized PostgreSQL data dir already exists (i.e. this is an
  // in-place upgrade, not a fresh install). Set in InitializeWizard. When True the
  // CSV catalog-import page is skipped and the authoritative CSV re-seed is NOT run,
  // so a version update never touches the store's existing catalog.
  IsUpgradeInstall: Boolean;

// True only on a fresh install — gates the CSV seed [Run] step so upgrades skip it.
function ShouldSeedCsv(): Boolean;
begin
  Result := not IsUpgradeInstall;
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

// ── CSV Import Page helpers ───────────────────────────────────────────────

const
  PRODUCTS_CSV_HEADER = 'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price';
  PRODUCTS_CSV_HEADER_WITH_IMAGE = 'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price,Product Image URL';
  MODIFIERS_CSV_HEADER = 'Modifier Group Name,Group Description,Selection Type,Is Required,Min Selection,Max Selection,Linked Product Group,Option Name,Option Price Add-On,Option Available';

function DetectCsvSchema(FilePath: String): String;
var
  Lines: TArrayOfString;
  Header: String;
begin
  Result := 'unknown';
  if not LoadStringsFromFile(FilePath, Lines) then Exit;
  if GetArrayLength(Lines) = 0 then Exit;
  Header := Trim(Lines[0]);
  // Strip a leading BOM character if present
  if (Length(Header) > 0) and (Ord(Header[1]) = 65279) then
    Header := Copy(Header, 2, Length(Header));
  if (Header = PRODUCTS_CSV_HEADER) or (Header = PRODUCTS_CSV_HEADER_WITH_IMAGE) then
    Result := 'products'
  else if Header = MODIFIERS_CSV_HEADER then
    Result := 'modifiers';
end;

function CountCsvDataRows(FilePath: String): Integer;
var
  Lines: TArrayOfString;
begin
  Result := 0;
  if LoadStringsFromFile(FilePath, Lines) then
    Result := GetArrayLength(Lines) - 1; // minus header
end;

procedure UpdateCsvStatus;
var
  I: Integer;
  FilePath, Schema, DisplayText: String;
  HasKnown, HasErrors: Boolean;
begin
  HasKnown := False;
  HasErrors := False;

  CsvListBox.Items.Clear;

  for I := 0 to CsvFullPaths.Count - 1 do
  begin
    FilePath := CsvFullPaths[I];
    Schema := DetectCsvSchema(FilePath);

    if (Schema = 'products') or (Schema = 'modifiers') then
    begin
      if CountCsvDataRows(FilePath) > 0 then
      begin
        if Schema = 'modifiers' then
          DisplayText := '[Valid] ' + ExtractFileName(FilePath) + ' — Modifier Groups / Options'
        else
          DisplayText := '[Valid] ' + ExtractFileName(FilePath) + ' — Products / Categories / Variants';
        HasKnown := True;
      end
      else
      begin
        DisplayText := '[Error] ' + ExtractFileName(FilePath) + ' — No data rows found';
        HasErrors := True;
      end;
    end
    else
      DisplayText := '[Warning] ' + ExtractFileName(FilePath) + ' — Unknown schema';

    CsvListBox.Items.Add(DisplayText);
  end;

  if CsvFullPaths.Count = 0 then
    CsvStatusLabel.Caption := 'No CSV files added. At least one recognized CSV is required.'
  else if HasErrors then
    CsvStatusLabel.Caption := 'One or more CSV files have errors. Please fix or remove them.'
  else if not HasKnown then
    CsvStatusLabel.Caption := 'No recognized CSV files. Add a file matching a known schema.'
  else
    CsvStatusLabel.Caption := 'Ready. Recognized CSV files will be imported during installation.';
end;

procedure AddCsvButtonClick(Sender: TObject);
var
  TempScript, TempOutput: String;
  ResultCode, I: Integer;
  Lines: TArrayOfString;
  FilePath: String;
begin
  TempScript := ExpandConstant('{tmp}\open_csv.ps1');
  TempOutput := ExpandConstant('{tmp}\csv_paths.txt');
  DeleteFile(TempOutput);

  SaveStringToFile(TempScript,
    'Add-Type -AssemblyName System.Windows.Forms' + #13#10 +
    '$d = New-Object System.Windows.Forms.OpenFileDialog' + #13#10 +
    '$d.Filter = "CSV files (*.csv)|*.csv"' + #13#10 +
    '$d.Title = "Select CSV files for POS data import"' + #13#10 +
    '$d.Multiselect = $true' + #13#10 +
    'if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {' + #13#10 +
    '  [System.IO.File]::WriteAllLines("' + TempOutput + '", $d.FileNames)' + #13#10 +
    '}',
    False);

  Exec('powershell.exe',
    '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + TempScript + '"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  if FileExists(TempOutput) and LoadStringsFromFile(TempOutput, Lines) then
  begin
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      FilePath := Trim(Lines[I]);
      if FilePath = '' then Continue;
      if not FileExists(FilePath) then Continue;
      if CsvFullPaths.IndexOf(FilePath) >= 0 then Continue; // skip duplicates
      CsvFullPaths.Add(FilePath);
    end;
  end;

  UpdateCsvStatus;
end;

procedure RemoveCsvButtonClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CsvListBox.ItemIndex;
  if Idx >= 0 then
  begin
    CsvFullPaths.Delete(Idx);
    UpdateCsvStatus;
  end;
end;

procedure InitializeWizard;
var
  AddBtn, RemoveBtn: TButton;
  InstructLabel: TLabel;
begin
  // An existing, initialized Postgres data dir means the store's catalog is
  // already seeded — treat this run as an upgrade and skip CSV re-import.
  IsUpgradeInstall := FileExists('C:\posdata\PG_VERSION');

  KioskNoPage := CreateInputQueryPage(
    wpSelectTasks,
    'Kiosk Configuration',
    'Identify this terminal',
    'Enter a unique kiosk number (1â€"999) for this machine. ' +
    'It appears in all sales order numbers generated here, e.g. SO-001-2026-0001.'
  );
  KioskNoPage.Add('Kiosk Number:', False);
  KioskNoPage.Values[0] := '1';

  // ── CSV Import page ───────────────────────────────────────────────────
  CsvFullPaths := TStringList.Create;

  CsvImportPage := CreateCustomPage(
    KioskNoPage.ID,
    'Product Catalog Import',
    'Import your store''s product catalog from CSV files'
  );

  // Layout note: positions are computed from each control's actual height
  // (Top + Height + margin) rather than hard-coded offsets, so the multi-line
  // instruction label never overlaps the list box across DPI/font differences.
  InstructLabel := TLabel.Create(CsvImportPage);
  InstructLabel.Parent := CsvImportPage.Surface;
  InstructLabel.Left := 0;
  InstructLabel.Top := 0;
  InstructLabel.Width := CsvImportPage.SurfaceWidth;
  InstructLabel.WordWrap := True;
  InstructLabel.AutoSize := True;
  InstructLabel.Caption :=
    'Add one or more CSV files. The installer detects their schema automatically.' + #13#10 +
    'Supported schemas: Products / Categories / Variants, and Modifier Groups / Options.' + #13#10 +
    'The Products schema takes an optional last column, Product Image URL.' + #13#10 +
    'A template CSV is installed to C:\POSKiosk\data\products-template.csv for reference.';

  CsvListBox := TListBox.Create(CsvImportPage);
  CsvListBox.Parent := CsvImportPage.Surface;
  CsvListBox.Left := 0;
  CsvListBox.Top := InstructLabel.Top + InstructLabel.Height + ScaleY(12);
  CsvListBox.Width := CsvImportPage.SurfaceWidth;
  CsvListBox.Height := ScaleY(120);

  AddBtn := TButton.Create(CsvImportPage);
  AddBtn.Parent := CsvImportPage.Surface;
  AddBtn.Left := 0;
  AddBtn.Top := CsvListBox.Top + CsvListBox.Height + ScaleY(8);
  AddBtn.Width := ScaleX(100);
  AddBtn.Caption := 'Add CSV...';
  AddBtn.OnClick := @AddCsvButtonClick;

  RemoveBtn := TButton.Create(CsvImportPage);
  RemoveBtn.Parent := CsvImportPage.Surface;
  RemoveBtn.Left := AddBtn.Left + AddBtn.Width + ScaleX(10);
  RemoveBtn.Top := AddBtn.Top;
  RemoveBtn.Width := ScaleX(100);
  RemoveBtn.Caption := 'Remove';
  RemoveBtn.OnClick := @RemoveCsvButtonClick;

  CsvStatusLabel := TLabel.Create(CsvImportPage);
  CsvStatusLabel.Parent := CsvImportPage.Surface;
  CsvStatusLabel.Left := 0;
  CsvStatusLabel.Top := AddBtn.Top + AddBtn.Height + ScaleY(12);
  CsvStatusLabel.Width := CsvImportPage.SurfaceWidth;
  CsvStatusLabel.WordWrap := True;
  CsvStatusLabel.AutoSize := True;
  CsvStatusLabel.Caption := 'No CSV files added. At least one recognized CSV is required.';
end;

// Skip the product-catalog import page on upgrades — the catalog already exists
// in the database and the CSV seeder is authoritative (would soft-delete anything
// not in the file). Fresh installs still see the page and must supply a CSV.
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = CsvImportPage.ID) and IsUpgradeInstall;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  KioskNo: String;
  Val, I: Integer;
  UnknownFiles, ErrorFiles: String;
  HasKnown, HasErrors: Boolean;
  FilePath, Schema: String;
  MsgResult: Integer;
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

  // ── CSV Import page validation ────────────────────────────────────────
  if CurPageID = CsvImportPage.ID then begin
    HasKnown := False;
    HasErrors := False;
    UnknownFiles := '';
    ErrorFiles := '';

    for I := 0 to CsvFullPaths.Count - 1 do
    begin
      FilePath := CsvFullPaths[I];
      Schema := DetectCsvSchema(FilePath);

      if Schema = 'unknown' then
        UnknownFiles := UnknownFiles + '  - ' + ExtractFileName(FilePath) + #13#10
      else begin
        HasKnown := True;
        if CountCsvDataRows(FilePath) = 0 then begin
          HasErrors := True;
          ErrorFiles := ErrorFiles + '  - ' + ExtractFileName(FilePath) + ' (no data rows)' + #13#10;
        end;
      end;
    end;

    if CsvFullPaths.Count = 0 then begin
      MsgBox('Please add at least one CSV file before continuing.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    if HasErrors then begin
      MsgBox(
        'The following CSV files have errors and must be fixed or removed:' + #13#10 + #13#10 +
        ErrorFiles,
        mbError, MB_OK
      );
      Result := False;
      Exit;
    end;

    if not HasKnown then begin
      MsgBox(
        'None of the added CSV files match a recognized schema.' + #13#10 +
        'At least one recognized CSV file is required to continue.',
        mbError, MB_OK
      );
      Result := False;
      Exit;
    end;

    if UnknownFiles <> '' then begin
      MsgResult := MsgBox(
        'The following files do not match a known schema and will be skipped:' + #13#10 + #13#10 +
        UnknownFiles + #13#10 +
        'Do you want to continue without these files?',
        mbConfirmation, MB_YESNO
      );
      if MsgResult = IDNO then begin
        Result := False;
        Exit;
      end;
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
  SettingsPath, CsvDestDir, SrcPath, DestPath: String;
  I: Integer;
begin
  if CurStep = ssInstall then begin
    // Copy all selected CSV files to {app}\data\csv\ before the [Run] steps
    CsvDestDir := ExpandConstant('{app}\data\csv');
    if not DirExists(CsvDestDir) then
      ForceDirectories(CsvDestDir);
    for I := 0 to CsvFullPaths.Count - 1 do
    begin
      SrcPath := CsvFullPaths[I];
      DestPath := CsvDestDir + '\' + ExtractFileName(SrcPath);
      FileCopy(SrcPath, DestPath, False);
    end;
  end;

  if CurStep = ssPostInstall then begin
    SettingsPath := ExpandConstant('{app}\settings.txt');
    SaveStringToFile(SettingsPath, 'kiosk.no=' + Trim(KioskNoPage.Values[0]), False);

    // Check that CSV seeding completed — the script writes a marker on success.
    // [Run] steps ignore exit codes so this is the only way to surface failures.
    // Skipped on upgrades, where the seed step intentionally never runs.
    if (not IsUpgradeInstall) and (not FileExists(ExpandConstant('{app}\logs\seed-csv-success.marker'))) then begin
      MsgBox(
        'Product catalog import did not complete successfully.' + #13#10 + #13#10 +
        'Check the log for details:' + #13#10 +
        ExpandConstant('{app}\logs\seed-csv-install.log') + #13#10 + #13#10 +
        'You can re-run seeding after install by placing updated CSV files in:' + #13#10 +
        ExpandConstant('{app}\data\csv\') + #13#10 +
        'then running recover-services.bat as administrator.',
        mbError, MB_OK
      );
    end;

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





















































