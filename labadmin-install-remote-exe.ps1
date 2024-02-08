#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [String]$fileName,                  # Filename of installer file
  [String]$MD5,                       # MD5 to check integrity install file (if match not download)
  [URI]$URL,                          # URL from download (only download if file not exists and MD5 match)
  [Switch]$forceDownload,             # Force download and override install file
  [String]$destinationPath,	          # Optional folder to download instead of labadmin base download  
  [Switch]$removeInstaller,           # Remove install file after installation
  [String]$argumentList               # Optional argument list to silent installation instead of default: "/S /v /qn"
)

#### CONFIG VARIABLES
$labadminDownloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"}
$defaultArguments='/S /v /qn'

if(!$argumentList) { $argumentList=$defaultArguments }
if(!$destinationPath) { $destinationPath=$labadminDownloadsPath}
$filePath="${destinationPath}\${fileName}"    

# DOWNLOAD: call labadmin-download-file.ps1
$PSBoundParameters.Remove("removeInstaller") | Out-Null; $PSBoundParameters.Remove("argumentList") | Out-Null
& "${PSScriptRoot}\labadmin-download-file.ps1" @$PSBoundParameters

# INSTALL
Write-Output "Installing in silent mode: $filePath"
Start-Process -FilePath $filePath -ArgumentList $argumentList -Verb runas -Wait
$lec=$LASTEXITCODE
Write-Output "Exit status: $? ($lec)"

# REMOVE
if($removeInstaller) { Remove-Item -Force $filePath }

exit $lec
