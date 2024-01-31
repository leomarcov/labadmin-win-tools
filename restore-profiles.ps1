# CONFIG VARIABLES
$restore_users="alumno","pepe"
$backup_folder="C:\Users\profiles-backup\"
$restore_days_file="restore-days.conf"


# CREATE BACKUP
foreach(user in $resore_users) {
  robocopy "C:\Users\${u}" "${backup_folder}\${u}" /MIR /XJ /COPYALL
}

# RESTORE
foreach(user in $resore_users) {
  echo d | robocopy "${backup_folder}\${u}" "C:\Users\${u}" /MIR /XJ /COPYALL /XD "${backup_folder}\${u}\Desktop" /XD "${backup_folder}\${u}\Downloads" /XD "${backup_folder}\${u}\Documents"
}
