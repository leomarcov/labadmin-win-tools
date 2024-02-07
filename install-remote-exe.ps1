#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  [URI]$URL,
  [parameter(Mandatory=$true)]
  [String]$filename,
  [Switch]$downloadOverride,
  [Switch]$removeDownload
)

#### CONFIG VARIABLES
$downloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"                                    # Labadmin Downloads base directory


# Create download folder if not exists
if (-not (Test-Path -LiteralPath $downloadsPath -PathType Container)) {	New-Item -ItemType Directory -Path $downloadsPath }   
$filePath="${downloadsPath}\${filename}"                                                  # File to download path

# Download
if($downloadOverride -OR !(Test-Path -LiteralPath $filePath -PathType Leaf)) {
    Write-Output "Downloading: $filePath"
    Invoke-WebRequest -URI $url -outfile ${filePath} -ErrorAction Stop
    Write-Output "Download succsessful: $filePath"
}


# Install
Write-Output "Installing in silent mode: $filePath"
Start-Process -FilePath $filePath -ArgumentList '/S','/v','/qn' -Verb runas -Wait
$lec=$LASTEXITCODE
Write-Output "Exit status: $? ($lec)"

# Remove download
if($removeDownload) { Remove-Item -Force $filePath }

exit $lec
