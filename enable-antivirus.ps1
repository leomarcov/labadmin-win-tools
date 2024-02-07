#Requires -RunAsAdministrator

Write-Host -NoNewline  "Enabling antivirus"
Set-MpPreference -DisableRealtimeMonitoring $false
if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Host -ForegroundColor red "`t`t`t[FAIL]"; exit 1	}
else { Write-Host -ForegroundColor green "`t`t`t[OK]"; exit 0 }
}
