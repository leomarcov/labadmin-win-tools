###################################################################
#### PARAMETERS
###################################################################
Param(
  [Switch]$CreateBackup,    # Backup profiles instead of restore
  [String[]]$users                     # List of users to backup/restore instead of $fixed_users
)


###################################################################
#### CONFIG VARIABLES
###################################################################
$fixed_users="alumno","pepe"
$backups_path="C:\Users\restore-profile"

if(!$users) { $users=$fixed_users }


###################################################################
#### CREATE PROFILE BACKUP
###################################################################
if($CreateBackup) {
  New-Item -ItemType Directory -Force -Path $backups_path | Out-Null   # Create backups path if no exists
  foreach($u in $users) {
    $user_profile="C:\Users\${u}"
    $user_backup="${backups_path}\${u}"
    
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL
  }

  exit
}


###################################################################
#### RESTORE PROFILE BACKUP
###################################################################
foreach($u in $users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"
  
  # Every call restore:
  echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL 
  echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL 

  # Scheduled restore:
  $user_conf = Get-Content "${user_backup}\restore-profile.conf"| ConvertFrom-StringData

  
  $user_conf = Get-Content "${user_backup}\restore-profile.conf"| ConvertFrom-StringData
  $user_restore_conf

  if((New-TimeSpan -Start ([DateTime]$user_conf.lastRestore) -End (Get-Date)).Days -ge 1) {
    echo d | robocopy "${user_backup}\" "${user_profile}" /MIR /XJ /COPYALL 
  }
}
