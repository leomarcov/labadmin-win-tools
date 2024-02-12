#Requires -RunAsAdministrator

<#
.SYNOPSIS
	Download installer program from URL file (EXE or MSI) and install it silently noGUI

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
.PARAMETER installArgs
  Optional argument list for EXE installer to silent noGUI installation
  By default parameters used are: /S /v"/qn"
  Other typical  parameters are:
     * /s
     * /S
     * /SILENT
     * /VERYSILENT
     * /VERYSILENT /SUPPRESSMSGBOXES
     * /quiet
     * Try exec: installer /? to get specific method
  
.NOTES
	File Name: labadmin-install-remote.ps1
	Author   : Leonardo Marco
#>

Param(
  [parameter(Mandatory=$true)]
  [String]$fileName,
  [String]$MD5,
  [URI]$URL,
  [Switch]$forceDownload,
  [String]$destinationPath,
  [Switch]$removeInstaller,
  [String]$installArgs
)


#### CONFIG VARIABLES
$labadminDownloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"
$defaultInstallArgs='/S /v`"/qn`"'

if(!$installArgs) { $installArgs=$defaultInstallArgs }
if(!$destinationPath) { $destinationPath=$labadminDownloadsPath }
$filePath="${destinationPath}\${fileName}"    

# CHECK EXTESION
if([System.IO.Path]::GetExtension($filePath) -eq ".exe") { $fileTypeEXE = $true }
elseif([System.IO.Path]::GetExtension($filePath) -eq ".msi") { $fileTypeMSI= $true }
else { Write-Error "File extension not supoerted (only .exe and .msi files)"; exit 1 }

# DOWNLOAD: call labadmin-download-file.ps1
$PSBoundParameters.Remove("removeInstaller") | Out-Null; $PSBoundParameters.Remove("installArgs") | Out-Null
& "${PSScriptRoot}\labadmin-download-file.ps1" @PSBoundParameters -ErrorAction Stop

# INSTALL
if($fileTypeEXE) { 
  Write-Output "Installing EXE in silent mode: $filePath  $installArgs"
  Start-Process -FilePath $filePath -ArgumentList $installArgs -Verb runas -Wait; $lec=$LASTEXITCODE
  Write-Output "DONE! Please, check manuallay if package is installed
If fail, typical installArgs for silent noGUI are:
   * /s
   * /S
   * /S /v`"/qn`"
   * /SILENT
   * /VERYSILENT
   * /VERYSILENT /SUPPRESSMSGBOXES
   * /quiet
   * Try & `"$filePath`" /? to get specific method"
} elseif($fileTypeMSI) { 
  Write-Output "Installing MSI in silent mode: $filePath"
  Start-Process msiexec.exe -Wait -ArgumentList "/I `"${filePath}`" /norestart /QN"; $lec=$LASTEXITCODE
}


# REMOVE
if($removeInstaller) { 
    Write-Output "Removing install file: $filePath"
    Remove-Item -Force $filePath 
}
exit $lec
