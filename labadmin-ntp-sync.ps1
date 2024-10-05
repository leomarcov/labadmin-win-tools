#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Set list of NTP servers and force sync
.PARAMETER ntpServersList
    List of NTP servers (space separated)
    
.NOTES
    File Name: labadmin-ntp-sync.ps1
    Author   : Leonardo Marco
#>

Param(
  [String]$ntpServersList
)

# CONFIG VARIABLES
$defaultNTPServerList="time.windows.com time.nist.gov 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
if(!$ntpServersList) { $ntpServersList=$defaultNTPServerList }

Start-Service w32time
w32tm /config /syncfromflags:manual /manualpeerlist:"$ntpServersList" /reliable:yes /update
w32tm /resync /force
# w32tm /query /status
