# CONFIG VARIABLES
$restore_users="alumno","pepe"
$backups_path="C:\Users\restore-profile\"
$restore_cache_filename="restore-profile.conf"
$default_restore_days="1"

# CREATE BACKUP
foreach(user in $resore_users) {
  robocopy "C:\Users\${u}" "${backups_path}\${u}" /MIR /XJ /COPYALL
}

# RESTORE
foreach(user in $restore_users) {
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"
  
  # Each call restore
  echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL 
  echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL 

  $user_conf = Get-Content $b| ConvertFrom-StringData
  $user_restore_conf
  # Scheduled restore

}
