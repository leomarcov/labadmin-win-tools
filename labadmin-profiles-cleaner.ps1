#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated user profiles cleaner
.DESCRIPTION
    Automated user profiles cleaner for backup and autorestore at startup according scheduled rules
    Each profile folder is backup in c:\users\labadmin-profiles-cleaner\ and a <username>.cfg file is generated
    Profile config <username>.cfg file JSON options are:
        skipUser                  : Boolean (true or false) to skip this user from autoclean (skips fullCleanDays)
		fullCleanDays             : Number of days from last full clean to next autoclean (0 clean in each reboot, 1 clean every day, etc)
		softCleanDays             : Number of days from last soft clean to next autoclean (0 clean in each reboot, 1 clean every day, etc)
		lastFullClean             : Date when last full clean was performed
		lastSoftClean             : Date when last soft or full clean was performed
		$fullCleanRemovePaths[]   : List of paths to remove shen full clean
		$fullCleanRestorePaths[]  : List of paths to restore from backup profile on full clean
		$softCleanRemovePaths[]   : List of patsh to remove when soft or full clean
		$softCleanRestorePaths[]  : List of paths to restore from backup profile on soft or full clean
	
	INSTALLATION NOTES
	Once script is installed in Program Files folder, to config autostart script open gpedit.msc and config 2 group policies:
      * Exec script at startup:
        - Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts
        - Script to exec: C:\Program Files\labadmin\labadmin-win-tools\labadmin-profiles-cleaner.ps1
        - Params: -CleanProfiles -Log
      * Disable run start asynchronously:
        - Computer Configuration > Administrative Templates > System > Scripts > Run startup scripts asynchronously
        - Set to Disabled

.PARAMETER BackupProfiles
    Backup (or update backup if previos backup exists) users profiles to c:\users\labadmin-profiles-cleaner\
    For new backups default <username>.cfg file is generated
    Parameter -Users must be given with list of users to backup
.PARAMETER RestoreProfiles
    Restore full profile from backup
.PARAMETER CleanProfiles
	Clean profiles according CleanMode
.PARAMETER CleanMode
    Mode to perform clean: full or soft (clean full/soft and skips schedule config and skipuser) and auto (performs full, soft o none according schedule config and skipuser)
.PARAMETER Users
    List of users to backup/restore/clean
.PARAMETER Log
    Save output to log file in c:\users\labadmin-profiles-cleaner\log.txt

.NOTES
    File Name: labadmin-profiles-cleaner.ps1
    Author   : Leonardo Marco
#>

Param(
	[parameter(Mandatory=$true, ParameterSetName="backup")]
	[Switch]$BackupProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="restore")]
	[Switch]$RestoreProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="clean")]
	[Switch]$CleanProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="backup")]
	[parameter(Mandatory=$false, ParameterSetName="restore")]
	[parameter(Mandatory=$false, ParameterSetName="clean")]
	[String[]]$Users,
	
	[parameter(Mandatory=$true, ParameterSetName="clean")]
	[ValidateSet('full','soft','auto')]
	[string]$CleanMode = 'auto',
	
	[parameter(Mandatory=$false, ParameterSetName="create")]
	[parameter(Mandatory=$false, ParameterSetName="restore")]
	[parameter(Mandatory=$false, ParameterSetName="clean")]
	[Switch]$Log
)


#### CONFIG VARIABLES ############################################
$backups_path="${ENV:SystemDrive}\Users\labadmin-profiles-cleaner"                       # Path to save backups and configs
$log_path="${backups_path}\log.txt"                                                      # Path to save logs
$default_config=@{
	skipUser=$false                                                                      # Skip this user of autoclean
	lastFullClean=(Get-Date -Format "yyyy-MM-dd")                                        # Date of last full clean executed
	lastSoftClean=(Get-Date -Format "yyyy-MM-dd")                                        # Date of last soft clean executed
	fullCleanDays=1                                                                      # Days after do full profile clean
	softCleanDays=0																		 # Days after do soft profile clean

	fullCleanRemovePaths=@(
		"\Downloads\*",
		"\Documents\*",
		"\Desktop\*",
		"\Pictures\*",
		"\Videos\*",
		"\Music\*",
		"\Favorites\*",
		"\Contacts\*",
		"\Searches\*",
		"\Saved Games\*",
		"\Links\*",		
		"\AppData\Local\Temp\*",
		"\AppData\Local\Microsoft\Windows\Caches\*",
		"\AppData\Local\Microsoft\Windows\INetCache\*",
		"\AppData\Local\Microsoft\Windows\WebCache\*",
		"\AppData\Local\Microsoft\Windows\Explorer\*",
		"\AppData\LocalLow\*",
		"\AppData\Roaming\Microsoft\Windows\Recent\*",
		"\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*",
		"\AppData\Roaming\Microsoft\Office\Recent\*",
		"\AppData\Roaming\Microsoft\Teams\*",
		"\AppData\Roaming\Microsoft\Windows\Themes\*"
	)
	fullCleanRestorePaths=@(
	)
	
	softCleanRemovePaths=@(
		"\Appdata\Local\Microsoft\Credentials",
		"\Appdata\Local\Microsoft\IdentityCache",
		"\Appdata\Local\Microsoft\TokenBroker",
		"\Appdata\Local\Microsoft\OneAuth",
		"\Appdata\Local\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy",
		"\Appdata\Local\ConnectedDevicesPlatform",
		"\Appdata\Roaming\Microsoft\Crypto\Keys",
		"\Appdata\Roaming\Microsoft\SystemCertificates",
		"\Appdata\Local\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"
	)

	softCleanRestorePaths=@(
		"AppData\Local\Google\Chrome\",
		"AppData\Local\Microsoft\Edge\",
		"AppData\Roaming\Mozilla\Firefox\Profiles\"
	)
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
    $user_config_file="${backups_path}\$u.cfg"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup -ErrorAction SilentlyContinue }
    
    # Copy profile
	& "${env:SystemRoot}\System32\cmd.exe" /c "rmdir /s /q ${user_profile}\AppData\Local\Microsoft\Windows\SFAP\" *> $null       # Delete this folder first to avoid access denied in Windows 11
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL
    Remove-Item -Force -Path "${user_backup}\AppData\Local\Microsoft\Windows\UsrClass.dat"	# Avoid restore UsrClass.dat file to prevent Start button crash (will be deleted on each restore)
    
    # Save default user config file in backups path
    if(!(Test-Path $user_config_file)) { $default_config | ConvertTo-Json | Out-File $user_config_file }
  }
}

function RestoreProfiles {
	# If no users param get all users from each .cfg file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }
	
	foreach($u in $users) {
		Write-Output "`n`n###############################################################################`n#### RESTORE PROFILE: $u `n##########################################################################"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.cfg"
		
		# Check backup folder
		if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
		
		Write-Output "Removing user $u profile folder..."
		# Remove-Item -Recurse -Force $user_profile
		& "${env:SystemRoot}\System32\cmd.exe" /c "rmdir /s /q ${user_profile}"
		echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL 
	}
}


function CleanProfiles {
	# If no users param get all users from each .cfg file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.cfg) {$f.basename } }

	foreach($u in $users) {
		Write-Output "`n`n###############################################################################`n#### CLEAN PROFILE: $u `n############################################################################"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.cfg"		
		
		# Check backup folder
		if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
		# Get user config
		$user_conf=@{}; (Get-Content $user_config_file | ConvertFrom-Json).psobject.properties | Foreach { $user_conf[$_.Name] = $_.Value }
		if($user_conf.fullCleanDays -isnot [int] -OR !$user_conf.lastFullClean) {
			Write-Output "WARNING! Invalid config file ${user_config_file}. SAVING DEFAULT CONFIG FILE!"
			$default_config | ConvertTo-Json | Out-File $user_config_file
			$user_conf = $default_config.Clone()
		}
		
		# Skip user if skipUser config true
		if($CleanMode -eq "auto" -AND $user_conf.skipUser -eq "true") { Write-Output "Skipping user $u (skipUser config file)"; continue }
		
		# Skip if fullCleanDays=0 and last shutdown was unexpected
		if($CleanMode -eq "auto" -AND  $user_conf.fullCleanDays -eq 0) {
			$lastShutdown=(Get-WinEvent -FilterHashtable @{logname = 'System'; id = 6009})[0].TimeCreated
			$lastUnexpectedShutdown=(Get-WinEvent -FilterHashtable @{logname = 'System'; id = 6008})[0].TimeCreated
			if($lastShutdown -eq $lastUnexpectedShutdown) { Write-Output "Skipping user $u (last shutdown unexpected)"; continue }
		}
		
		# Check CleanMode auto: full or soft
		if($CleanMode -eq "auto") {
			$CleanMode="none"
			if((New-TimeSpan -Start ([DateTime]$user_conf.lastFullClean) -End (Get-Date)).Days -ge $user_conf.softCleanDays) { $CleanMode="soft" }
			if((New-TimeSpan -Start ([DateTime]$user_conf.lastFullClean) -End (Get-Date)).Days -ge $user_conf.fullCleanDays) { $CleanMode="full" }
		}
		
		# FULL CLEAN
		if($CleanMode -eq "full") {
			Write-Output "Full cleaning user profile folder: $user_profile"
			$removePaths=$user_conf.fullCleanRemovePaths+$user_conf.softCleanRemovePaths
			$restorePaths=$user_conf.fullCleanRestorePaths+$user_conf.softCleanRestorePaths		

			# Update lastFullClean and lastSoftClean date 
			$user_conf.lastFullClean=Get-Date -Format "yyyy-MM-dd"
			$user_conf.lastSoftClean=Get-Date -Format "yyyy-MM-dd"
			$user_conf | ConvertTo-Json | Out-File $user_config_file
		
		# SOFT CLEAN
		} elseif($CleanMode -eq "soft") {
			Write-Output "Soft cleaning user profile folder: $user_profile"
			$removePaths=$user_conf.softCleanRemovePaths
			$restorePaths=$user_conf.softCleanRestorePaths
			# Update lastSoftClean date 		
			$user_conf.lastSoftClean=Get-Date -Format "yyyy-MM-dd"
			$user_conf | ConvertTo-Json | Out-File $user_config_file			
		} else {
			Write-Output "Skipping user profile folder $u (auto mode not select soft or full cleaning)"
			continue
		}
		
		# REMOVE PATHS
		foreach($rp in $removepaths) {
			$fp=Join-Path $user_profile $rp
			if(Test-Path $fp -ErrorAction SilentlyContinue){
				Remove-Item -Recurse -Force $fp
			}
		}
		# RESTORE PATHS
		foreach($rp in $restorepaths) {
			$fp_dest=Join-Path $user_profile $rp
			$fp_src=Join-Path $user_backup $rp
			if(Test-Path $fp -ErrorAction SilentlyContinue){
				echo d | robocopy ${fp_src} ${fp_dest} /MIR /XJ /COPYALL /NFL /NDL 
			}
		}	
	}
}




function main {
	if($BackupProfiles)      	{ BackupProfiles  	}
	elseif($RestoreProfiles) 	{ RestoreProfiles 	}
 	elseif($CleanProfiles)		{ CleanProfiles	}
}

# EXEC 
if(!$Log) { main }

# EXEC > log.txt
else {
    if((Get-ChildItem $log_path | % {[int]($_.length / 1kb)}) -gt 8) { Remove-Item -Path $log_path }  # Delete log if size > 8kb
    &{ Write-Output "`n`n#########################################################################################################"(Get-Date).toString()"#########################################################################################################"; main } 2>&1 | Out-File -FilePath $log_path -Append 
}
