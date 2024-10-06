#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Force NTP sync and update NTP server list

.PARAMETER ntpServersList
    List of NTP servers (space separated)
    
.NOTES
    File Name: labadmin-ntp-sync.ps1
    Author   : Leonardo Marco
#>

Param(
  [Switch]$updateServers,
  [String]$serverList,
  [Switch]$forceSync,
  [Switch]$status
)

# CONFIG VARIABLES
$defaultNTPServerList="time.windows.com time.nist.gov 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"


Start-Service w32time

# CONFIG NTP SERVER LIST
if($updateServers) {
    if(!$serverList) { $serverList=$defaultNTPServerList }
    w32tm /config /syncfromflags:manual /manualpeerlist:"$serverList" /reliable:yes /update
}

# FORCE SYNC
if($forceSync) {
    w32tm /resync /force
}

# STATUS
w32tm /query /status



