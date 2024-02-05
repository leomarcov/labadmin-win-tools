#Requires -RunAsAdministrator
Param(
  [Switch]$EnableUSBStorages,
  [Switch]$DisableUSBStorages,
  [Switch]$StatusUSBStorages,
)

# DISABLE
if($EnableUSBStorages) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4

# ENABLE 
} elseif($DisableUSBSTorages) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3

# SHOW CURRENT STATUS
} elseif($StatusUSBStorages) {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Disabled" } 
  else { Write-Output "Enabled" }
}
