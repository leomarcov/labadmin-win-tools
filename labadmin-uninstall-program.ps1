#Requires -RunAsAdministrator
<#
.SYNOPSIS
	Try silent noGUI uninstall program using some methods

.PARAMETER programName
  Name of package to match (if multiple matches will be cancelled)
.PARAMETER List
  No uninstall, only list all installed packages on system. Optional name can be used to filter matches
.PARAMETER useMethodWmiObject
  Try WmiObject method to uninstall
  If no any method is specified methods used are: wmiobject, uninstall-package, winget, register
.PARAMETER useMethodUninstallPackage
  Try Uninstall-Package method to uninstall
  If no any method is specified methods used are: wmiobject, uninstall-package, winget, register
.PARAMETER useMethodWinget
  Try winget method to uninstall
  If no any method is specified methods used are: wmiobject, uninstall-package, winget, register
.PARAMETER useMethodUninstallRegister
  Try uninstall string from regedit method to uninstall
  If no any method is specified methods used are: wmiobject, uninstall-package, winget, register
.PARAMETER argumentList
  Optional argument list to use for uninstall.exe (by default /S is used)
  Typical arguments for silent and no GUI are:
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
  [parameter(Position=1, Mandatory=$false, ParameterSetName="list")]
  [parameter(Mandatory=$true, ParameterSetName="uninstall")]
  [String]$programName,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]
  [Switch]$useMethodWmiObject,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]
  [Switch]$useMethodUninstallPackage,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]
  [Switch]$useMethodWinget,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]  
  [Switch]$useMethodUninstallRegister,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]

  [String]$argumentList,
  [parameter(Position=0, Mandatory=$true, ParameterSetName="list")]
  [Switch]$list
)


# CONFIG VARIABLES
if(!$argumentList) { $argumentList="/S" }

#LIST 
if($list) {
	Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $programName }
 	exit
}

# CHECK PACKAGE INSTALLED AND GET $literalName
if(!$programName) { Write-Error "-programName param required"; exit 1 }
$literalName=Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $programName }
if(!$literalName) { Write-Error "Cant find installed program $programName"; exit 1 }
if($literalName -is [Array]) {  $literalName; Write-Error "Multiple matching for name: $programName"; exit 1 }
$literalName=$literalName.Name
if($programName -ne $literalName) { Write-Output "Literal program name found: $literalName" }

# CHECK METHODS TO USE
if(!$useMethodWmiObject -AND !$useMethodUninstallPackage -AND !$useMethodWinget -AND !$useMethodUninstallRegister) {
    $useMethodWmiObject=$true; $useMethodUninstallPackage=$true; $useMethodWinget=$true; $useMethodUninstallRegister=$true
}

# TRY UNINSTALL: WmiObject
if($useMethodWmiObject) {
	Write-Output "Trying uninstall using WmiObject..."
	$app=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $literalName }
	if($app) { 
	  $app.Uninstall()
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY UNINSTALL: Uninstall-Package
if($useMethodUninstallPackage) {
	Write-Output "Trying uninstall using Uninstall-Package..."
	$app=Get-Package $literalName
	if($app) {
	  Uninstall-Package -Name $literalName -Force
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY UNINSTALL: winget
if($useMethodWinget) {
	if(Get-Command winget -ErrorAction SilentlyContinue) {
	  winget uninstall --exact --force --silent --disable-interactivity --accept-source-agreements $literalName
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY REGEDIT uninstall.exe or MSI ID
if($useMethodUninstallRegister) {
	Write-Output "Trying uninstall using register uninstall string path..."
	$app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName }
	if(!$app) { $app = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName } }
	if($app) {
      $uninstallString=$app.UninstallString
      # .MSI UNINSTALL
      if($uninstallString -match "msiexec.exe") {
        $msiID=($uninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X","").Trim()
        Write-Output "Executing MSI uninstall from: ${msiID}"
        start-process "msiexec.exe" -arg "/X $uninstall64 /qn" -Wait
        if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }

   	  # .EXE UNINSTALL?
	  }elseif($uninstallString -match "uninst") {
        $uninstallPath=$uninstallString
        $uninstallArgs=$argumentList
        if($uninstallPath.StartsWith("`"")) { 
            $uninstallPath=$uninstallString.Split("`"")[1]
            $uninstallArgs=$uninstallString.Split("`"")|Select -Skip 2
            $uninstallArgs=$uninstallArgs+" "+$argumentList
        }
		Write-Output "Executing uninstall: ${uninstallPath} ${uninstallArgs}"
		Start-Process -FilePath $uninstallPath -ArgumentList $uninstallArgs -Verb runas -Wait
		if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
		Write-Output "ERROR!: Cant found uninstall method for $literalName package
   Typical uninstall.exe argumentList parameters are:
     * /s
     * /S
     * /S /v`"/qn`"
     * /SILENT
     * /VERYSILENT
     * /VERYSILENT /SUPPRESSMSGBOXES
     * Try & `"$uninstallPath`" /? to get specific method"
		  }
	}
}

# NO METHOD FOUND!
Write-Error "No uninstall method found!"
exit 1
