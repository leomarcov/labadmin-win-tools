#Requires -RunAsAdministrator

Start-Service w32time
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" /reliable:yes /update
w32tm /resync /force
w32tm /query /status
