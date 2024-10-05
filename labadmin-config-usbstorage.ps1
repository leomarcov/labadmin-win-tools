#Requires -RunAsAdministrator

<#
.SYNOPSIS
  Enable/disable USB for storage devices connection
  
.PARAMETER Enable
    Enable USB storage devices
.PARAMETER Disable
    Disable USB storage devices
.PARAMETER Status
    Show current status
    
.NOTES
    File Name: labadmin-config-usbstorage.ps1
    Author   : Leonardo Marco
#>

Param(
  [Parameter(Mandatory=$true, ParameterSetName='enable')] 
  [Switch]$Enable,
  [Parameter(Mandatory=$true, ParameterSetName='disable')] 
  [Switch]$Disable,
  [Parameter(Mandatory=$true, ParameterSetName='status')] 
  [Switch]$Status
)

# DISABLE
function disable {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4
}

# ENABLE
function enable {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3
}

# STATUS
function status {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Current status: DISABLED"; exit 1 } 
  else { Write-Output "Current status: ENABLED"; exit 0 }
}


if($disable)      { disable; status } 
elseif($enable)   { enable; status  }
else              { status }

