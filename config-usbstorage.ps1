#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables/disables USB Storages 
.NOTES
    File Name      : config-usbstorage.ps1
    Author         : Leonardo Marco
.EXAMPLE
    config-usbstorage.ps1 -Enable
.EXAMPLE
    config-usbstorage.ps1 -Disable
.EXAMPLE
    config-usbstorage.ps1      # Show current status
#>

Param(
  [Switch]$Enable,
  [Switch]$Disable
)

# DISABLE
if($disable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4

# ENABLE 
} elseif($enable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3

# SHOW CURRENT STATUS
} else {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Disabled" } 
  else { Write-Output "Enabled" }
}
