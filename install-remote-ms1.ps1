#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [String]$URL,
  [parameter(Mandatory=$true)]
  [String]$filename,
  [Switch]$removeDownload
)

$downloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"                                    # Labadmin Downloads base directory
if (-not (Test-Path $downloadsPath)) {	New-Item -ItemType Directory -Path $downloadsPath }   
$downloadPath="${downloadsPath}\${filename}"                                                  # File to download path

Invoke-WebRequest -URI $url -outfile "${downloadsPath}\$filename" -ErrorAction Stop
Start-Process msiexec.exe -Wait -ArgumentList "/I '${$downloadPath}' /norestart /QN"

if(removeDownload) { Remove-Item -Force $downloadPath }
