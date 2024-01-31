# CONFIG VARIABLES
$restore_users="pepe"
$backup_folder="C:\Users\profiles-backup\"



robocopy c:\users\pepe c:\users\pepe_bak /mir /xj /copyall

echo d | robocopy c:\users\pepe_bak2 c:\users\pepe /mir /xj /copyall /xd c:\users\pepe_bak2\desktop /xd c:\users\pepe_bak2\downloads
