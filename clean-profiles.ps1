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
    clean-profiles.ps1 -CreateBackup
.EXAMPLE
    clean-profiles.ps1 
#>


#### PARAMETERS ##################################################
Param(
  [Switch]$CreateBackup,        # Backup profiles instead of restore
  [String[]]$users              # Optional list of users to backup/restore instead of $fixed_users
)

#### CONFIG VARIABLES ############################################
$fixed_users="alumno","pepe","manolo"
$backups_path="C:\Users\clean-profiles"

if(!$users) { $users=$fixed_users }



#### CREATE PROFILE BACKUP #######################################
if($CreateBackup) {
  # Create backups folder and set permissions
  if(!(Test-Path $backups_path)) {
    New-Item -ItemType Directory -Force -Path $backups_path | Out-Null   
    $acl = Get-Acl $backups_path
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($acl.owner,"FullControl","Allow")
    $acl.SetOwner((New-Object System.Security.Principal.Ntaccount($acl.owner)))
    $acl.SetAccessRuleProtection($true,$false)
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $backups_path
  }
  º
  foreach($u in $users) {
    $user_profile="C:\Users\${u}"
    $user_backup="${backups_path}\${u}"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup }
    
    # Copy profile
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL
    
    # Copy default user config file
    $default_conf=@{ cleanAfterDays=1; lastClean=(Get-Date -Format "yyy-MM-dd") }
  }
  exit
}

exit

#### RESTORE PROFILE BACKUP #######################################
foreach($u in $users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"

  if(!Test-Path $user_profile) { Write-Output "Folder $user_profile not exists. Skipping user $u"; continue }
  if(!Test-Path $user_backup)  { Write-Output "Folder $user_profile not exists. Skipping user $u"; continue }
  
  # RESTORE EVERY CALL
  echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL /NFL /NDL
  echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL /NFL /NDL

  # SCHEDULED RESTORE
  $user_conf = Get-Content "${user_backup}\clean-profile.conf"| ConvertFrom-StringData
  $hashtable.GetEnumerator()|select name,value|convertto-csv | out-file file.csv

  $user_conf = Get-Content "${user_backup}\clean-profile.conf"| ConvertFrom-StringData
  $user_restore_conf

  if((New-TimeSpan -Start ([DateTime]$user_conf.lastRestore) -End (Get-Date)).Days -ge 1) {
    echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL /XF "${user_backup}\clean-profile.conf"
    $user_conf.last=Get-Date -Format "yyyy-MM-dd"
  }
}
