#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [String]$filename,                  # filename of installer file
  [URI]$URL,                          # URL from download (only download if file not exists and MD5 match)
  [Switch]$forceDownload,             # force download and override install file
  [Switch]$removeInstaller,           # remove install file after installation
  [String]$md5File,                   # MD5 to check integrity install file (if match not download)
)

#### CONFIG VARIABLES
$downloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"                                    # Labadmin Downloads base directory


# CREATE FOLDERS
if (-not (Test-Path -LiteralPath $downloadsPath -PathType Container)) {	New-Item -ItemType Directory -Path $downloadsPath }   
$installerPath="${downloadsPath}\${filename}"                                                  # File to download path

# CHECK PARAMS
if(!$url -AND ($forceDownload -OR $md5File)) { Write-Error "URL param is mandatory when forceDownload or md5File"; exit 1 }
if(!$forceDownload) {
	# If previuos downloader installer not found
	if(!(Test-Path -LiteralPath $installerPath -PathType Leaf)) {
		if(!url) {  Write-Error "ERROR: File $filename not found"; exit 1 }
		$forceDownload=$true	
	# If previuous downloaded installer found
	} else {
		if(!$md5File) { $forceDownload=$false }
		elseif((Get-FileHash $installerPath -Algorithm MD5).Hash -ne $md5file) { Write-Output "MD5 match!"; $forceDownload=$false }
		else { Write-Output "MD5 not matching! Forced download"; $forceDownload=$true }
	}
}

# DOWNLOAD
if($forceDownload) {
    Write-Output "Downloading: $installerPath"
    Invoke-WebRequest -URI $url -outfile ${installerPath} -ErrorAction Stop
    Write-Output "Download succsessful: $installerPath"
}

# INSTALL
Write-Output "Installing in silent mode: $installerPath"
Start-Process msiexec.exe -Wait -ArgumentList "/I '${$installerPAth}' /norestart /QN"
$lec=$LASTEXITCODE
Write-Output "Exit status: $? ($lec)"

# REMOVE
if($removeInstaller) { Remove-Item -Force $installerPath }

exit $lec
