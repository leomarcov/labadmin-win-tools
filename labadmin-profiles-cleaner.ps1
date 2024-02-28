#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated user profiles cleaner
.DESCRIPTION
    Automated user profiles cleaner for backup and autorestore at startup according scheduled rules
    Each profile folder is backup in c:\users\labadmin-profiles-cleaner\ and a <username>.cfg file is generated
    Profile config <username>.cfg file JSON options are:
        cleanAfterDays: Number of days from last clean to next autoclean (0 clean in each reboot, 1 clean every day, etc)
        skipUser      : Boolean (true or false) to skip this user from autoclean (skips cleanAfterDays and cleanAllways)
        cleanAlways   : Array of relative paths to clean on every call
        lastClean     : Date when last clean was performed
    
	INSTALLATION NOTES
	Once script is installed in Program Files folder, to config autostart script open gpedit.msc and config 2 group policies:
      * Exec script at startup:
        - Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts
        - Script to exec: C:\Program Files\labadmin\labadmin-win-tools\labadmin-profiles-cleaner.ps1
        - Params: -RestoreProfile -Log
      * Disable run start asynchronously:
        - Computer Configuration > Administrative Templates > System > Scripts > Run startup scripts asynchronously
        - Set to Disabled

.PARAMETER CreateBackup
    Backup (or update backup if previos backup exists) users profiles to c:\users\labadmin-profiles-cleaner\
    For new backups default <username>.cfg file is generated
    Parameter -Users must be given with list of users to backup
.PARAMETER RestoreProfiles
    Try to restore profiles according user backup profile config
.PARAMETER Users
    List of users to backup/restore/modify-config
.PARAMETER Force
    Force profile clean and ommits skipUser and cleanAfterDays config
.PARAMETER Log
    Save output to log file in c:\users\labadmin-profiles-cleaner\log.txt
.PARAMETER ShowConfig
	Show all (or -users list) users config
.PARAMETER showlog
	Show log file Content
.PARAMETER ModifyUsersConfig
	Modify all (or -users list) users config file 
	Modified values are given with parameters: CleanAfterDays, SkipUser, CleanAllways and LastClean

.NOTES
    File Name: labadmin-profiles-cleaner.ps1
    Author   : Leonardo Marco
#>

Param(
  [parameter(Mandatory=$true, ParameterSetName="create")]
  [Switch]$BackupProfiles,

  [parameter(Mandatory=$true, ParameterSetName="restore")]
  [Switch]$RestoreProfiles,

  [parameter(Mandatory=$true, ParameterSetName="showlog")]
  [Switch]$ShowLog,
  
  [parameter(Mandatory=$true, ParameterSetName="showuser")]
  [Switch]$ShowConfig,

  [parameter(Mandatory=$true, ParameterSetName="modifyconfig")]
  [Switch]$ModifyUsersConfig,
  [parameter(Mandatory=$false, ParameterSetName="modifyconfig")]
  [Int]$CleanAfterDays,
  [parameter(Mandatory=$false, ParameterSetName="modifyconfig")]
  [String]$SkipUser,
  [parameter(Mandatory=$false, ParameterSetName="modifyconfig")]
  [String[]]$CleanAllways,
  [parameter(Mandatory=$false, ParameterSetName="modifyconfig")]
  [DateTime]$LastClean,
  
  [parameter(Mandatory=$true, ParameterSetName="create")]
  [parameter(Mandatory=$false, ParameterSetName="restore")]
  [parameter(Mandatory=$false, ParameterSetName="showuser")]
  [parameter(Mandatory=$false, ParameterSetName="modifyconfig")]
  [String[]]$Users,
  
  [parameter(ParameterSetName="restore")]
  [Switch]$Force,
  
  [parameter(Mandatory=$false, ParameterSetName="create")]
  [parameter(Mandatory=$false, ParameterSetName="restore")]
  [Switch]$Log
)


#### CONFIG VARIABLES ############################################
$backups_path="${ENV:SystemDrive}\Users\labadmin-profiles-cleaner"                       # Path to save backups and configs
$log_path="${backups_path}\log.txt"                                                      # Path to save logs
$default_config=@{
    cleanAfterDays=1                                                                     # Days after spend to exec a new profile autoclean
    lastClean=(Get-Date -Format "yyy-MM-dd")                                             # Date of last autoclean executed
    skipUser=$false                                                                      # Skip this user of autoclean
    cleanAllways=@("\Appdata\Local\Google\Chrome","\Appdata\Local\Mozilla\Firefox")      # Items inside profile user to clean on every call
    #cleanAllways=@("\Appdata\Local\Google\Chrome","\Appdata\Local\Mozilla\Firefox","\Appdata\Local\Microsoft\Credentials","\Appdata\Local\Microsoft\IdentityCache","\Appdata\Local\Microsoft\TokenBroker","\Appdata\Local\Microsoft\OneAuth","\Appdata\Local\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy","\Appdata\Local\ConnectedDevicesPlataform","\Appdata\Roaming\Microsoft\Crypto\Keys","\Appdata\Roaming\Microsoft\SystemCertificates","\Appdata\Local\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy")
    }

function BackupProfiles {
  # Create backups folder and set Administrator permissions
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
    $user_profile="${ENV:SystemDrive}\Users\${u}"
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


function RestoreProfiles {
    # If no users param get all users from each .cfg file in backups dir
    if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }

    foreach($u in $users) {
      Write-Output "`n`n###############################################################################`n#### CLEAN USER: $u `n###############################################################################"
      $user_profile="${ENV:SystemDrive}\Users\${u}"
      $user_backup="${backups_path}\${u}"
      $user_conf_file="${backups_path}\$u.cfg"

      # Check backup folder
      if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
      
      # Get user config
      $user_conf=@{}; (Get-Content $user_conf_file | ConvertFrom-Json).psobject.properties | Foreach { $user_conf[$_.Name] = $_.Value }
      if($user_conf.cleanAfterDays -isnot [int] -OR !$user_conf.lastClean) {
        Write-Output "WARNING! Invalid config file ${user_conf_file}. Skipping user ${u}"
        continue
      }

      # Skip user (only if no force)
      if(!$Force -AND $user_conf.skipUser -eq "true") { Write-Output "Skipping user $u (skipUser config file)"; continue }

      # Scheduled restore
      if($Force -OR (New-TimeSpan -Start ([DateTime]$user_conf.lastClean) -End (Get-Date)).Days -ge $user_conf.cleanAfterDays) {
        Write-Output "Removing user $u profile folder..."
        Remove-Item -Recurse -Force $user_profile
        echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL 
        
        # Update lastClean date
        $user_conf.lastClean=Get-Date -Format "yyy-MM-dd"
        $user_conf | ConvertTo-Json | Out-File $user_conf_file

      # Restore on every call
      } else {
          foreach($d in $user_conf.cleanAllways) { 
              if(!(Test-Path "${user_backup}\$d")) { continue }
              Remove-Item -Recurse -Force "${user_profile}\${d}"
              echo d | robocopy "${user_backup}\${d}" "${user_profile}\${d}" /MIR /XJ /COPYALL /NFL /NDL
          }
      }
    }
}

function ShowConfig {
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }
	foreach($u in $users) {
		$user_conf_file="${backups_path}\$u.cfg"
		Write-Output "#### USER: $u #################################################################"
  		Write-Output "File: ${user_conf_file}"
		Get-Content -Path $user_conf_file
		Write-Output ""
	}
}

function ShowLog {
	Get-Content -Path $log_path
}

function ModifyUsersConfig {
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }
	foreach($u in $users) {
		# Get user config
		$user_conf_file="${backups_path}\$u.cfg"
		$user_conf=@{}; (Get-Content $user_conf_file | ConvertFrom-Json).psobject.properties | Foreach { $user_conf[$_.Name] = $_.Value }
		if($user_conf.cleanAfterDays -isnot [int] -OR !$user_conf.lastClean) {
        	Write-Output "WARNING! Invalid config file ${user_conf_file}. Skipping user ${u}"
        	continue
      	}
		
		# Change user config
		if($CleanAfterDays) { $user_conf.cleanAfterDays=$CleanAfterDays }
  		if($SkipUser) { if($SkipUser -eq "true") { $user_conf.skipUser=$true } else { $user_conf.skipUser=$false } }
    	if($CleanAllways) { $user_conf.cleanAllways=$CleanAllways }
      	if($LastClean) { $user_conf.lastClean=$LastClean.ToString("yyy-MM-dd") }

		# Save user config
 		$user_conf | ConvertTo-Json | Out-File $user_conf_file 
 	} 
}



function main {
	if($BackupProfiles)      	{ BackupProfiles  	}
	elseif($RestoreProfiles) 	{ RestoreProfiles 	}
 	elseif($ShowConfig) 	 	{ ShowConfig      	}	
  	elseif($ShowLog)			{ ShowLog         	}
 	elseif($ModifyUsersConfig)	{ ModifyUsersConfig	}
}

# EXEC 
if(!$Log) { main }

# EXEC > log.txt
else {
    if((Get-ChildItem $logs_path | % {[int]($_.length / 1kb)}) -gt 8) { Remove-Item -Path $log_path }  # Delete log if size > 8kb
    &{ Write-Output "`n`n#########################################################################################################"(Get-Date).toString()"#########################################################################################################"; main } 2>&1 | Out-File -FilePath $log_path -Append 
}
