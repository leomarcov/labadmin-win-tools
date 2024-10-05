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
  [Switch]$Enable,
  [Switch]$Disable,
  [Switch]$Status
)

# DISABLE
if($disable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4

# ENABLE
} elseif($enable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3

# STATUS
} elseif($status) {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Current status: DISABLED"; exit 1 } 
  else { Write-Output "Current status: ENABLED"; exit 0 }

# HELP
} else {
  Get-Help $PSCommandPath -Detailed
  exit 1
}
