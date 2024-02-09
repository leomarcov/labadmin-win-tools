#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable/disable Windows antivirus real time protection
.PARAMETER Enabled
    Enable antivirus real time protection
.PARAMETER Disabled
    Disable antivirus real time protection
.PARAMETER Status
    Show current status
.NOTES
    File Name: labadmin-config-antivirus.ps1
    Author   : Leonardo Marco
#>


Param(
  [Switch]$Enable,
  [Switch]$Disable
)

if($enable) {
  Set-MpPreference -DisableRealtimeMonitoring $false
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "WARNING! Realtime protection is DISABLED"; exit 1 	}
  else { Write-Output "Realtime protection is ENABLED"; exit 0 }

} elseif($disable) {
  Set-MpPreference -DisableRealtimeMonitoring $true
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Realtime protection is DISABLED"; exit 0	}
  else { Write-Error "Realtime protection is still ENABLED!"; exit 1 }

} else {
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Error "Current status: DISABLED"; exit 1	}
  else { Write-Output "Current status: ENABLED"; exit 0 }
}



