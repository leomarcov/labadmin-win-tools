#Requires -RunAsAdministrator

Param(
  [Switch]$Enable,
  [Switch]$Disable
)

if($enable) {
  Set-MpPreference -DisableRealtimeMonitoring $false
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Warning! Realtime monitoring is DISABLED"; exit 1 	}
  else { Write-Output "Realtime monitoring is ENABLED"; exit 0 }

} elseif($disable) {
  Set-MpPreference -DisableRealtimeMonitoring $false
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Warning! Realtime monitoring is DISABLED"; exit 1 	}
  else { Write-Output "Realtime monitoring is ENABLED"; exit 0 }
} else {
  if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Output "Realtime monitoring is DISABLED"; exit 1 	}
  else { Write-Output "Realtime monitoring is ENABLED"; exit 0 }
}



