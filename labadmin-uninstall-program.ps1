#Requires -RunAsAdministrator
Param(
  [String]$literalName,                  # Name of program
  [Switch]$List
)

$name=$literalName

if($list) { Get-Package; exit }
if(!(Get-Package $name)) { Write-Error "Cant find installed package $name"; exit 1 }

# TRY UNINSTALL: WmiObject
$app=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $name }
if($app) { $app.Uninstall(); if($?) { exit 0 } }

# TRY UNINSTALL: Uninstall-Packate
$app=Get-Package $name
if($app) {
  Uninstall-Package -Name $name -Force
  if(!(Get-Package $name)) { exit 0 }
}

# TRY REGEDIT uninstall
$app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $name }
if($app) {
  $uninstallPath=$app.UninstallString
}
