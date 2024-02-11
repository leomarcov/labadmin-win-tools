#Requires -RunAsAdministrator

<#
.SYNOPSIS
	Try silent noGUI uninstall program using some methods
.PARAMETER list
  No uninstall, only list all installed packages on system. Optional name can be used to filter matches
  
 .PARAMETER uninstallCustomString
  Uninstall using custom command and arguments. Example: "c:\path\to\command.exe" /arg1 /arg2 /arg3
  
.PARAMETER programName
  Name of package to match (if multiple matches will be cancelled)
.PARAMETER uninstallWmiObject
  Try WmiObject method to uninstall
.PARAMETER uninstallUninstallPackage
  Try Uninstall-Package cmdlet method to uninstall
.PARAMETER uninstallWinget
  Try winget method to uninstall
.PARAMETER uninstallRegistryUninstaller
  Try uninstall string from registry method to uninstall
.PARAMETER uninstallArgs
  Optional argument list to use for uninstall.exe (by default /S is used)
  Typical arguments for silent and no GUI are:
    * /s
    * /S
    * /S /v"/qn"
    * /SILENT
    * /VERYSILENT
    * /VERYSILENT /SUPPRESSMSGBOXES
    * /quiet
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
  [Switch]$uninstallWmiObject,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]
  [Switch]$uninstallUninstallPackage,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]
  [Switch]$uninstallWinget,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]  
  [Switch]$uninstallRegistryUninstaller,
  [parameter(Mandatory=$false, ParameterSetName="uninstall")]

  [String]$uninstallArgs,

  [parameter(Mandatory=$false, ParameterSetName="uninstallcustom")]
  [String]$uninstallCustomString,
  
  
  [parameter(Position=0, Mandatory=$true, ParameterSetName="list")]
  [Switch]$list
)


# CONFIG VARIABLES
if(!$uninstallArgs) { $uninstallArgs="/S" }

#########################################################################################
##### LIST ##############################################################################
#########################################################################################
if($list) {
	$list2=Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $programName }
    $literalName=$list2.Name
	# Multiple result: show list
    if($list2 -is [Array]) { $list2; exit 0 }
    # 1 result: Show app info
    elseif ($list2) {
		# Check REGISTRY UNINSTALLER 
        $list2; Write-Output "`n"
		Write-Output "Available methods`n-----------------"
        $app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName }
	    if(!$app) { $app = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName } }
	    if($app) {
            $ui=$app.UninstallString
            $qui=$app.QuietUninstallString
            Write-Output " * uninstallRegistryUninstaller : yes"
            Write-Output "      Uninstall string          : $ui"
            Write-Output "      Quiet uninstall string    : $qui`n"
        } 		else { Write-Output " * uninstallRegistryUninstaller : no" }
        # Check WMIOBJECT 
		if(Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $literalName }) { 
            Write-Output " * uninstallWmiObject           : yes"
        } else { Write-Output " * uninstallWmiObject           : no" }
        # Check WINGET
		if((Get-Command winget -ErrorAction SilentlyContinue) -AND (winget list $literalName)) {
            Write-Output " * uninstallWinget              : yes"
        } else { Write-Output " * uninstallWinget              : no" }
		# Check UNINSTALL-PACKAGE CMDLET
		if(Get-Package |  Where-Object { $_.ProviderName -ne "Programs" -AND $_.Name -eq "$literalName" } -ErrorAction SilentlyContinue) {
            Write-Output " * uninstallUninstallPackage    : yes"
        } else { Write-Output " * uninstallUninstallPackage    : no" }			
		
        exit 0
    }
 	exit 1
}



#########################################################################################
##### UNINSTALL #########################################################################
#########################################################################################

# TRY UNINSTALL: custom command
if($uninstallCustomString) {
	Write-Output "Trying uninstall using custom command"
	# Split uninstallCustomString: uninstallPath + uninstallArgs
	$uninstallPath=$uninstallCustomString
	if($uninstallPath.StartsWith("`"")) { $uninstallPath=$uninstallCustomString.Split("`"")[1]; $uninstallArgs=$uninstallCustomString.Split("`"")|Select -Skip 2 }
	else { $uninstallPath=$uninstallCustomString.Split(" ")[0]; $uninstallArgs=$uninstallCustomString.Split(" ")|Select -Skip 1  }	
	
	Write-Output "Executing command: ${uninstallPath}  ${uninstallArgs}"
	Start-Process -FilePath $uninstallPath -ArgumentList $uninstallArgs -Verb runas -Wait
	if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	exit 1
}


# GET LITERAL NAME MATCH
if(!$programName) { Write-Error "-programName param required"; exit 1 }
$literalName=Get-Package | Select-Object -Property Name | Where-Object { $_.Name -match $programName }
if(!$literalName) { Write-Error "Cant find installed program $programName"; exit 1 }
if($literalName -is [Array]) {  $literalName; Write-Error "Multiple matching for name: $programName"; exit 1 }
$literalName=$literalName.Name
if($programName -ne $literalName) { Write-Output "Literal program name found: $literalName" }

# CHECK PARAMETERS
if(!$uninstallCustomString -AND !$uninstallWmiObject -AND !$uninstallUninstallPackage -AND !$uninstallWinget -AND !$uninstallRegistryUninstaller) {
    Write-Error "Missing uninstall method parameter";	exit 1
}

# TRY UNINSTALL: WmiObject
if($uninstallWmiObject) {
	Write-Output "Trying uninstall using WmiObject..."
	$app=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $literalName }
	if($app) { 
	  $app.Uninstall()
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY UNINSTALL: Uninstall-Package
if($uninstallUninstallPackage) {
	Write-Output "Trying uninstall using Uninstall-Package..."
	$app=Get-Package $literalName
	if($app) {
	  Uninstall-Package -Name $literalName -Force
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY UNINSTALL: winget
if($uninstallWinget) {
	if(Get-Command winget -ErrorAction SilentlyContinue) {
	  winget uninstall --exact --force --silent --disable-interactivity --accept-source-agreements $literalName
	  if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
	}
}

# TRY REGEDIT uninstall string
if($uninstallRegistryUninstaller) {
	Write-Output "Trying uninstall using register uninstall string path..."
	$app=gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName }
	if(!$app) { $app = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_.DisplayName -eq $literalName } }
	if($app) {
	  # Get uninstall string
      $uninstallString=$app.UninstallString
	  if($app.QuietUninstallString) { $uninstallString=$app.QuietUninstallString }	  
      
	  # .MSI UNINSTALL
      if($uninstallString -match "msiexec.exe") {
        $msiID=($uninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X","").Trim()
        Write-Output "Executing MSI uninstall: msiexec.exe /x ${msiID} /qn"
        start-process "msiexec.exe" -arg "/x $msiID /qn" -Wait
        if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }

   	  # .EXE UNINSTALL?
	  } else {
        $uninstallPath=$uninstallString
		# Split uninstallString: uninstallPath + uninstallArgs
        if($uninstallPath.StartsWith("`"")) { $uninstallPath=$uninstallString.Split("`"")[1]; $uninstallArgs=($uninstallString.Split("`"")|Select -Skip 2)+" ${uninstallArgs}" }
		else { $uninstallPath=$uninstallString.Split(" ")[0]; $uninstallArgs=($uninstallString.Split(" ")|Select -Skip 1)+" ${uninstallArgs}"  }
		Write-Output "Executing uninstall: ${uninstallPath}  ${uninstallArgs}"
		
		Start-Process -FilePath $uninstallPath -ArgumentList $uninstallArgs -Verb runas -Wait
		if(!(Get-Package $literalName -ErrorAction SilentlyContinue)) { Write-Output "Uninstall successful!"; exit 0 }
		Write-Output "ERROR!: Cant found uninstall method for $literalName package
   Typical uninstall.exe uninstallArgs parameters are:
     * /s
     * /S
     * /S /v`"/qn`"
     * /SILENT
     * /VERYSILENT
     * /VERYSILENT /SUPPRESSMSGBOXES
     * /quiet
     * Try & `"$uninstallPath`" /? to get specific method"
		  }
	}
}

# NO METHOD FOUND!
Write-Error "No uninstall method found!"
exit 1
