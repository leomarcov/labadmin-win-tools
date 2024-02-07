#Requires -RunAsAdministrator

Write-Host -NoNewline "Disabling antivirus"
Set-MpPreference -DisableRealtimeMonitoring $true
if((Get-MpPreference).DisableRealtimeMonitoring) { Write-Host -ForegroundColor green "`t`t`t[OK]"; exit 0} 
else { Write-Host -ForegroundColor red "`t`t`t[FAIL]"; exit 1}	
