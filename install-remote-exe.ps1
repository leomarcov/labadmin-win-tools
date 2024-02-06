#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  $URL,
  [parameter(Mandatory=$true)]
  $filename
)

$downloadPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"
if (-not (Test-Path $downloadPath)) {	New-Item -ItemType Directory -Path $downloadPath } 

Invoke-WebRequest -URI $url -outfile "c:\seb.exe"
Start-Process -FilePath "c:\seb.exe" -ArgumentList '/S','/v','/qn' -Verb runas -Wait
Remove-Item -Path "c:\seb.exe" -Force

