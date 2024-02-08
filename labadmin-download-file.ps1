#Requires -RunAsAdministrator

<#
.SYNOPSIS
	URL File downloader
.DESCRIPTION
	Download file from URL to labadmin base downloads dir (or specific destinationPath)
	If file exists not download and if MD5 is supplied check before download to determine if download is needed
.PARAMETER fileName
	Filename for downloaded file
.PARAMETER md5File
	MD5 hash to check file integrity. 
	If file exists in destionation path check integrety before to determine if download or not
	If file is downloaded checks integrity after download to determine is download is correct
.PARAMETER URL
	URL from download file. 
	If no supplied use local file in destionation path if exists. In this case is recomended use MD5 to check integrety.
.PARAMETER forceDownload
	Force download file and overrides local file if exists
.PARAMETER destinationPath
	Optional destination folder to save download. If no supplied use labadmin base download

.NOTES
	File Name      : labadmin-download-file.ps1
	Author         : Leonardo Marco
#>


Param(
  [parameter(Mandatory=$true)]
  [String]$fileName,                 # Filename of downloaded file
  [String]$md5File,                  # MD5 to check integrity downloaded file (if match not download)
  [URI]$URL,                         # URL from download (only download if file not exists and MD5 match)  
  [Switch]$forceDownload,            # Force download and override local file
  [String]$destinationPath	     # Optional folder to download instead of labadmin base download
)

#### CONFIG VARIABLES
if(!$destinationPath) { $destinationPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"}

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
		if(!$md5File) {	
			Write-Output "WARNING!: Using local $filePath but not integrity checked!"
			exit 0 
		}elseif((Get-FileHash $filePath -Algorithm MD5).Hash -eq $md5File) { 
			Write-Output " MD5 match!. Using local $filePath"
			exit 0 
		}else { 
			Write-Output "MD5 not matching! Forced download to $filePath"; $forceDownload=$true 
		}
	}
}
if(!$url -AND $forceDownload) { Write-Error "URL needed to download file"; exit 1 }


# DOWNLOAD?
if($forceDownload) {
    Write-Output "Downloading: $filePath"
    Invoke-WebRequest -URI $url -outfile ${filePath} -ErrorAction Stop
    Write-Output "Download succsessful: $filePath"
	
	# Check integrity
	if($md5File) {
		if((Get-FileHash $filePath -Algorithm MD5).Hash -eq $md5File) { Write-Output "MD5 match!"; exit 0 }
		else { Write-Error "MD5 not match!"; exit 1 }
	}
	exit 0
}
