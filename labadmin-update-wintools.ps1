#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Install/update labadmin wintools from GitHub repository
    
.NOTES
    File Name: labadmin-config-antivirus.ps1
    Author   : Leonardo Marco
#>

$install_path=$ENV:ProgramFiles+"\labadmin\labadmin-win-tools\"
$url="https://github.com/leomarcov/labadmin-win-tools/archive/refs/heads/main.zip"

# Create folder
if((Test-Path -LiteralPath $install_path -PathType Container)) { 
  Write-Output "Removing folder ${install_path} ..."
  Remove-Item -LiteralPath ${install_path} -Force -Recurse 
}
Write-Output "Creating folder ${install_path} ..."
New-Item -ItemType Directory -Force -Path $install_path | Out-Null

# Download repository
Write-Output "Downloading files ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri ${url} -OutFile "${install_path}\main.zip" -ErrorAction Stop
Expand-Archive -LiteralPath "${install_path}\main.zip" -DestinationPath $install_path -Force -ErrorAction Stop
Move-Item -Path "${install_path}\labadmin-win-tools-main\*.ps1" -Destination $install_path -ErrorAction Stop
Remove-Item -LiteralPath "${install_path}\main.zip" -Force
Remove-Item -LiteralPath "${install_path}\labadmin-win-tools-main" -Force -Recurse

# Update PATH
$current_path = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
# Check if install_path is already in PATH
if(!($current_path.Split(';') | Where-Object { $_ -eq $install_path })){ 
  Write-Output 'Updating $PATH ...'
  $new_path = "$current_path;${install_path}"
  Write-Output "Adding $install_path to ENVIRONMENT PATH variable"
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $new_path
}
Write-Output "`n"

