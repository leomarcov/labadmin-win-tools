###################################################################
#### CONFIG VARIABLES
###################################################################
$fixed_users="alumno","pepe"
$backups_path="C:\Users\restore-profile\"

###################################################################
#### PARAMETERS
###################################################################
Param(
  [switch]$backup,        # Backup profiles
  [switch]$restore        # Restore profiles
  [String]$users          # List of users to backup/restore instead of $fixed_users
)

if(!$users) { $users=$fixed_users }

###################################################################
#### CREATE BACKUP
###################################################################
foreach(user in $users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"
  
  New-Item -ItemType Directory -Force -Path $bachups_path
  robocopy $user_profile $user_backup /MIR /XJ /COPYALL
}


# RESTORE
foreach(u in $users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"
  
  # Resotre every call
  echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL 
  echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL 

  # Scheduled restore
  $user_conf = Get-Content "${user_backup}\restore-profile.conf"| ConvertFrom-StringData
  $user_restore_conf

  echo d | robocopy "${user_backup}\" "${user_profile}" /MIR /XJ /COPYALL 
}
