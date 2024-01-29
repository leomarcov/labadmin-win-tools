#Requires -RunAsAdministrator

$conf = Get-Content ${PSScriptRoot}/conf | ConvertFrom-StringData
Restore-Computer-RestorePoint $conf.main_rp
