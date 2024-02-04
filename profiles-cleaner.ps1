#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated user profiles cleaner
.DESCRIPTION
    Automated user profiles cleaner for backup and restore at startup 
    Each profile is backup in c:\users\profiles-cleaner\ and a username.cfg file is generated
    Profile config file syntax is:
        cleanAfterDays                      # Number of days until autoclean
        skip                                # Skip autoclean for this user
        cleanAlways                         # Array of relative paths to clean on every call
        lastClean                           # Date when last clean was performed
.PARAMETER CreateBackup
    Backup (or update backup if previos backup exists) current users profiles to c:\users\profiles-cleaner\
    If no use this parameter, instead of backup, profile restore (clean) is done
    Parameter -users must be given with list of users to backup
    For new backups default username.cfg file is generated
.PARAMETER Users
    List of users to backup/restore
    With -CreateBackup this parameter is mandatory
    When restore is optional. If no given all backup profiles stored are used
.PARAMETER Force
    Force profile clean and ommits skip user config
.PARAMETER Log
    Save output to log file in c:\users\profiels-cleaner\log.txt
.NOTES
    File Name      : profiles-cleaner.ps1
    Author         : Leonardo Marco
.EXAMPLE
    profiles-cleaner.ps1 -CreateBackup -Users user1,user2,user3
.EXAMPLE
    profiles-cleaner.ps1
    profiles-cleaner.ps1 -Users user1
    profiles-cleaner.ps1 -Force
#>


#### PARAMETERS ##################################################
Param(
  [Switch]$CreateBackups,            # Backup profiles instead of restore
  [String[]]$Users,                  # Optional list of users to backup or restore instead of .cfg files
  [Switch]$Force,                    # Force restore instead of config file dates
  [Switch]$Log                       # Save to log file
)

#### CONFIG VARIABLES ############################################
$backups_path="C:\Users\profiles-cleaner"                                                # Path to save backups and configs
$log_path="${backups_path}\log.txt"                                                      # Path to save logs
$default_config=@{
    cleanAfterDays=1                                                                     # Days after spend to exec a new profile autoclean
    lastClean=(Get-Date -Format "yyy-MM-dd")                                             # Date of last autoclean executed
    skipUser=$false                                                                      # Skip this user of autoclean
    cleanAllways=@("\Appdata\Local\Google\Chrome","\Appdata\Local\Mozilla\Firefox")     # Items inside profile user to clean on every call
}



#### FUNCTION CreateBackup #######################################
function CreateBackups {
  if(!$users) { Write-Output "Please, specific users parameter"; exit 1 }

  # Create backups folder and set permissions
  if(!(Test-Path $backups_path)) {
    New-Item -ItemType Directory -Force -Path $backups_path | Out-Null   
    attrib +h $backups_path
    $acl = Get-Acl $backups_path
    $acl.SetAccessRuleProtection($true, $false)
    $adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
    $acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name,"FullControl", 3, 0, "Allow")))
    Set-Acl -Path $backups_path -AclObject $acl
  }

  foreach($u in $users) {
    Write-Output "`n`n###############################################################################`n#### BACKUP USER: $u `n###############################################################################"
    $user_profile="C:\Users\${u}"
    $user_backup="${backups_path}\${u}"
    $user_conf_file="${backups_path}\$u.cfg"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup -ErrorAction SilentlyContinue }
    
    # Copy profile
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL
    
    # Save default user config file in backups path
    if(!(Test-Path $user_conf_file)) { $default_config | ConvertTo-Json | Out-File $user_conf_file }
  }
}



#### FUNCTION RestoreProfiles ######################################
function RestoreProfiles {
    # If no users param get all users from each .cfg file in backups dir
    if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }

    foreach($u in $users) {
      Write-Output "`n`n###############################################################################`n#### CLEAN USER: $u `n###############################################################################"
      $user_profile="C:\Users\${u}"
      $user_backup="${backups_path}\${u}"
      $user_conf_file="${backups_path}\$u.cfg"

      # CHECK FOLDER
      if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }

      # GET USER CONFIG
      $user_conf=@{}; (Get-Content $user_conf_file | ConvertFrom-Json).psobject.properties | Foreach { $user_conf[$_.Name] = $_.Value }
      if($user_conf.cleanAfterDays -isnot [int] -OR !$user_conf.lastClean) {
        Write-Output "WARNING! Invalid config file ${user_conf_file}. Skipping user ${u}"
        continue
      }

      # SKIP USER (only if no force)
      if(!$Force -AND $user_conf.skipUser -eq "true") { Write-Output "Skipping user $u for config file"; continue }

      # SCHEDULED RESTORE
      if($Force -OR (New-TimeSpan -Start ([DateTime]$user_conf.lastClean) -End (Get-Date)).Days -ge $user_conf.cleanAfterDays) {
        Write-Output "Removing user $u profile folder..."
        Remove-Item -Recurse -Force $user_profile
        echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL 
        
        # Update lastClean date
        $user_conf.lastClean=Get-Date -Format "yyy-MM-dd"
        $user_conf | ConvertTo-Json | Out-File $user_conf_file

      # RESTORE ON EVERY CALL
      } else {
          foreach($d in $user_conf.cleanAllways) { 
              if(!(Test-Path "${user_backup}\$d")) { continue }
              Remove-Item -Recurse -Force "${user_profile}\${d}"
              echo d | robocopy "${user_backup}\${d}" "${user_profile}\${d}" /MIR /XJ /COPYALL /NFL /NDL
          }
      }
    }
}


#### FUNCTION main
function main {
    if($CreateBackups) {  CreateBackups  }
    else               { RestoreProfiles }
}

# Exec 
if(!$Log) { main }
# Exec > log.txt
else {
    if((Get-ChildItem $logs_path | % {[int]($_.length / 1kb)}) -gt 4) { Remove-Item -Path $log_path }  # Delete log if size > 4kb
    &{ Write-Output "`n`n#########################################################################################################"(Get-Date).toString()"#########################################################################################################"; main } 2>&1 | Out-File -FilePath $log_path -Append 
}
      

