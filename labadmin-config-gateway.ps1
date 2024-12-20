#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Set gateway address (even if current addres has been get using dhcp)

.PARAMETER setGateway
    Address to set as gateway (remove old gateway)
.PARAMETER resetGateway
    Address to remove as gateway (and try renew DHCP addresses)

.NOTES
    File Name: labadmin-config-gateway.ps1
    Author   : Leonardo Marco
#>

Param(
  [Parameter(Mandatory=$true, ParameterSetName='set')] 
  [ipaddress]$setGateway,
  
  [Parameter(Mandatory=$true, ParameterSetName='reset')] 
  [ipaddress]$resetGateway
)


# SETWATEGAY
if($setGateway) {
    # Get current gw
    $gwCurrent=(Find-NetRoute -RemoteIPAddress 8.8.8.8)[1].NextHop

    # Set new gw
    $wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
    $wmi = $wmi | Where-Object { $_.DefaultIPGateway -eq $gwCurrent }
    $wmi.SetGateways($setGateway, 1) | Out-null

    # Show new config
    ipconfig
    
    # EXIT CODE
    if($setGateway -eq (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop) { 
        Remove-NetRoute -NextHop $gwCurrent -Confirm:$false -ErrorAction SilentlyContinue | Out-Null    # Remove old gw
        exit 0 
    } else { 
        Write-Output "WANING! Gateway address not chnaged!"; exit 1 
    }

# RESETGATEWAY
} elseif($resetGateWay) {
	Remove-NetRoute -NextHop $resetGateway -Confirm:$false
	ipconfig /renew 
} 






