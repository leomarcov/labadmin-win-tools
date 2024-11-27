#Requires -RunAsAdministrator

<#
.SYNOPSIS
	URL File downloader manager
.DESCRIPTION
	Download file from URL to labadmin base downloads dir (or specific -destinationPath)
	If file exists not download but if MD5 is supplied check before download to determine if download is needed

.PARAMETER fileName
	Filename for downloaded file
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

.NOTES
	File Name : labadmin-download-file.ps1
	Author    : Leonardo Marco
#>

Param(
  [Parameter(Mandatory=$false, ParameterSetName='help')]
  [Parameter(Mandatory=$true, ParameterSetName='file')] 
  [String]$fileName,                 # Filename of downloaded file
  
  [Parameter(ParameterSetName='file')]
  [String]$MD5,                      # MD5 to check integrity downloaded file (if match not download)
  
  [Parameter(ParameterSetName='file')]
  [URI]$URL,                         # URL from download

  [Parameter(ParameterSetName='file')]
  [Switch]$forceDownload,            # Force download and override local file
  
  [Parameter(ParameterSetName='file')]
  [String]$destinationPath	     # Optional folder to download instead labadmin base download
)

# HELP
if($PSCmdlet.MyInvocation.BoundParameters.Count -eq 0) {
  Get-Help $PSCommandPath -Detailed
  exit 1
}

#### CONFIG VARIABLES
$labadminDownloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"
if(!$destinationPath) { $destinationPath=$labadminDownloadsPath}

# CREATE FOLDERS
if (!(Test-Path -LiteralPath $destinationPath -PathType Container)) { New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null}   
$filePath="${destinationPath}\${fileName}"    # File to download path

# CHECK IF NEED DOWNLOAD
if(!$forceDownload) {
	# If local file not found
	if(!(Test-Path -LiteralPath $filePath -PathType Leaf)) { 
		Write-Output "File $filePath not found. Force Download"
		$forceDownload=$true 
	# If local file found
	} else {
		if(!$MD5) {	
			Write-Output "WARNING!: Using local $filePath but not integrity checked!"
			exit 0 
		} elseif((Get-FileHash -LiteralPath $filePath -Algorithm MD5).Hash -eq $MD5) { 
			Write-Output "MD5 match!. Using local $filePath"
			exit 0 
		} else { 
			Write-Output "MD5 not matching! Forced download to $filePath"; $forceDownload=$true 
		}
	}
}
if(!$url -AND $forceDownload) { Write-Error "URL needed to download file"; exit 1 }

# DOWNLOAD?
if($forceDownload) {
	Write-Output "Downloading: $filePath"
	$ProgressPreference = 'SilentlyContinue'	# Disable progress bar increase speed
	Invoke-WebRequest -URI $url -outfile ${filePath} -ErrorAction Stop
	Write-Output "Download succsessful: $filePath"
	
	# Check integrity
	if($MD5) {
		if((Get-FileHash $filePath -Algorithm MD5).Hash -eq $MD5) { Write-Output "MD5 match!"; exit 0 }
		else { Write-Error "MD5 not match!"; exit 1 }
	}
	exit 0
}
