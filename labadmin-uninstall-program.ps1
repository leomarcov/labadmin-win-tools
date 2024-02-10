#Requires -RunAsAdministrator
<#
.SYNOPSIS
	Try uninstall program using some methods

.PARAMETER programName
  Name of package to match (if multiple matches will be cancelled)
.PARAMETER List
  List all installed packages on system. Optional string can be used to filter matches
.PARAMETER argumentList
  Optional argument list to use for uninstall.exe (by default /SILENT is used)
  Typical arguments are: 
    * /s
    * /S
    * /S /v"/qn"
    * /SILENT
    * /VERYSILENT
    * /VERYSILENT /SUPPRESSMSGBOXES
    * Try uninstall.exe /? to get specific method

.NOTES
	File Name: labadmin-uninstall-program.ps1
	Author   : Leonardo Marco
#>

Param(
  [String]$programName,
  [String]$argumentList,
  [Switch]$List
)


# CONFIG VARIABLES
if(!$argumentList) { $argumentList="/SILENT") }

#LIST 
if($list) {
	Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $name }
 	exit
}

# CHECK PACKAGE INSTALLED AND GET $literalName
if(!$programName) { Write-Error "-programName param required"; exit 1 }
$literalName=Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $programName }
if(!$literalName) { Write-Error "Cant find installed program $programName"; exit 1 }
if($literalName -is [Array]) {  $literalName; Write-Error "Multiple matching for name: $programName"; exit 1 }
$literalName=$literalName.Name
if($programName -ne $literalName) { Write-Output "Literal program name found: $literalName" }

# TRY UNINSTALL: WmiObject
Write-Output "Trying uninstall using WmiObject..."
$app=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $literalName }
if($app) { 
  $app.Uninstall()
  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
}

# TRY UNINSTALL: Uninstall-Package
Write-Output "Trying uninstall using Uninstall-Package..."
$app=Get-Package $literalName
if($app) {
  Uninstall-Package -Name $literalName -Force
  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
}

# TRY REGEDIT uninstall.exe
Write-Output "Trying uninstall using Regedit uninstall path..."
$app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName }
if(!$app) { $app = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName } }
if($app) {
  $uninstallPath=$app.UninstallString.Trim("`"")
  if([System.IO.Path]::GetExtension($uninstallPath) -eq ".exe") {
	Write-Output "Executing uninstall: ${uninstallPath} ${arg}"
	Start-Process -FilePath $uninstallPath -ArgumentList $argumentList -Verb runas -Wait
	if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	Write-Outout "ERROR!: Cant found uninstall method for $literalName package
	Typical uninstall.exe argumentList parameters are:
	    * /s
	    * /S
	    * /S /v"/qn"
	    * /SILENT
	    * /VERYSILENT
	    * /VERYSILENT /SUPPRESSMSGBOXES
	    * Try $uninstallPath /? to get specific method"
	  }
}

# NO METHOD FOUND!
Write-Error "No uninstall method found!"
exit 1
