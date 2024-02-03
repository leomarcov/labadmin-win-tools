#Requires -RunAsAdministrator

$install_path=$ENV:ProgramFiles+"\labadmin\labadmin-freezer\"

# Create folder and close permissions to admin
if(!(Test-Path $install_path)) {
  New-Item -ItemType Directory -Force -Path $install_path | Out-Null   
  $acl = Get-Acl $install_path
  $acl.SetAccessRuleProtection($true,$false)
  $adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
  $acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
  $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name,"FullControl","Allow")))
  Set-Acl -Path $backups_path -AclObject $acl
}



# Download files
$url="https://raw.githubusercontent.com/leomarcov/labadmin-freezer/main/"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url_files="config-usbstorage.ps1 manage-restorepoints.ps1 profiles-cleaner.ps1"
foreach($f in $url_files.split(" ")) { Invoke-WebRequest -Uri ("${url}/${f}") -OutFile ($install_path+"\$f") }

