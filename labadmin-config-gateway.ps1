#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Set gateway address (even if current addres has been get using dhcp)

.PARAMETER address
    Gateway address 
.PARAMETER setGateway
    Set gateway address and remove old gateway
.PARAMETER resetGateway
    Remove gateway and try renew DHCP addresses

.NOTES
    File Name: labadmin-config-gateway.ps1
    Author   : Leonardo Marco
#>

Param(
  [Parameter(Mandatory=$false, ParameterSetName='help')]
  [Parameter(Mandatory=$true, ParameterSetName='address')] 
  [ipaddress]$address,

  [Parameter(ParameterSetName='address')]
  [Switch]$setGateway,                      # Set gateway
  
  [Parameter(ParameterSetName='address')]
  [Switch]$resetGateway                     # Reset gateway
)


# SETWATEGAY
if($setGateway) {
    # Get current gw
    $gwCurrent=(Get-NetIPConfiguration).IPv4DefaultGateway.NextHop

    # Set new gw
    $wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
    $wmi.SetGateways($address, 1) | Out-null

    # Show new config
    Get-NetIPConfiguration

    # EXIT CODE
    if($address -eq (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop) { 
        Remove-NetRoute -NextHop $gwCurrent -Confirm:$false -ErrorAction SilentlyContinue | Out-Null    # Remove old gw
        exit 0 
    } else { 
        Write-Output "WANING! Gateway address not chnaged!"; exit 1 
    }

# RESETGATEWAY
} elseif($resetGateWay) {
	Remove-NetRoute -NextHop $address -Confirm:$false
	ipconfig /renew > null

# HELP
} else {
  Get-Help $PSCommandPath -Detailed
  exit 1
}






