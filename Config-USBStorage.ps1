Param(
  [Switch]$Enable,
  [Switch]$Disable
)

# DISABLE
if($disable) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "start" -Value 4
# ENABLE
} elseif($enable) 
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "start" -Value 3
# SHOW CURRENT STATE
} else {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "start") -eq 4) { Write-Output "Disabled" } 
  else { Write-Output "Enabled" }
}

