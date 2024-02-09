#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Set gateway address (even if current addres has been get using dhcp)

.PARAMETER gwAddress
    Gateway address 
.NOTES
    File Name: labadmin-config-gateway.ps1
    Author   : Leonardo Marco
#>
Param(
  [Parameter(Mandatory)]
  [ipaddress]$gwAddress
)


$wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
$wmi.SetGateways($gwAddress, 1) | Out-null

Get-NetIPConfiguration

if($gwAddress -eq (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop) { exit 0 } 
else { Write-Output "WANING! Gateway address not chnaged!"; exit 1 }
