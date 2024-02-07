#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [String]$URL,
  [parameter(Mandatory=$true)]
  [String]$filename,
  [Switch]$removeDownload
)

#### CONFIG VARIABLES
$downloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"                                    # Labadmin Downloads base directory


if (-not (Test-Path $downloadsPath)) {	New-Item -ItemType Directory -Path $downloadsPath }   
$downloadPath="${downloadsPath}\${filename}"                                                  # File to download path

Invoke-WebRequest -URI $url -outfile "${downloadsPath}\$filename" -ErrorAction Stop
Start-Process -FilePath $downloadPath -ArgumentList '/S','/v','/qn' -Verb runas -Wait

if(removeDownload) { Remove-Item -Force $downloadPath }

