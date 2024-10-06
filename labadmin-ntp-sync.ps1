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
  [String]$UpdateServers,
  [Switch]$ForceSync,
  [Switch]$Status
)


Start-Service w32time

# CONFIG NTP SERVER LIST
if($UpdateServers) {
    $defaultNTPServerList="time.windows.com time.nist.gov 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
    if(!$NTPServerList) { $ntpServersList=$defaultNTPServerList }
    w32tm /config /syncfromflags:manual /manualpeerlist:"$ntpServersList" /reliable:yes /update
}

# FORCE SYNC
if($ForceSync) {
    w32tm /resync /force
}

# STATUS
w32tm /query /status



