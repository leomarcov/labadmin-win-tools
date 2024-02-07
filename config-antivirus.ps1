#Requires -RunAsAdministrator

Param(
  [Switch]$Enable,
  [Switch]$Disable
)

if($enable) {
  Set-MpPreference -DisableRealtimeMonitoring $false
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "WARNING! Realtime monitoring is DISABLED"; exit 1 	}
  else { Write-Output "Realtime monitoring is ENABLED"; exit 0 }

} elseif($disable) {
  Set-MpPreference -DisableRealtimeMonitoring $true
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Realtime monitoring is DISABLED"; exit 0	}
  else { Write-Output "WARMIMG! Realtime monitoring is ENABLED"; exit 1 }

} else {
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Realtime monitoring is DISABLED"; exit 1	}
  else { Write-Output "Realtime monitoring is ENABLED"; exit 0 }
}



