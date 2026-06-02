; ----------------------------------------
; POSApp Installer (WMI Check Version)
; Flutter UI + NestJS backend + NSSM service
; ----------------------------------------

[Setup]
AppId=inc.cody.posapp
AppName=POS App
AppVersion=0.0.1
DefaultDirName={autopf}\POSApp
DefaultGroupName=POSApp
PrivilegesRequired=admin
OutputBaseFilename=POSAppInstaller
Compression=lzma2
SolidCompression=yes
; We handle the check in [Code], but this helps Windows Restart Manager
CloseApplications=yes
UninstallDisplayIcon={app}\pos_app.exe

[Dirs]
Name: "{app}\logs"
Name: "{app}\backend"
Name: "{app}\tools"
Name: "{app}\dependencies"
Name: "{app}\symmetric-server"
Name: "{app}\symmetric-server\engines"

[Files]
; --- Flutter UI ---
Source: "..\build\windows\x64\runner\Release\pos_app.exe"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\file_selector_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\flutter_secure_storage_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\screen_retriever_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\share_plus_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: recursesubdirs createallsubdirs

; --- Backend & Tools ---
Source: "..\backend\POSBackend.exe"; DestDir: "{app}\backend"; Flags: ignoreversion restartreplace
Source: "tools\nssm.exe"; DestDir: "{app}\tools"; Flags: ignoreversion

; --- Dependency Installers ---
Source: "dependencies\jdk-25_windows-x64_bin.exe"; DestDir: "{app}\dependencies"; Flags: ignoreversion
Source: "dependencies\postgresql-18.1-2-windows-x64.exe"; DestDir: "{app}\dependencies"; Flags: ignoreversion

; --- Symmetric Server ---
Source: "dependencies\symmetric-server-3.16.9\*"; DestDir: "{app}\symmetric-server"; Flags: ignoreversion recursesubdirs createallsubdirs

; --- Assets ---
Source: "dependencies\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\POS App"; Filename: "{app}\pos_app.exe"
Name: "{userdesktop}\POS App"; Filename: "{app}\pos_app.exe"

[Run]
; --- INSTALL DEPENDENCIES (Java, PostgreSQL) ---
; Install Java JDK 25
Filename: "{app}\dependencies\jdk-25_windows-x64_bin.exe"; Parameters: /s; Flags: waituntilterminated; StatusMsg: "Installing Java JDK 25..."; Check: ShouldInstallJava

; Install PostgreSQL 18
Filename: "{app}\dependencies\postgresql-18.1-2-windows-x64.exe"; Parameters: "--mode unattended --superpassword postgres --servicename postgresql-x64-18 --servicepassword postgres --serverport 5432"; Flags: runhidden waituntilterminated; StatusMsg: "Installing PostgreSQL 18..."; Check: ShouldInstallPostgres

; Wait for PostgreSQL service to start (only if we just installed it)
Filename: "powershell"; Parameters: "-Command ""{code:GetStartPostgresServiceCommand}"""; Flags: runhidden waituntilterminated; StatusMsg: "Starting PostgreSQL service..."; Check: ShouldInstallPostgres

; Wait for PostgreSQL to be fully ready before creating database
Filename: "cmd.exe"; Parameters: "/c timeout /t 5 /nobreak >nul"; Flags: runhidden; StatusMsg: "Waiting for PostgreSQL to be ready..."

; Database creation is handled in CurStepChanged event (ssPostInstall step)
; This avoids using cmd.exe or PowerShell - uses Pascal Exec directly
; See TestPostgresConnection() and CreatePostgresDatabase() functions in [Code] section

; --- CLEANUP BEFORE INSTALL (Upgrades) ---
; Stop and remove existing POSBackend service if it exists (using sc.exe as per Stack Overflow: https://stackoverflow.com/questions/16517974/inno-setup-installing-windows-services-using-sc-create)
Filename: "{sys}\sc.exe"; Parameters: "stop POSBackend"; Flags: runhidden; StatusMsg: "Stopping existing services..."
Filename: "{sys}\sc.exe"; Parameters: "delete POSBackend"; Flags: runhidden
; Stop and remove existing SymmetricDS service if it exists
Filename: "{sys}\sc.exe"; Parameters: "stop SymmetricDS"; Flags: runhidden; StatusMsg: "Stopping existing services..."
Filename: "{sys}\sc.exe"; Parameters: "delete SymmetricDS"; Flags: runhidden

; --- SERVICE INSTALLATION ---
; Install POSBackend service using NSSM (since POSBackend.exe is a regular executable, not a Windows service)
Filename: "{app}\tools\nssm.exe"; Parameters: "install POSBackend ""{app}\backend\POSBackend.exe"""; Flags: runhidden; StatusMsg: "Installing Backend Service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set POSBackend AppDirectory ""{app}\backend"""; Flags: runhidden
Filename: "{app}\tools\nssm.exe"; Parameters: "set POSBackend AppStdout ""{app}\logs\backend_stdout.log"""; Flags: runhidden
Filename: "{app}\tools\nssm.exe"; Parameters: "set POSBackend AppStderr ""{app}\logs\backend_stderr.log"""; Flags: runhidden
Filename: "{app}\tools\nssm.exe"; Parameters: "set POSBackend Start SERVICE_AUTO_START"; Flags: runhidden
; Start the service using sc.exe (more reliable than NSSM start)
Filename: "{sys}\sc.exe"; Parameters: "start POSBackend"; Flags: runhidden; StatusMsg: "Starting Backend Service..."

; Install SymmetricDS service using native sym_service.bat script
Filename: "{app}\symmetric-server\bin\sym_service.bat"; Parameters: "install"; Flags: runhidden waituntilterminated; StatusMsg: "Installing SymmetricDS Service..."
; Start the SymmetricDS service
Filename: "{sys}\sc.exe"; Parameters: "start SymmetricDS"; Flags: runhidden; StatusMsg: "Starting SymmetricDS Service..."

; --- FIREWALL ---
; Add firewall rule (will not error if it already exists)
;Filename: "powershell"; Parameters: "-Command ""{code:GetAddFirewallRuleCommand}"""; Flags: runhidden; StatusMsg: "Configuring firewall..."

; --- LAUNCH APP ---
Filename: "{app}\pos_app.exe"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; --- SERVICE REMOVAL ---
; Using sc.exe as per Stack Overflow: https://stackoverflow.com/questions/16517974/inno-setup-installing-windows-services-using-sc-create
; We use 'waituntilterminated' to ensure the service is fully dead before we delete files
Filename: "{sys}\sc.exe"; Parameters: "stop POSBackend"; Flags: runhidden waituntilterminated; StatusMsg: "Stopping Backend Service..."
Filename: "{sys}\sc.exe"; Parameters: "delete POSBackend"; Flags: runhidden
; Stop and remove SymmetricDS service using native sym_service.bat script
Filename: "{sys}\sc.exe"; Parameters: "stop SymmetricDS"; Flags: runhidden waituntilterminated; StatusMsg: "Stopping SymmetricDS Service..."
Filename: "{app}\symmetric-server\bin\sym_service.bat"; Parameters: "uninstall"; Flags: runhidden waituntilterminated; StatusMsg: "Removing SymmetricDS Service..."

; --- FIREWALL REMOVAL ---
; Remove firewall rule (will not error if it doesn't exist)
Filename: "powershell"; Parameters: "-Command ""$ruleName = ''POSBackend''; netsh advfirewall firewall delete rule name=$ruleName 2>&1 | Out-Null"""; Flags: runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Global variables for SymmetricDS configuration
var
  SymmetricDSPage: TWizardPage;
  SourceIPPage: TInputQueryWizardPage;
  NodeNumberEdit: TEdit;
  NodeNumber: Integer;
  IsSourceNode: Boolean;
  SourceIP: String;
  ExternalID: String;
  DeviceIP: String;
  PostgresPort: String;
  DatabaseName: String;

// This function runs BEFORE file copying begins
// It stops the POSBackend service and closes pos_app.exe to prevent file lock errors
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  AppPath: String;
  NssmPath: String;
  ServiceExists: Boolean;
begin
  Result := True;

  try
    // First, try to stop POSBackend service using Windows service commands
    // This works regardless of where the app is installed
    ServiceExists := False;
    if Exec('sc.exe', 'query POSBackend', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode = 0 then
      begin
        ServiceExists := True;
        // Service exists, stop it
        Exec('sc.exe', 'stop POSBackend', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        // Wait for service to stop
        Sleep(3000);
      end;
    end;

    // Stop SymmetricDS service if it exists
    if Exec('sc.exe', 'query SymmetricDS', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode = 0 then
      begin
        Exec('sc.exe', 'stop SymmetricDS', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        Sleep(3000);
      end;
    end;

    // Also try using NSSM if available (for more graceful shutdown)
    AppPath := ExpandConstant('{autopf}\POSApp');
    NssmPath := AppPath + '\tools\nssm.exe';
    if FileExists(NssmPath) then
    begin
      Exec(NssmPath, 'stop POSBackend', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Exec(NssmPath, 'stop SymmetricDS', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Sleep(2000);
    end;

    // Close pos_app.exe if running using taskkill (most reliable)
    Exec('taskkill.exe', '/F /IM pos_app.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // Also try PowerShell as additional method
    Exec('powershell.exe', '-Command "Get-Process -Name pos_app -ErrorAction SilentlyContinue | Stop-Process -Force"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    // Wait for processes to fully terminate
    Sleep(2000);

  except
    // If anything fails, continue with installation
    // The restartreplace flag will handle locked files by scheduling a restart if needed
  end;
end;

// Check if Java is already installed
function IsJavaInstalled(): Boolean;
var
  ResultCode: Integer;
begin
  Result := False;
  // Try to run java -version
  if Exec('cmd.exe', '/c java -version >nul 2>&1', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Result := (ResultCode = 0);
  end;
end;

// Check if PostgreSQL is already installed
// Only returns True if psql.exe actually exists (most reliable check)
function IsPostgresInstalled(): Boolean;
var
  PgPath: String;
  i: Integer;
begin
  Result := False;

  // MANDATORY: Only check Program Files (C:\Program Files\PostgreSQL)
  // Do not check Program Files (x86) - we require 64-bit installation
  // Check common PostgreSQL installation paths (18, 17, 16, 15, 14, 13, 12, 11, 10)
  // Check for both psql.exe and createdb.exe to ensure it's a complete installation
  for i := 18 downto 10 do
  begin
    PgPath := ExpandConstant('C:\Program Files\PostgreSQL\' + IntToStr(i) + '\bin');
    if FileExists(PgPath + '\psql.exe') and FileExists(PgPath + '\createdb.exe') then
    begin
      Result := True;
      Break;
    end;
  end;

  // Removed service checks - they can be unreliable (service might exist but PostgreSQL not fully installed)
end;

// Check if Java should be installed
function ShouldInstallJava(): Boolean;
begin
  Result := not IsJavaInstalled();
end;

// Check if PostgreSQL should be installed
function ShouldInstallPostgres(): Boolean;
begin
  Result := not IsPostgresInstalled();
end;

// Get PowerShell command to start PostgreSQL service
function GetStartPostgresServiceCommand(Param: String): String;
begin
  Result := 'Start-Sleep -Seconds 5; ' +
            '$svc = Get-Service -Name ''postgresql*'' -ErrorAction SilentlyContinue | Select-Object -First 1; ' +
            'if ($svc -and $svc.Status -ne ''Running'') { ' +
            'Start-Service $svc.Name; ' +
            '$timeout = 30; ' +
            '$elapsed = 0; ' +
            'while ($svc.Status -ne ''Running'' -and $elapsed -lt $timeout) { ' +
            'Start-Sleep -Seconds 2; ' +
            '$svc.Refresh(); ' +
            '$elapsed += 2 ' +
            '} ' +
            '}';
end;


// Get PowerShell command to add firewall rule (idempotent)
function GetAddFirewallRuleCommand(Param: String): String;
begin
  Result := '$ruleName = "POSBackend"; ' +
            '$existingRule = netsh advfirewall firewall show rule name=$ruleName 2>&1; ' +
            'if ($existingRule -notmatch "No rules match") { ' +
            '  netsh advfirewall firewall delete rule name=$ruleName 2>&1 | Out-Null; ' +
            '} ' +
            'netsh advfirewall firewall add rule name=$ruleName dir=in action=allow protocol=TCP localport=3000 2>&1 | Out-Null;';
end;


// Find PostgreSQL bin directory
// MANDATORY: Only checks Program Files (C:\Program Files\PostgreSQL)
// Does not check Program Files (x86) - we require 64-bit installation
function GetPostgresBinPath(Param: String): String;
var
  PgPath: String;
  i: Integer;
begin
  Result := '';

  // MANDATORY: Only check Program Files (64-bit installation required)
  // Check common PostgreSQL installation paths (18, 17, 16, 15, 14, 13, 12, 11, 10)
  for i := 18 downto 10 do
  begin
    PgPath := ExpandConstant('{pf}\PostgreSQL\' + IntToStr(i) + '\bin');
    if FileExists(PgPath + '\createdb.exe') then
    begin
      Result := PgPath;
      Break;
    end;
  end;

  // If not found, Result will be empty string
  // This will cause the fallback in GetCreateDatabaseCommand to use the default path
end;

// Check if database should be created
// Always try to create database if PostgreSQL is installed
function ShouldCreateDatabase(): Boolean;
begin
  // Try to create database if PostgreSQL is installed
  Result := IsPostgresInstalled();
end;

// Create .pgpass file with password 'postgres' for PostgreSQL authentication
procedure CreatePgPassFile();
var
  PgPassPath: String;
begin
  // .pgpass file location: %APPDATA%\postgresql\pgpass.conf
  PgPassPath := ExpandConstant('{userappdata}\postgresql');
  if not DirExists(PgPassPath) then
    CreateDir(PgPassPath);

  // Create .pgpass file with password 'postgres'
  // Format: hostname:port:database:username:password
  SaveStringToFile(PgPassPath + '\pgpass.conf', 'localhost:5432:*:postgres:postgres' + #13#10, False);
end;

// Test PostgreSQL connection using Pascal Exec (no cmd.exe or PowerShell)
procedure TestPostgresConnection();
var
  ResultCode: Integer;
  PsqlPath: String;
  LogFile: String;
  ErrorFile: String;
  ErrorOutput: AnsiString;
begin
  PsqlPath := GetPostgresBinPath('');
  if PsqlPath = '' then
    PsqlPath := ExpandConstant('C:\Program Files\PostgreSQL\18\bin');

  LogFile := ExpandConstant('{app}\logs\postgres_connection_test.log');

  // Check if psql.exe exists
  if not FileExists(PsqlPath + '\psql.exe') then
  begin
    SaveStringToFile(LogFile, 'psql.exe not found at: ' + PsqlPath + #13#10, False);
    RaiseException('PostgreSQL client tools not found.' + #13#10 + #13#10 +
                  'Expected location: ' + PsqlPath + '\psql.exe' + #13#10 +
                  'Please ensure PostgreSQL 18 is installed correctly. Installation will be cancelled.');
  end;

  // Create .pgpass file for authentication
  CreatePgPassFile();

  // Test connection using psql directly (without output redirection to avoid issues)
  // Use -q flag for quiet mode and -t flag for tuples only (no headers)
  if not Exec(PsqlPath + '\psql.exe', '-U postgres -h localhost -p 5432 -q -t -c "SELECT 1;" postgres', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    // Failed to execute - abort installation
    SaveStringToFile(LogFile, 'Failed to execute PostgreSQL connection test command.' + #13#10, False);
    RaiseException('Failed to execute PostgreSQL connection test.' + #13#10 +
                  'PostgreSQL may not be installed correctly or the psql.exe tool is missing.');
  end;

  // If connection test failed, try to get error details
  if ResultCode <> 0 then
  begin
    // Try again with error capture to get the actual error message
    ErrorFile := ExpandConstant('{tmp}\postgres_test_error.txt');
    if Exec('cmd.exe', '/c "' + PsqlPath + '\psql.exe" -U postgres -h localhost -p 5432 -c "SELECT 1;" postgres 2> "' + ErrorFile + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if FileExists(ErrorFile) then
      begin
        if LoadStringFromFile(ErrorFile, ErrorOutput) then
        begin
          ErrorOutput := Trim(ErrorOutput);
          SaveStringToFile(LogFile, 'PostgreSQL connection test failed. Error: ' + ErrorOutput + #13#10, False);
          DeleteFile(ErrorFile);
          if ErrorOutput <> '' then
          begin
            RaiseException('PostgreSQL connection failed.' + #13#10 + #13#10 +
                          'Error details: ' + ErrorOutput + #13#10 + #13#10 +
                          'Please ensure:' + #13#10 +
                          '- PostgreSQL service is running' + #13#10 +
                          '- Password is set to "postgres"' + #13#10 +
                          '- Port 5432 is accessible' + #13#10 +
                          'Installation will be cancelled.');
          end;
        end;
        DeleteFile(ErrorFile);
      end;
    end;

    // Fallback error message
    SaveStringToFile(LogFile, 'PostgreSQL connection test failed with exit code: ' + IntToStr(ResultCode) + #13#10, False);
  end
  else
  begin
    SaveStringToFile(LogFile, 'PostgreSQL connection test successful.' + #13#10, False);
  end;
end;

// Check if database already exists
function DatabaseExists(): Boolean;
var
  ResultCode: Integer;
  PsqlPath: String;
  TempFile: String;
  Output: AnsiString;
begin
  Result := False;

  try
    PsqlPath := GetPostgresBinPath('');
    if PsqlPath = '' then
      PsqlPath := ExpandConstant('C:\Program Files\PostgreSQL\18\bin');

    // Check if psql.exe exists
    if not FileExists(PsqlPath + '\psql.exe') then
      Exit; // psql not found, assume database doesn't exist

    TempFile := ExpandConstant('{tmp}\check_db_pos.txt');

    // Check if database exists using psql with output redirection
    // Use -A -t flags for simpler output, and redirect to temp file
    if Exec('cmd.exe', '/c "' + PsqlPath + '\psql.exe" -U postgres -h localhost -p 5432 -A -t -c "SELECT 1 FROM pg_database WHERE datname = ''pos_db''" postgres > "' + TempFile + '" 2>&1', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      // Only check file if command succeeded (ResultCode = 0)
      if (ResultCode = 0) and FileExists(TempFile) then
      begin
        if LoadStringFromFile(TempFile, Output) then
        begin
          // If output contains "1", database exists
          Output := Trim(Output);
          if (Output = '1') or (Pos('1', Output) > 0) then
            Result := True;
        end;
      end;

      // Clean up temp file
      if FileExists(TempFile) then
        DeleteFile(TempFile);
    end;
  except
    // If anything fails, assume database doesn't exist (fail-safe)
    Result := False;
  end;
end;

// Create PostgreSQL database using Pascal Exec (no cmd.exe or PowerShell)
procedure CreatePostgresDatabase();
var
  ResultCode: Integer;
  CreatedbPath: String;
  LogFile: String;
  ErrorFile: String;
  ErrorOutput: AnsiString;
  ErrorOutputLower: String;
begin
  CreatedbPath := GetPostgresBinPath('');
  if CreatedbPath = '' then
    CreatedbPath := ExpandConstant('C:\Program Files\PostgreSQL\18\bin');

  LogFile := ExpandConstant('{app}\logs\database_creation.log');

  // .pgpass file is already created by TestPostgresConnection()
  // PostgreSQL tools will automatically read it for authentication

  // Check if database already exists - if so, skip creation and continue
  if DatabaseExists() then
  begin
    SaveStringToFile(LogFile, 'Database pos_db already exists. Skipping creation and continuing installation.' + #13#10, False);
    Exit; // Database exists, nothing to do - continue installation
  end;

  // Check if createdb.exe exists
  if not FileExists(CreatedbPath + '\createdb.exe') then
  begin
    SaveStringToFile(LogFile, 'createdb.exe not found at: ' + CreatedbPath + #13#10, False);
    RaiseException('PostgreSQL database creation tool not found.' + #13#10 + #13#10 +
                  'Expected location: ' + CreatedbPath + '\createdb.exe' + #13#10 +
                  'Please ensure PostgreSQL 18 is installed correctly. Installation will be cancelled.');
  end;

  // Create database using createdb.exe directly (without output redirection first)
  if not Exec(CreatedbPath + '\createdb.exe', '-U postgres -h localhost -p 5432 -E UTF8 -O postgres pos_db', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    // Failed to execute - abort installation
    SaveStringToFile(LogFile, 'Failed to execute database creation command.' + #13#10, False);
    RaiseException('Failed to execute database creation command.' + #13#10 +
                  'PostgreSQL may not be installed correctly or the createdb.exe tool is missing.');
  end;

  // Check result
  if ResultCode <> 0 then
  begin
    // Creation failed - check if database exists now (might have been created between check and creation attempt)
    if DatabaseExists() then
    begin
      // Database exists now, so the failure was likely because it already existed
      SaveStringToFile(LogFile, 'Database creation returned error, but database pos_db exists. Continuing installation.' + #13#10, False);
      Exit; // Database exists, treat as success and continue
    end
    else
    begin
      // Creation failed - check if database exists or if error is "already exists"
      // Try to get error details by running again with error capture
      ErrorFile := ExpandConstant('{tmp}\createdb_error.txt');
      if Exec('cmd.exe', '/c "' + CreatedbPath + '\createdb.exe" -U postgres -h localhost -p 5432 -E UTF8 -O postgres pos_db 2> "' + ErrorFile + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      begin
        if FileExists(ErrorFile) then
        begin
          if LoadStringFromFile(ErrorFile, ErrorOutput) then
          begin
            ErrorOutput := Trim(ErrorOutput);
            // Log the original error for debugging
            SaveStringToFile(LogFile, 'Database creation error output: ' + ErrorOutput + #13#10, False);

            // Convert to lowercase for case-insensitive matching (keep original for display)
            ErrorOutputLower := LowerCase(ErrorOutput);
            // Check if error indicates database already exists
            // PostgreSQL error format: "ERROR:  database "pos_db" already exists"
            // Check for various patterns that indicate database already exists
            if (Pos('already exists', ErrorOutputLower) > 0) or
               (Pos('duplicate', ErrorOutputLower) > 0) or
               (Pos('already present', ErrorOutputLower) > 0) or
               ((Pos('database', ErrorOutputLower) > 0) and (Pos('exists', ErrorOutputLower) > 0)) then
            begin
              // Database already exists - this is fine, continue installation
              SaveStringToFile(LogFile, 'Database creation returned error (already exists): ' + ErrorOutput + '. Continuing installation.' + #13#10, False);
              DeleteFile(ErrorFile);
              Exit; // Database exists, treat as success and continue
            end;

            // It's a real error - log and raise exception (use original ErrorOutput for display)
            SaveStringToFile(LogFile, 'Database creation failed. Error: ' + ErrorOutput + #13#10, False);
            DeleteFile(ErrorFile);
            if ErrorOutput <> '' then
            begin
              RaiseException('Failed to create database "pos_db".' + #13#10 + #13#10 +
                            'Error details: ' + ErrorOutput + #13#10 + #13#10 +
                            'Please ensure PostgreSQL is running and accessible. Installation will be cancelled.');
            end;
          end;
          DeleteFile(ErrorFile);
        end;
      end;
    end;
  end
  else
  begin
    // Success - database created
    SaveStringToFile(LogFile, 'Database pos_db created successfully.' + #13#10, False);
  end;
end;

// Run database migrations using POSBackend.exe
procedure RunDatabaseMigrations();
var
  ResultCode: Integer;
  BackendPath: String;
  LogFile: String;
  ErrorFile: String;
  ErrorOutput: AnsiString;
begin
  BackendPath := ExpandConstant('{app}\backend\POSBackend.exe');
  LogFile := ExpandConstant('{app}\logs\migration.log');

  // Check if POSBackend.exe exists
  if not FileExists(BackendPath) then
  begin
    SaveStringToFile(LogFile, 'POSBackend.exe not found at: ' + BackendPath + '. Skipping migrations.' + #13#10, False);
    RaiseException('POSBackend.exe not found at: ' + BackendPath + #13#10 +
                   'The backend executable is required for database setup. Installation will be cancelled.');
  end;

  SaveStringToFile(LogFile, 'Starting database migrations...' + #13#10, False);
  SaveStringToFile(LogFile, 'Command: ' + BackendPath + ' --migrate' + #13#10, False);

  // Run migration command with error capture
  ErrorFile := ExpandConstant('{tmp}\migration_error.txt');
  if not Exec('cmd.exe', '/c "' + BackendPath + '" --migrate > "' + ErrorFile + '" 2>&1', ExpandConstant('{app}\backend'), SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    SaveStringToFile(LogFile, 'Failed to execute migration command.' + #13#10, False);
    RaiseException('Failed to execute database migration command.' + #13#10 +
                   'POSBackend.exe may not be installed correctly or may be missing dependencies.');
  end;

  // Check migration result
  if ResultCode <> 0 then
  begin
    // Try to read the actual error message
    if FileExists(ErrorFile) then
    begin
      if LoadStringFromFile(ErrorFile, ErrorOutput) then
      begin
        ErrorOutput := Trim(ErrorOutput);
        SaveStringToFile(LogFile, 'Migration failed. Error output: ' + ErrorOutput + #13#10, False);
        DeleteFile(ErrorFile);
        if ErrorOutput <> '' then
        begin
          RaiseException('Database migration failed.' + #13#10 + #13#10 +
                        'Error details: ' + ErrorOutput + #13#10 + #13#10 +
                        'Please check the migration log for more information. Installation will be cancelled.');
        end;
      end;
      DeleteFile(ErrorFile);
    end;

    SaveStringToFile(LogFile, 'Migration failed with exit code: ' + IntToStr(ResultCode) + #13#10, False);
  end
  else
  begin
    SaveStringToFile(LogFile, 'Database migrations completed successfully.' + #13#10, False);
    if FileExists(ErrorFile) then
      DeleteFile(ErrorFile);
  end;

  // Now run seed command separately
  SaveStringToFile(LogFile, 'Starting database seeding...' + #13#10, False);
  SaveStringToFile(LogFile, 'Command: ' + BackendPath + ' --seed' + #13#10, False);

  // Run seed command directly first (without output redirection to avoid issues)
  if not Exec(BackendPath, '--seed', ExpandConstant('{app}\backend'), SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    SaveStringToFile(LogFile, 'Failed to execute seed command.' + #13#10, False);
    RaiseException('Failed to execute database seeding command.' + #13#10 +
                   'POSBackend.exe may not be installed correctly or may be missing dependencies.');
  end;

  // Check seed result
  if ResultCode <> 0 then
  begin
    // Seed failed - try to get error details by running again with error capture
    ErrorFile := ExpandConstant('{tmp}\seed_error.txt');
    if Exec('cmd.exe', '/c "' + BackendPath + '" --seed 2> "' + ErrorFile + '"', ExpandConstant('{app}\backend'), SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      // Try to read the actual error message
      if FileExists(ErrorFile) then
      begin
        if LoadStringFromFile(ErrorFile, ErrorOutput) then
        begin
          ErrorOutput := Trim(ErrorOutput);
          SaveStringToFile(LogFile, 'Seeding failed. Error output: ' + ErrorOutput + #13#10, False);
          DeleteFile(ErrorFile);
          if ErrorOutput <> '' then
          begin
            RaiseException('Database seeding failed.' + #13#10 + #13#10 +
                          'Error details: ' + ErrorOutput + #13#10 + #13#10 +
                          'Please check the migration log for more information. Installation will be cancelled.');
          end;
        end;
        DeleteFile(ErrorFile);
      end;
    end;

    SaveStringToFile(LogFile, 'Seeding failed with exit code: ' + IntToStr(ResultCode) + #13#10, False);
  end
  else
  begin
    SaveStringToFile(LogFile, 'Database seeding completed successfully.' + #13#10, False);
  end;
end;

// Get local IP address automatically
function GetLocalIP(): String;
var
  ResultCode: Integer;
  TempFile: String;
  Output: AnsiString;
  i: Integer;
begin
  Result := '';
  TempFile := ExpandConstant('{tmp}\ipconfig_output.txt');

  // Use ipconfig to get IP address and save to temp file
  if Exec('cmd.exe', '/c ipconfig | findstr /i "IPv4" > "' + TempFile + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if FileExists(TempFile) then
    begin
      if LoadStringFromFile(TempFile, Output) then
      begin
        // Parse output to get first IP address (usually the active one)
        // Extract IP from output like "   IPv4 Address. . . . . . . . . . . : 192.168.1.100"
        i := Pos(':', Output);
        if i > 0 then
        begin
          Result := Trim(Copy(Output, i + 1, Length(Output)));
          // Remove any trailing characters after IP
          i := Pos(#13#10, Result);
          if i > 0 then
            Result := Copy(Result, 1, i - 1);
          i := Pos(#10, Result);
          if i > 0 then
            Result := Copy(Result, 1, i - 1);
          i := Pos(' ', Result);
          if i > 0 then
            Result := Copy(Result, 1, i - 1);
        end;
      end;
      DeleteFile(TempFile);
    end;
  end;

  // Fallback: try PowerShell if ipconfig didn't work
  if Result = '' then
  begin
    TempFile := ExpandConstant('{tmp}\powershell_ip.txt');
    if Exec('powershell.exe', '-Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike ''*Loopback*''})[0].IPAddress | Out-File -FilePath ''' + TempFile + '''"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if FileExists(TempFile) then
      begin
        if LoadStringFromFile(TempFile, Output) then
        begin
          Result := Trim(Output);
        end;
        DeleteFile(TempFile);
      end;
    end;
  end;
end;

// Generate unique external ID for child nodes
function GenerateExternalID(): String;
var
  ComputerName: String;
  RandomSuffix: String;
  ResultCode: Integer;
  TempFile: String;
  Output: AnsiString;
  i: Integer;
begin
  // Get computer name using environment variable
  ComputerName := GetEnv('COMPUTERNAME');
  if ComputerName = '' then
  begin
    // Fallback: try hostname command
    TempFile := ExpandConstant('{tmp}\hostname.txt');
    if Exec('cmd.exe', '/c hostname > "' + TempFile + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if FileExists(TempFile) then
      begin
        if LoadStringFromFile(TempFile, Output) then
        begin
          ComputerName := Trim(Output);
        end;
        DeleteFile(TempFile);
      end;
    end;
  end;

  if ComputerName = '' then
    ComputerName := 'KIOSK';

  // Generate unique suffix (2 digits) using a simple hash of computer name
  // This creates a pseudo-random 2-digit number (00-99) based on computer name
  i := 0;
  if Length(ComputerName) > 0 then
  begin
    // Sum ASCII values of first few characters
    i := Ord(ComputerName[1]);
    if Length(ComputerName) > 1 then
      i := i + Ord(ComputerName[Length(ComputerName)]);
    i := (i * 17 + Length(ComputerName) * 23) mod 100;
  end;
  RandomSuffix := Format('%.2d', [i]);

  // Format: KIOSK + last 3 chars of computer name + random suffix
  if Length(ComputerName) > 3 then
    Result := 'KIOSK' + Copy(ComputerName, Length(ComputerName) - 2, 3) + RandomSuffix
  else
    Result := 'KIOSK' + ComputerName + RandomSuffix;
end;

// Initialize wizard pages for SymmetricDS configuration
procedure InitializeWizard();
var
  NodeTypeLabel: TLabel;
begin
  // Create custom page with dropdown for node type selection
  SymmetricDSPage := CreateCustomPage(wpSelectTasks,
    'SymmetricDS Configuration', 'Select node type');

  // Create label for number input
  NodeTypeLabel := TLabel.Create(SymmetricDSPage);
  NodeTypeLabel.Caption := 'Enter Kiosk Number:';
  NodeTypeLabel.Parent := SymmetricDSPage.Surface;
  NodeTypeLabel.Left := 0;
  NodeTypeLabel.Top := 0;
  NodeTypeLabel.Width := 400;

  // Create number input (edit box) for node number
  NodeNumberEdit := TEdit.Create(SymmetricDSPage);
  NodeNumberEdit.Parent := SymmetricDSPage.Surface;
  NodeNumberEdit.Left := 0;
  NodeNumberEdit.Top := NodeTypeLabel.Top + NodeTypeLabel.Height + 8;
  NodeNumberEdit.Width := 200;
  NodeNumberEdit.Text := '1'; // Default to Master Node (1)

  // Create page for source IP (only shown for child nodes)
  SourceIPPage := CreateInputQueryPage(SymmetricDSPage.ID,
    'SymmetricDS Source Configuration', 'Enter source node information',
    'Please enter the IP address of the source node:');
  SourceIPPage.Add('Source IP Address:', False);
end;

// Handle wizard page changes
function NextButtonClick(CurPageID: Integer): Boolean;
var
  NodeNumberStr: String;
begin
  Result := True;

  if CurPageID = SymmetricDSPage.ID then
  begin
    // Get node number from input
    NodeNumberStr := Trim(NodeNumberEdit.Text);

    // Validate that it's a number
    if NodeNumberStr = '' then
    begin
      MsgBox('Please enter a kiosk number.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    // Try to convert to integer and store in global variable
    try
      NodeNumber := StrToInt(NodeNumberStr);
    except
      MsgBox('Please enter a valid number.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    // If number is 1, treat as master (source node), otherwise treat as child
    IsSourceNode := (NodeNumber = 1);

    // If source node, skip the source IP page
    // If child node, show source IP page
    if IsSourceNode then
    begin
      // Skip source IP page for source nodes
      // We'll handle this in ShouldSkipPage
    end
    else
    begin
      // For child nodes, prepare source IP page
      SourceIPPage.Values[0] := '';
    end;
  end
  else if CurPageID = SourceIPPage.ID then
  begin
    // Only validate if it's a child node
    if not IsSourceNode then
    begin
      SourceIP := Trim(SourceIPPage.Values[0]);
      if SourceIP = '' then
      begin
        MsgBox('Please enter the source IP address.', mbError, MB_OK);
        Result := False;
      end;
    end;
  end;
end;

// Skip source IP page if source node is selected
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;

  // Skip source IP page if source node is selected
  if PageID = SourceIPPage.ID then
  begin
    Result := IsSourceNode;
  end;
end;

// Create engine.properties file for SymmetricDS
procedure CreateEngineProperties();
var
  EngineDir: String;
  EnginePropsPath: String;
  PropsContent: String;
  SyncURL: String;
  RegistrationURL: String;
begin
  // Ensure IsSourceNode is initialized (default to child if not set)
  // This handles cases where wizard pages might not have been shown
  if not (IsSourceNode or (SourceIP <> '')) then
  begin
    // If neither is set, check if we can determine from the combo box
    // Otherwise default to child node
    IsSourceNode := False;
  end;

  // Set default values
  PostgresPort := '5432';
  DatabaseName := 'pos_db';

  // Get device IP
  DeviceIP := GetLocalIP();
  if DeviceIP = '' then
    DeviceIP := 'localhost'; // Fallback

  // Ensure SourceIP is set for child nodes
  if not IsSourceNode and (SourceIP = '') then
  begin
    // If child node but no source IP, use localhost as fallback
    SourceIP := 'localhost';
  end;

  // Generate external ID using node number: KIOSK0 + node number
  ExternalID := 'KIOSK0' + IntToStr(NodeNumber);

  // Create engine directory (ensure parent directories exist)
  EngineDir := ExpandConstant('{app}\symmetric-server\engines');

  // Create parent directories if they don't exist
  if not DirExists(ExpandConstant('{app}\symmetric-server')) then
    CreateDir(ExpandConstant('{app}\symmetric-server'));
  if not DirExists(EngineDir) then
    CreateDir(EngineDir);

  // Create engine.properties file directly in engines folder
  EnginePropsPath := EngineDir + '\engine.properties';

  // Build sync URL using node number
  SyncURL := 'http://' + DeviceIP + ':51415/sync/kiosk-engine-' + IntToStr(NodeNumber);

  // Build registration URL (only for child nodes)
  if not IsSourceNode then
  begin
    RegistrationURL := 'http://' + SourceIP + ':51415/sync/kiosk-engine-1';
  end
  else
  begin
    RegistrationURL := '';
  end;

  // Build properties content using node number
  PropsContent := 'engine.name = kiosk-engine-' + IntToStr(NodeNumber) + #13#10 +
                  'db.driver = org.postgresql.Driver' + #13#10 +
                  'db.url = jdbc:postgresql://localhost:' + PostgresPort + '/' + DatabaseName + #13#10 +
                  'db.user = postgres' + #13#10 +
                  'db.password = postgres' + #13#10 +
                  'sync.url = ' + SyncURL + #13#10 +
                  'group.id = KIOSKS' + #13#10 +
                  'external.id = ' + ExternalID + #13#10;

  // Add registration URL (empty for source nodes, set for child nodes)
  PropsContent := PropsContent + 'registration.url = ' + RegistrationURL + #13#10;

  PropsContent := PropsContent + 'auto.registration = true' + #13#10;

  // Save properties file (replace if exists)
  try
    SaveStringToFile(EnginePropsPath, PropsContent, False);
    // Log success for debugging
    SaveStringToFile(ExpandConstant('{app}\logs\engine_properties.log'),
      'Engine properties created successfully at: ' + EnginePropsPath + #13#10 +
      'DeviceIP: ' + DeviceIP + #13#10 +
      'ExternalID: ' + ExternalID + #13#10, False);
  except
    // If save fails, raise exception to stop installation
    RaiseException('Failed to create engine.properties file at: ' + EnginePropsPath);
  end;
end;

// This event is called during installation at various steps
// Create settings.txt file in root folder with kiosk number
procedure CreateSettingsFile();
var
  SettingsPath: String;
  SettingsContent: String;
begin
  SettingsPath := ExpandConstant('{app}\settings.txt');
  SettingsContent := 'kiosk.no=' + IntToStr(NodeNumber) + #13#10;

  try
    SaveStringToFile(SettingsPath, SettingsContent, False);
  except
    RaiseException('Failed to create settings.txt file at: ' + SettingsPath);
  end;
end;

// We use it to test PostgreSQL connection and create database without cmd.exe or PowerShell
procedure CurStepChanged(CurStep: TSetupStep);
begin
  // After files are installed, test connection and create database
  if CurStep = ssPostInstall then
  begin
    if ShouldCreateDatabase() then
    begin
      TestPostgresConnection();
      CreatePostgresDatabase();
      // Run database migrations after database creation
      RunDatabaseMigrations();
    end;

    // Create SymmetricDS engine.properties file
    CreateEngineProperties();

    // Create settings.txt file with kiosk number
    CreateSettingsFile();
  end;
end;

// This function runs immediately when uninstall starts.
// It scans the Windows Task Manager for "pos_app.exe".

function InitializeUninstall(): Boolean;
var
  WbemLocator: Variant;
  WMIService: Variant;
  WbemObjectSet: Variant;
begin
  Result := True; // Default to allowing uninstall

  try
    // Connect to WMI (Windows Management Instrumentation)
    WbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := WbemLocator.ConnectServer('', 'root\CIMV2', '', '');

    // Query for the specific process name "pos_app.exe"
    WbemObjectSet := WMIService.ExecQuery('SELECT Name FROM Win32_Process Where Name="pos_app.exe"');

    // If Count > 0, it means the process is running in the background or foreground
    if (WbemObjectSet.Count > 0) then
    begin
      MsgBox('The application "POS App" is currently running.' + #13#10 + #13#10 +
             'Please close the application and try again.', mbError, MB_OK);

      // Return False to CANCEL the uninstallation
      Result := False;
    end;

  except
    // If WMI isn't available (very rare), we allow the uninstall to proceed
    // to prevent the user from being stuck.
  end;
end;
