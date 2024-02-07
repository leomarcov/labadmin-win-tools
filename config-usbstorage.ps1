#Requires -RunAsAdministrator

Param(
  [Switch]$Enable,
  [Switch]$Disable
)

if($disable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4

} elseif($enable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3

} else {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Current status: Disabled"; exit 1 } 
  else { Write-Output "Current status: Enabled"; exit 0 }
}
