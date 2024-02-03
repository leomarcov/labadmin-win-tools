#Requires -RunAsAdministrator

$install_path=$ENV:ProgramFiles+"\labadmin\labadmin-freezer\"

# Create folder
New-Item -ItemType Directory -Force -Path $install_path | Out-Null

# Download files
$url="https://raw.githubusercontent.com/leomarcov/labadmin-freezer/main/"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url_files="config-usbstorage.ps1 manage-restorepoints.ps1 profiles-cleaner.ps1 install.ps1"
foreach($f in $url_files.split(" ")) { Invoke-WebRequest -Uri ("${url}/${f}") -OutFile ($install_path+"\$f") }
Rename-Item -Path $install_path -NewName update.ps1

