# CONFIG VARIABLES
$restore_users="alumno","pepe"
$backup_folder="C:\Users\profiles-backup\"
$restore_days_file="restore-days.conf"
$default_restore_days="1"

# CREATE BACKUP
foreach(user in $resore_users) {
  robocopy "C:\Users\${u}" "${backup_folder}\${u}" /MIR /XJ /COPYALL
}

# RESTORE
foreach(user in $resore_users) {
  echo d | robocopy "${backup_folder}\${u}" "C:\Users\${u}" /MIR /XJ /COPYALL /XD "${backup_folder}\${u}\Desktop" /XF "${backup_folder}\${u}\${restore_days_file}" /XD "${backup_folder}\${u}\Downloads" /XD "${backup_folder}\${u}\Documents"
}
