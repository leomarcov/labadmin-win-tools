#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [String]$fileNname,                  # Filename of installer file
  [String]$md5File,                   # MD5 to check integrity install file (if match not download)
  [URI]$URL,                          # URL from download (only download if file not exists and MD5 match)
  [Switch]$forceDownload,             # Force download and override install file
  [Switch]$removeInstaller,           # Remove install file after installation
  [String]$argumentList               # Optional argument list to silent installation instead of default: "/S /v /qn"
)

#### CONFIG VARIABLES
$defaultArguments='/S /v /qn'
if(!$argumentList) { $argumentList=$defaultArguments }
$installerPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads\${fileName}"

# DOWNLOAD
${PSScriptRoot}\download-file.ps1 -file

# INSTALL
Write-Output "Installing in silent mode: $installerPath"
Start-Process -FilePath $installerPath -ArgumentList $argumentList -Verb runas -Wait
$lec=$LASTEXITCODE
Write-Output "Exit status: $? ($lec)"

# REMOVE
if($removeInstaller) { Remove-Item -Force $installerPath }

exit $lec
