#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Force NTP sync 
    
.NOTES
    File Name: labadmin-ntp-sync.ps1
    Author   : Leonardo Marco
#>


Start-Service w32time
Write-Output "`n#### NTP SYNC ######################################################################"
w32tm /resync /force

Write-Output "`n#### NTP STATUS ####################################################################"
w32tm /query /status






