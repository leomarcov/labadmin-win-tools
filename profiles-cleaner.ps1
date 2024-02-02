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
  [String[]]$users,             # Optional list of users to backup or restore instead of .config files
  [Switch]$Force                # Force restore instead of config file dates
)

#### CONFIG VARIABLES ############################################
$backups_path="C:\Users\profiles-cleaner"



#### CREATE PROFILE BACKUP #######################################
if($CreateBackup) {
  if(!$users) { Write-Output "Please, specific users parameter"; exit 1 }

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
    Write-Output "`n`n###############################################################################`n#### BACKUP USER: $u `n###############################################################################"
    $user_profile="C:\Users\${u}"
    $user_backup="${backups_path}\${u}"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup -ErrorAction SilentlyContinue }
    
    # Copy profile
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL
    
    # Save default user config file in backups path
    if(!(Test-Path "${backups_path}\$u.conf")) {
        $default_conf="cleanAfterDays=1`r`nlastClean="+(Get-Date -Format "yyy-MM-dd")+"`r`nskip=false"
        $default_conf | Out-File "${backups_path}\$u.conf" 
    }
  }
  
  exit
}



#### RESTORE PROFILE BACKUP #######################################
# If no users param get users from each .conf file in backups dir
if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.conf) {$f.basename } }

foreach($u in $users) {
  Write-Output "`n`n###############################################################################`n#### CLEAN USER: $u `n###############################################################################"
  $user_profile="C:\Users\${u}"
  $user_backup="${backups_path}\${u}"
  $user_conf_file="${backups_path}\$u.conf"

  # CHECK FOLDER
  if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
  if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }

  # GET USER CONFIG
  $user_conf=Get-Content "$user_conf_file"| ConvertFrom-StringData
  if(!$user_conf -OR !$user_conf.cleanAfterDays -OR !$user_conf.lastClean -OR !$user_conf.skip) {
    Write-Output "WARNING! Invalid config file ${user_conf_file}. Skipping user ${u}"; continue
  }

  # SKIP USER (only if no force)
  if(!$Force -AND $user_conf.skip -eq "true") { Write-Output "Skipping user $u for config file"; continue }


  # SCHEDULED RESTORE
  if($Force -OR (New-TimeSpan -Start ([DateTime]$user_conf.lastClean) -End (Get-Date)).Days -ge $user_conf.cleanAfterDays) {
    echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL
    "cleanAfterDays="+$user_conf.cleanAfterDays+"`r`nlastClean="+(Get-Date -Format "yyy-MM-dd")+"`r`nskip=false" | Out-File $user_conf_file  # Update lastClean date


  # RESTORE ON EVERY CALL
  } else {
      if((Test-Path "${user_backup}\Appdata\Local\Google\Chrome")) { echo d | robocopy "${user_backup}\Appdata\Local\Google\Chrome" "${user_profile}\AppData\Local\Google\Chrome" /MIR /XJ /COPYALL /NFL /NDL }
      if((Test-Path "${user_backup}\Appdata\Local\Mozilla\Firefox")) { echo d | robocopy "${user_backup}\Appdata\Local\Mozilla\Firefox" "${user_profile}\AppData\Local\Mozilla\Firefox" /MIR /XJ /COPYALL /NFL /NDL }
  }

}
