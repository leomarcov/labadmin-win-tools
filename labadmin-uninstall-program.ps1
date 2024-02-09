#Requires -RunAsAdministrator
Param(
  [String]$literalName,                  # Exact name of program to uninstall
  [String]$argumentList,                 # Optional arguments for uninstall.exe method
  [Switch]$List
)

# CONFIG VARIABLES
$argumentsMethods=@("/S", "/S /v`"/qn`"", "/SILENT", "/VERYSILENT")      # Unisntall.exe arguments to try
if($argumentList) { $argumentsMethods=@($argumentList) }
$name=$literalName

#LIST 
if($list) {Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $name }; exit }

# CHECK PACKAGE INSTALLED
if(!$name) { Write-Error "-literalName param required"; exit 1 }
if(!(Get-Package $name -ErrorAction SilentlyContinue)) { Write-Error "Cant find installed package $name"; exit 1 }

# TRY UNINSTALL: WmiObject
Write-Output "Trying uninstall using WmiObject..."
$app=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $name }
if($app) { 
  $app.Uninstall()
  if(!(Get-Package $name -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
}

# TRY UNINSTALL: Uninstall-Package
Write-Output "Trying uninstall using Uninstall-Package..."
$app=Get-Package $name
if($app) {
  Uninstall-Package -Name $name -Force
  if(!(Get-Package $name -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
}

# TRY REGEDIT uninstall.exe
Write-Output "Trying uninstall using Regedit uninstall path..."
$app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $name }
if(!$app) { $app = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $name } }
if($app) {
  $uninstallPath=$app.UninstallString.Trim("`"")
  if([System.IO.Path]::GetExtension($uninstallPath) -eq ".exe") {
    foreach($arg in $argumentsMethods) {
      Write-Output "Executing uninstall: ${uninstallPath} ${arg}"
      Start-Process -FilePath $uninstallPath -ArgumentList $arg -Verb runas -Wait
      if(!(Get-Package $name -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
    }
  }
}

# NO METHOD FOUND!
Write-Error "Cant found uninstall method for $name package"
exit 1
