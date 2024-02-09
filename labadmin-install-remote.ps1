#Requires -RunAsAdministrator
<#
.SYNOPSIS
	Download installer program from URL file (EXE or MSI) and install it silently
.DESCRIPTION
	Download installer file from URL to labadmin base downloads dir (or specific -destinationPath) and install it
.PARAMETER fileName
	Filename for downloaded installer file
.PARAMETER MD5
	MD5 hash to check file integrity
	If file exists in destionation path check integrety before to determine if download is needed
	If file is downloaded checks integrity after download to determine is download is correct
.PARAMETER URL
	URL from download file
	If no supplied use local file in destionation path if exists. In this case is recomended supply MD5 param to check integrety
.PARAMETER forceDownload
	Force download file and overrides local file if exists
.PARAMETER destinationPath
	Optional destination folder to save download (by default labadmin base download is used C:\ProgramData\labadmin\downloads\)
.PARAMETER removeInstaller
  Remove installer file after install (by default is not removed)
.PARAMETER argumentList
  Optional argument list for EXE installer to silent installation
  By default parameters used are: /S /v"/qn"
  Other typical options are: /S, /SILENT, /VERYSILENT, /SUPPRESSMSGBOXES

.NOTES
	File Name      : labadmin-download-file.ps1
	Author         : Leonardo Marco
#>

Param(
  [parameter(Mandatory=$true)]
  [String]$fileName,
  [String]$MD5,
  [URI]$URL,
  [Switch]$forceDownload,
  [String]$destinationPath,
  [Switch]$removeInstaller,
  [String]$argumentList
)


#### CONFIG VARIABLES
$labadminDownloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"
$defaultArguments='/S /v`"/qn`"'

if(!$argumentList) { $argumentList=$defaultArguments }
if(!$destinationPath) { $destinationPath=$labadminDownloadsPath}
$filePath="${destinationPath}\${fileName}"    

# CHECK EXTESION
if([System.IO.Path]::GetExtension($filePath) -eq ".exe") { $fileTypeEXE = $true }
elseif([System.IO.Path]::GetExtension($filePath) -eq ".msi") { $fileTypeMSI= $true }
else { Write-Error "File extension not supoerted (only .exe and .msi files)"; exit 1 }

# DOWNLOAD: call labadmin-download-file.ps1
$PSBoundParameters.Remove("removeInstaller") | Out-Null; $PSBoundParameters.Remove("argumentList") | Out-Null
& "${PSScriptRoot}\labadmin-download-file.ps1" @PSBoundParameters -ErrorAction Stop

# INSTALL
if($fileTypeEXE) { 
  Write-Output "Installing EXE in silent mode: $filePath $argumentList"
  Start-Process -FilePath $filePath -ArgumentList $argumentList -Verb runas -Wait
  Write-Output "Please, check manuallay if package is installed"
  Write-Output "`nIf fail, typical uninstall argumentList alternatives are:"
  Write-Output "  * /S /v`"/qn`""
  Write-Output "  * /S"
  Write-Output "  * /SILENT"
  Write-Output "  * /VERYSILENT"
  Write-Output "  * /SILENT /SUPPRESSMSGBOXES"
} elseif($fileTypeMSI) { 
  Write-Output "Installing MSI in silent mode: $filePath"
  Start-Process msiexec.exe -Wait -ArgumentList "/I `"${filePath}`" /norestart /QN"
}
$lec=$LASTEXITCODE

# REMOVE
if($removeInstaller) { 
    Write-Output "Removing install file: $filePath"
    Remove-Item -Force $filePath 
}
exit $lec
