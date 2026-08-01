param(
    [Parameter(Mandatory=$true)]
    [string]$AppDir
)

# Creates a dedicated, non-admin local Windows account and configures
# AutoAdminLogon for it, so a kiosk machine comes all the way back up
# (services + the visible pos_app.exe window, via the {commonstartup}
# shortcut in installer.iss) after an unattended reboot with nobody there
# to log in. Idempotent: safe to re-run on every install/upgrade.

$ErrorActionPreference = 'Continue'
$logs = "$AppDir\logs"
if (!(Test-Path $logs)) { New-Item -ItemType Directory -Force $logs | Out-Null }

try { Start-Transcript -Path "$logs\configure-autologon-install.log" -Force | Out-Null } catch { }

$userName = "POSKiosk"

# Random password the account is only ever reached through AutoAdminLogon, so
# nobody needs to know or type it. Suffix guarantees upper/lower/digit/symbol
# so it passes default Windows password-complexity policy.
$raw = ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')).Substring(0, 20)
$password = "$raw" + "Aa1!"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

Write-Host "Configuring kiosk auto-logon account '$userName'..."

$existing = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Account already exists, resetting password..."
    Set-LocalUser -Name $userName -Password $securePassword `
        -PasswordNeverExpires $true -UserMayChangePassword $false
} else {
    Write-Host "Creating local account..."
    New-LocalUser -Name $userName -Password $securePassword -FullName "POS Kiosk" `
        -Description "Dedicated account for unattended POS Kiosk auto-logon" `
        -PasswordNeverExpires -UserMayNotChangePassword -AccountNeverExpires | Out-Null
}
Add-LocalGroupMember -Group "Users" -Member $userName -ErrorAction SilentlyContinue | Out-Null

$winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $winlogon -Name "AutoAdminLogon"    -Value "1" -Type String
Set-ItemProperty -Path $winlogon -Name "DefaultUserName"   -Value $userName -Type String
Set-ItemProperty -Path $winlogon -Name "DefaultDomainName" -Value $env:COMPUTERNAME -Type String
Set-ItemProperty -Path $winlogon -Name "DefaultPassword"   -Value $password -Type String

Write-Host "Auto-logon configured for '$userName' on $env:COMPUTERNAME."
Write-Host "configure-autologon.ps1 completed."
try { Stop-Transcript | Out-Null } catch { }
