#Requires -RunAsAdministrator

<#
.SYNOPSIS
    A brief description of the function or script. This keyword can be used
    only once in each topic.
.DESCRIPTION
    A detailed description of the function or script. This keyword can be
    used only once in each topic.
.NOTES
    File Name      : xxxx.ps1
    Author         : Leonardo Marco
.EXAMPLE
    profiles-cleaner.ps1 -CreateBackup
.EXAMPLE
    profiles-cleaner.ps1 
#>


#### PARAMETERS ##################################################
Param(
  [Switch]$CreateBackup,        # Backup profiles instead of restore
  [String[]]$users              # Optional list of users to backup/restore instead of $fixed_users
)

#### CONFIG VARIABLES ############################################
$fixed_users="alumno","pepe","manolo"
$backups_path="C:\Users\profiles-cleaner"

if(!$users) { $users=$fixed_users }



#### CREATE PROFILE BACKUP #######################################
if($CreateBackup) {
  # Create backups folder and set permissions
  if(!(Test-Path $backups_path)) {
    New-Item -ItemType Directory -Force -Path $backups_path | Out-Null   
    attrib +h $backups_path
    $acl = Get-Acl $backups_path
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($acl.owner,"FullControl","Allow")
    $acl.SetOwner((New-Object System.Security.Principal.Ntaccount($acl.owner)))
    $acl.SetAccessRuleProtection($true,$false)
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $backups_path
  }

  foreach($u in $users) {
    $user_profile="C:\Users\${u}"
    $user_backup="${backups_path}\${u}"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup }
    
    # Copy profile
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL
    
    # Save default user config file in profile backup
    $default_conf="cleanAfterDays=1`nlastClean="+(Get-Date -Format "yyy-MM-dd")
    $default_conf | Out-File "${user_backup}\profiles-cleaner.conf"  
  }
  exit
}



#### RESTORE PROFILE BACKUP #######################################
foreach($u in $users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"

  if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
  if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
  
  # RESTORE ON EVERY CALL
  if((Test-Path "${user_backup}\Appdata\Local\Google\Chrome")) { echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL /NFL /NDL }
  if((Test-Path "${user_backup}\Appdata\Local\Mozilla\Firefox")) { echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL /NFL /NDL }

  # SCHEDULED RESTORE
  $user_conf = Get-Content "${user_backup}\profiles-cleaner.conf"| ConvertFrom-StringData
  if(!$user_conf -OR (New-TimeSpan -Start ([DateTime]$user_conf.lastClean) -End (Get-Date)).Days -ge $user_conf.cleanAfterDays) {
    #echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL /XF "${user_backup}\profiles-cleaner.conf"
    echo "robocopy bla bla bla"
    "cleanAfterDays="+$user_conf.cleanAfterDays+"`nlastClean="+(Get-Date -Format "yyy-MM-dd") | Out-File "${user_backup}\profiles-cleaner.conf"  # Update lastClean date
  }
}
