#Requires -RunAsAdministrator
<#
.SYNOPSIS
	Try uninstall program using some methods

.PARAMETER literalName
	Exact name of program to uninstall
.PARAMETER List
  List all installed packages on system. Optional string can be used to filter matches
.PARAMETER argumentList
  Optional argument list to use for uninstall.exe method
  If no argumentList is give uninstall try these arguments:
    * /S
    * /S /v"/qn"
    * /SILENT
    * /VERYSILENT
    * /VERYSILENT /SUPPRESSMSGBOXES

.NOTES
	File Name: labadmin-uninstall-program.ps1
	Author   : Leonardo Marco
#>

Param(
  [String]$literalName,
  [String]$argumentList,
  [Switch]$List
)


# CONFIG VARIABLES
$argumentsMethods=@("/S", "/S /v`"/qn`"", "/SILENT", "/VERYSILENT", "/VERYSILENT /SUPPRESSMSGBOXES")      # Unisntall.exe arguments to try
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
Write-Outout "ERROR!: Cant found uninstall method for $name package
Typical uninstall.exe argumentList parameters are
  * /S /v`"/qn`""
  * /S"
  * /SILENT"
  * /VERYSILENT"
  * /SILENT /SUPPRESSMSGBOXES"
exit 1
