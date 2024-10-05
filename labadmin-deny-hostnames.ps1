#Requires -RunAsAdministrator

<#
.SYNOPSIS
  Manage hosts file to denay hostnames access

.PARAMETER ShowHostsFile
  Show hosts file content
.PARAMETER DenyHosts
  Add a list of hosts (by spaces, lines, tabs...) to denay them
.PARAMETER WipeHostsFile
  Wipe all labadmin lines inserted
.PARAMETER RemoveHosts
  Remove all lines in hosts file contaning string

.NOTES
    File Name: labadmin-edit-hostsfile.ps1
    Author   : Leonardo Marco
#>

Param(
  [Switch]$ShowHostsFile,
  [String]$DenyHosts,
  [Switch]$WipeHostsFile,
  [String]$RemoveHosts
)

#  CONFIG VARIABLES
$hosts_path = "$($Env:WinDir)\system32\Drivers\etc\hosts"
$hosts_comment= "# labadmin-edit-hostsfile"

# SHOWHOSTSFILE
function ShowHostsFile {
  Get-Content $hosts_path
}

# DENAYHOSTS
function DenyHosts {
  $DenyHosts = $DenyHosts.Split() | foreach { "127.0.0.1".PadRight(20, " ") + $_.PadRight(40, " ") + "# labadmin-edit-hostsfile" }
  Add-Content -Encoding UTF8  $hosts_path $DenyHosts
}

# WIPEHOSTSFILE
function WipeHostsFile {
  $RemoveHosts=$hosts_comment
  RemoveHosts
}

# REMOVEHOSTS
function RemoveHosts {
  (Get-Content $hosts_path | Where-Object { -not $_.Contains($RemoveHosts) }) | Out-File -Encoding UTF8 -FilePath $hosts_path
}


if($WipeHostsFile)	{ WipeHostsFile		}
if($DenyHosts) 		  { DenyHosts 		  }
if($RemoveHosts)		{ RemoveHosts		  }
if($ShowHostsFile)  { ShowHostsFile  	}


