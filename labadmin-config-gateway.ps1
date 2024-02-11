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

# GET CURRENT GW
$gwCurrent=(Get-NetIPConfiguration).IPv4DefaultGateway.NextHop

# SET NEW GW
$wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
$wmi.SetGateways($gwAddress, 1) | Out-null

# SHOW NEW CONFIG
Get-NetIPConfiguration

# EXIT CODE
if($gwAddress -eq (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop) { 
    Remove-NetRoute -NextHop $gwCurrent -Confirm:$false | Out-Null    # Remove old gw
    exit 0 
} else { 
    Write-Output "WANING! Gateway address not chnaged!"; exit 1 
}
