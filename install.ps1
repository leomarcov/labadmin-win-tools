#Requires -RunAsAdministrator

$install_path=$ENV:ProgramFiles+"\labadmin\labadmin-win-tools\"
$url="https://github.com/leomarcov/labadmin-win-tools/archive/refs/heads/main.zip"

# Create folder
New-Item -ItemType Directory -Force -Path $install_path | Out-Null

# Download repository
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri ${url} -OutFile "${install_path}\main.zip" -ErrorAction Stop
Expand-Archive -LiteralPath "${install_path}\main.zip" -DestinationPath $install_path -Force -ErrorAction Stop
Move-Item -Path "${install_path}\labadmin-win-tools-main\*.ps1" -Destination $install_path -ErrorAction Stop
Remove-Item -LiteralPath "${install_path}\labadmin-win-tools-main" -Force -Recurse

