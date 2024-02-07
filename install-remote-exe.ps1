#Requires -RunAsAdministrator
Param(
  [URI]$URL,
  [parameter(Mandatory=$true)]
  [String]$filename,
  [Switch]$downloadOverride,
  [Switch]$removeDownload,
  [String]$argumentList
)

#### CONFIG VARIABLES
$downloadsPath="${ENV:ALLUSERSPROFILE}\labadmin\downloads"                                    # Labadmin Downloads base directory
$defaultArguments='/S /v /qn'

if(!$argumentList) { $argumentList=$defaultArguments }

# Create download folder if not exists
if (-not (Test-Path -LiteralPath $downloadsPath -PathType Container)) {	New-Item -ItemType Directory -Path $downloadsPath }   
$filePath="${downloadsPath}\${filename}"                                                  # File to download path

# if no URL check if file exists
if(!url -AND !(Test-Path -LiteralPath $filePath -PathType Leaf)) {
    Write-Error "ERROR: File $filename not found"
    exit 1
}

# Download
if($downloadOverride -OR !(Test-Path -LiteralPath $filePath -PathType Leaf)) {
    Write-Output "Downloading: $filePath"
    Invoke-WebRequest -URI $url -outfile ${filePath} -ErrorAction Stop
    Write-Output "Download succsessful: $filePath"
}


# Install
Write-Output "Installing in silent mode: $filePath"
Start-Process -FilePath $filePath -ArgumentList $argumentList -Verb runas -Wait
$lec=$LASTEXITCODE
Write-Output "Exit status: $? ($lec)"

# Remove download
if($removeDownload) { Remove-Item -Force $filePath }

exit $lec
