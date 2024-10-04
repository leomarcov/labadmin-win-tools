#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Rotate user password according rule

.PARAMETER userName
	Username account to rotate
.PARAMETER show
	Show schedule job info rotation for userName account
.PARAMETER disable
	Disable schedule job rotation for userName account
.PARAMETER enable
	Enable schedule job rotation for userName account
.PARAMETER register
	Register schedule job rotation for userName account
.PARAMETER unregister
	Unregister schedule job rotation for userName account

.NOTES
    File Name: labadmin-rotatepass.ps1
    Author   : Leonardo Marco
#>

Param(
  [String]$userName,
  [Switch]$ShowHostsFile,
  [String]$DenyHosts,
  [Switch]$WipeHostsFile,
  [String]$RemoveHosts
)

$hosts_path = "$($Env:WinDir)\system32\Drivers\etc\hosts"


function ShowHostsFile {
  Get-Content $hosts_path
}

function DenyHosts {
  Add-Content -Encoding UTF8  $hosts_path ("127.0.0.1".PadRight(20, " ") + "$hostname".PadRight(40, " ") + "# labadmin-edit-hostsfile")
}

function WipeHostsFile {
"# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost" | Out-File -Encoding UTF8 -FilePath $hosts_path

}

function RemoveHosts {
  Get-Content $hosts_path | Where-Object { -not $_.Contains($hostname) } | Set-Content $hosts_path
}

function main {
	if($BackupProfiles)      	{ BackupProfiles  	}
	elseif($RestoreProfiles) 	{ RestoreProfiles 	}
 	elseif($ConfigProfiles)		{ ConfigProfiles	}
}

main
