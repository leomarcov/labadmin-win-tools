#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated user profiles cleaner
.DESCRIPTION
    Automated user profiles cleaner for backup and autoclean at startup according scheduled rules
    Each profile folder is backup in c:\users\labadmin-profiles-cleaner\ and a <username>.json file is generated
    Profile config <username>.json file JSON options are:
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
    For new backups default <username>.json file is generated
    Parameter -Users must be given with list of users to backup

.PARAMETER RestoreProfiles
    Restore full profile from backup
	Parameter -Users can be given to select profiles to restore (by default all config profiles will be restored)

.PARAMETER RemoveProfiles
	Delete backup profiles saved
	Parameter -Users must be given with list of users profiles to remove

.PARAMETER ResetConfig
	Set default config to backup users profiles
	Parameter -Users can be given to select profiles to set default config (by default all config profiles will be restored)

.PARAMETER CleanProfiles
	Clean profiles according CleanMode (auto, full or soft)
	Parameter -Users can be given to select profiles to clean (by default all config profiles will be restored)

.PARAMETER CleanMode
    Mode to perform clean: 
	  auto: performs full, soft or none according schedule config and skipuser
	  full: force full clean
	  soft: force soft clean

.PARAMETER Users
    List of users to backup/restore/remove/clean

.PARAMETER Log
    Save output to log file in c:\users\labadmin-profiles-cleaner\log.txt

.NOTES
    File Name: labadmin-profiles-cleaner.ps1
	Version  : 20260913
    Author   : Leonardo Marco
#>

Param(
	[parameter(Mandatory=$true, ParameterSetName="backupreg")]
	[Switch]$BackupRegistries,

	[parameter(Mandatory=$true, ParameterSetName="backup")]
	[Switch]$BackupProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="restore")]
	[Switch]$RestoreProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="clean")]
	[Switch]$CleanProfiles,
	
	[parameter(Mandatory=$true, ParameterSetName="remove")]
	[Switch]$RemoveProfiles,	
	
	[parameter(Mandatory=$true, ParameterSetName="resetconfig")]
	[Switch]$ResetConfig,	
	
	[parameter(Mandatory=$false, ParameterSetName="backupreg")]
	[parameter(Mandatory=$true, ParameterSetName="backup")]
	[parameter(Mandatory=$true, ParameterSetName="remove")]
	[parameter(Mandatory=$false, ParameterSetName="restore")]
	[parameter(Mandatory=$false, ParameterSetName="resetconfig")]
	[parameter(Mandatory=$false, ParameterSetName="clean")]
	[String[]]$Users,
	
	[parameter(Mandatory=$false, ParameterSetName="clean")]
	[ValidateSet('full','soft','auto')]
	[string]$CleanMode = 'auto',
	
	[parameter(Mandatory=$false, ParameterSetName="backupreg")]
	[parameter(Mandatory=$false, ParameterSetName="backup")]
	[parameter(Mandatory=$false, ParameterSetName="remove")]
	[parameter(Mandatory=$false, ParameterSetName="restore")]
	[parameter(Mandatory=$false, ParameterSetName="resetconfig")]
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
		"\Pictures\*",
		"\Videos\*",
		"\Music\*",
		"\Favorites\*",
		"\Contacts\*",
		"\Searches\*",
		"\Saved Games\*",
		"\Links\*",		
		"\AppData\Local\Microsoft\Windows\Caches\*",
		"\AppData\Local\Microsoft\Windows\INetCache\*",
		"\AppData\Local\Microsoft\Windows\WebCache\*",
		"\AppData\Local\Microsoft\Windows\Explorer\*",
		"\AppData\Local\Microsoft\Office\UnsavedFiles\*",
		"\AppData\LocalLow\*",
		"\AppData\Roaming\Microsoft\Windows\Recent\*",
		"\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*",
		"\AppData\Roaming\Microsoft\Office\Recent\*",
		"\AppData\Roaming\Microsoft\Teams\*",
		"\AppData\Roaming\Microsoft\Windows\Themes\*"
	)
	fullCleanRestorePaths=@(
		"\NTUSER.DAT",
		"\Desktop\"
	)
	
	softCleanRemovePaths=@(
		"\AppData\Local\Temp\*",	
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
		"\NTUSER.DAT",
		"\AppData\Local\Google\Chrome\User data\",
		"\AppData\Local\Microsoft\Edge\User data\",
		"\AppData\Roaming\Mozilla\Firefox\",
		"\AppData\Roaming\Code\"
	)
}


function ResetConfig {
	# If no users param get all users from each .json file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.json) {$f.basename } }
	
	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nRESET CONFIG: $u`n---------------------------------------------------------------------------------------------------------"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.json"
		
		if(!(Test-Path $user_backup)) { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
		
		$default_config | ConvertTo-Json | Out-File $user_config_file 
	}
}


function RemoveProfiles {
	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nREMOVE BACKUP USER: $u`n---------------------------------------------------------------------------------------------------------"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.json"

		if(!(Test-Path $user_backup)) { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
		
		& "${env:SystemRoot}\System32\cmd.exe" /c "rmdir /s /q `"${user_backup}`""
		Remove-Item -Recurse -Force $user_backup -ErrorAction SilentlyContinue
		Remove-Item -Force $user_config_file -ErrorAction SilentlyContinue
		
		if (Test-Path -LiteralPath $user_backup) { Write-Warning "Folder $user_backup cant be removed" }			
		if (Test-Path -LiteralPath $user_config_file) { Write-Warning "File $user_config_file cant be removed" }
	}
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
    Write-Output "---------------------------------------------------------------------------------------------------------`nBACKUP USER: $u`n---------------------------------------------------------------------------------------------------------"
    $user_profile="${ENV:SystemDrive}\Users\${u}"
    $user_backup="${backups_path}\${u}"
    $user_config_file="${backups_path}\$u.json"

    if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
    if(Test-Path $user_backup) { Remove-Item -Recurse -Force $user_backup -ErrorAction SilentlyContinue }
    
    # Copy profile
	& "${env:SystemRoot}\System32\cmd.exe" /c "rmdir /s /q ${user_profile}\AppData\Local\Microsoft\Windows\SFAP\" *> $null		# Delete this folder first to avoid access denied in Windows 11
    robocopy $user_profile $user_backup /MIR /XJ /COPYALL /NFL /NDL /R:1 /W:1	
    #Remove-Item -Force -Path "${user_backup}\AppData\Local\Microsoft\Windows\UsrClass.dat"	-ErrorAction SilentlyContinue		# Avoid restore UsrClass.dat file to prevent Start button crash (will be deleted on each restore)
    
    # Save default user config file in backups path
    if(!(Test-Path $user_config_file)) { $default_config | ConvertTo-Json | Out-File $user_config_file }
	
	# Show profile size
	$bytes = [long](Get-ChildItem $user_backup -Recurse -File -Force | Measure-Object Length -Sum).Sum
	Write-Output ("PROFILE $u SIZE: " + $(if ($bytes -ge 1TB) { "{0:N2} TB" -f ($bytes / 1TB) } elseif ($bytes -ge 1GB) { "{0:N2} GB" -f ($bytes / 1GB) } elseif ($bytes -ge 1MB) { "{0:N2} MB" -f ($bytes / 1MB) } elseif ($bytes -ge 1KB) { "{0:N2} KB" -f ($bytes / 1KB) } else { "$bytes B" }))
  }
}



function BackupRegistries {
	# If no users param get all users from each .json file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.json) {$f.basename } }	
	
	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nBACKUP NTUSER.DAT: $u`n---------------------------------------------------------------------------------------------------------"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"

		# Check profile and backup profile exists
		if(!(Test-Path $user_profile)) { Write-Output "WARNING! Folder $user_profile not exists. Skipping user $u"; continue }
		if(!(Test-Path $user_backup)) { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }

		Write-Output "Saving: ${user_profile}\NTUSER.DAT -> ${user_backup}\NTUSER.DAT"
		# Backup previous ntuser.dat 
		$f=$(Get-Date -Format 'yyyyMMdd-HHmmss')
		Copy-Item -LiteralPath "${user_backup}\NTUSER.DAT" -Destination "${user_backup}\_NTUSER.DAT_backup_${f}" -Force
		Remove-Item -LiteralPath "${user_backup}\NTUSER.DAT" -Force

		# USER CONNECTED -> get ntuser.data from registry
		$sid = (Get-LocalUser -Name $u).SID.Value
		if (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid -and $_.Loaded }) {
			reg save "HKU\${sid}" "${user_backup}\NTUSER.DAT" /y
			if($LASTEXITCODE -ne 0) { 
				Copy-Item -LiteralPath "${user_backup}\_NTUSER.DAT_backup_${f}" -Destination "${user_backup}\NTUSER.DAT" 
				continue
			}
		# USER DICONNECTED -> copy ntuser.dat from profile
		} else {
			Copy-Item -LiteralPath "${user_profile}\NTUSER.DAT" -Destination "${user_backup}" -Force
			if(-not $?) { 
				Copy-Item -LiteralPath "${user_backup}\_NTUSER.DAT_backup_${f}" -Destination "${user_backup}\NTUSER.DAT"
				continue				
			}
		}
		Get-ChildItem -LiteralPath ${user_backup} -Filter 'ntuser.dat*' -File -Force | Where-Object Name -ne 'ntuser.dat' | Remove-Item -Force
	}	
}



function RestoreRegistries {
	# If no users param get all users from each .json file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.json) {$f.basename } }
	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nRESTORE NTUSER.DAT: $u`n---------------------------------------------------------------------------------------------------------"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"
		
		# Check backup folder
		if(!(Test-Path "${user_profile}\NTUSER.DAT")) { Write-Output "WARNING! File ${user_profile}\NTUSER.DAT not exists. Skipping user $u"; continue }
		if(!(Test-Path "${user_backup}\NTUSER.DAT")) { Write-Output "WARNING! File ${user_backup}\NTUSER.DAT not exists. Skipping user $u"; continue }
		
		Write-Output "Restoring: ${user_backup}\NTUSER.DAT -> ${user_profile}\NTUSER.DAT"
		# Check user connected
		$sid = (Get-LocalUser -Name $u).SID.Value
		if (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid -and $_.Loaded }) {
			Write-Output "WARNING! Profile $u in use. Skipping user $u"; continue
		}
		
		# Backup previous ntuser.dat 
		$f=$(Get-Date -Format 'yyyyMMdd-HHmmss')
		Copy-Item -LiteralPath "${user_profile}\NTUSER.DAT" -Destination "${user_profile}\_NTUSER.DAT_backup_${f}" -Force
		Remove-Item -LiteralPath "${user_profile}\NTUSER.DAT" -Force
		Copy-Item -LiteralPath "${user_backup}\NTUSER.DAT" -Destination "${user_profile}" -Force
		if(-not $?) { Copy-Item -LiteralPath "${user_profile}\_NTUSER.DAT_backup_${f}" -Destination "${user_profile}\NTUSER.DAT"; continue; }
		Get-ChildItem -LiteralPath ${user_profile} -Filter 'ntuser.dat*' -File -Force | Where-Object Name -ne 'ntuser.dat' | Remove-Item -Force
	}	
}



function RestoreProfiles {
	# If no users param get all users from each .json file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.json) {$f.basename } }
	
	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nRESTORE PROFILE: $u`n---------------------------------------------------------------------------------------------------------"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.json"
		
		# Check backup folder
		if(!(Test-Path $user_backup))  { Write-Output "WARNING! Folder $user_backup not exists. Skipping user $u"; continue }
		
		Write-Output "Removing user $u profile folder..."
		# Remove-Item -Recurse -Force $user_profile
		& "${env:SystemRoot}\System32\cmd.exe" /c "rmdir /s /q ${user_profile}"
		echo d | robocopy ${user_backup} ${user_profile} /MIR /XJ /COPYALL /NFL /NDL /R:1 /W:1
	}
}



function CleanProfiles {
	# If no users param get all users from each .json file in backups dir
	if(!$users) { $users=foreach($f in Get-ChildItem $backups_path -filter *.json) {$f.basename } }

	foreach($u in $users) {
		Write-Output "---------------------------------------------------------------------------------------------------------`nCLEAN PROFILE: $u"
		$user_profile="${ENV:SystemDrive}\Users\${u}"
		$user_backup="${backups_path}\${u}"
		$user_config_file="${backups_path}\$u.json"		
		
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
			$cm="none"
			if((New-TimeSpan -Start ([DateTime]$user_conf.lastSoftClean) -End (Get-Date)).Days -ge $user_conf.softCleanDays) { $cm="soft" }
			if((New-TimeSpan -Start ([DateTime]$user_conf.lastFullClean) -End (Get-Date)).Days -ge $user_conf.fullCleanDays) { $cm="full" }
		}
		
		# FULL CLEAN
		if($cm -eq "full") {
			Write-Output "FULL CLEANING: $user_profile"
			$removePaths=$user_conf.fullCleanRemovePaths+$user_conf.softCleanRemovePaths
			$restorePaths=$user_conf.fullCleanRestorePaths+$user_conf.softCleanRestorePaths		

			# Update lastFullClean and lastSoftClean date 
			$user_conf.lastFullClean=Get-Date -Format "yyyy-MM-dd"
			$user_conf.lastSoftClean=Get-Date -Format "yyyy-MM-dd"
			$user_conf | ConvertTo-Json | Out-File $user_config_file
		
		# SOFT CLEAN
		} elseif($cm -eq "soft") {
			Write-Output "SOFT CLEANING: $user_profile"
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
			if($rp -isnot [string] -or [string]::IsNullOrWhiteSpace($rp)) { continue }
			$fp=Join-Path $user_profile $rp
			if(Test-Path $fp -ErrorAction SilentlyContinue){
				Remove-Item -Recurse -Force $fp
				Write-Output " Removing: $fp -> $(if($?){Write-Output "[OK]"}else{Write-Output "[ERROR]"})"
			}
		}
		# RESTORE PATHS
		foreach($rp in $restorepaths) {
			if($rp -isnot [string] -or [string]::IsNullOrWhiteSpace($rp)) { continue }
			$rp=$rp.TrimEnd('*').TrimEnd('\')
			$fp_dest=Join-Path $user_profile $rp
			$fp_src=Join-Path $user_backup $rp
			
			if(Test-Path $fp_src -ErrorAction SilentlyContinue){
				if (Test-Path -LiteralPath $fp_src -PathType Leaf) {
					Copy-Item -LiteralPath $fp_src -Destination $fp_dest 
					Write-Output " Restoring: $fp_src -> $(if($?){Write-Output "[OK]"}else{Write-Output "[ERROR]"})"
				} else {
					Remove-Item -Recurse -Force $fp_dest -ErrorAction SilentlyContinue
					echo d | robocopy ${fp_src} ${fp_dest} /MIR /XJ /COPYALL /NFL /NDL /R:1 /W:1 *>$null
					Write-Output " Restoring: $fp_src -> $(if($LASTEXITCODE -lt 8){Write-Output "[OK]"}else{Write-Output "[ERROR]"})"
				}
			}
		}	
		
		Write-Output "---------------------------------------------------------------------------------------------------------"
	}
}

function main {
	if($BackupProfiles)      			{ BackupProfiles  	}
	elseif($BackupRegistries) 			{ BackupRegistries 	}
	elseif($RestoreProfiles) 			{ RestoreProfiles 	}
 	elseif($CleanProfiles)				{ CleanProfiles		}
	elseif($RemoveProfiles)				{ RemoveProfiles	}
	elseif($ResetConfig)				{ ResetConfig		}	
}

# EXEC no log
if(!$Log) { main }

# EXEC log
else {
    if((Get-ChildItem $log_path -ErrorAction SilentlyContinue | % {[int]($_.length / 1kb)}) -gt 8) { Remove-Item -Path $log_path }		# Delete log if size > 8kb
    &{ Write-Output "`n`n#########################################################################################################`nLABADMIN-PROFILE-CLEANER $((Get-Date).toString())`n#########################################################################################################"; main } 2>&1 | Out-File -FilePath $log_path -Append 
}
