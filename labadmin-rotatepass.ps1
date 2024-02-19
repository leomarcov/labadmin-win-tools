#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Rotate user password according rule

.PARAMETER userName
	Username account to rotate
.PARAMETER show
	Show schedule job info rotation for userName account
.PARAMETER disable
	Disable schedule job rotation for userName account
.PARAMETER enable
	Enable schedule job rotation for userName account
.PARAMETER register
	Register schedule job rotation for userName account
.PARAMETER unregister
	Unregister schedule job rotation for userName account

.NOTES
    File Name: labadmin-rotatepass.ps1
    Author   : Leonardo Marco
#>

Param(
  [parameter(Mandatory=$true, Position=0)]
  [String]$userName,

  [Switch]$show,
  [Switch]$disable,
  [Switch]$enable,
  [Switch]$register,
  [Switch]$unregister
)

# CONFIG VARIABLES
$scheduledJobName="labadmin-rotatepass"


function rotatePassword {
    $d=(Get-Date).toString("yyyyMMdd")
    $f1="Q","W","E","R","T","Y","U","I","O","P"
    $f2="A","S","D","F","G","H","J","K","L","x" 
    $f3="Z","X","C","V","B","N","M",",",".","-"
    $p=$f1[[System.Int32]::Parse($d[0])-1]+$f1[[System.Int32]::Parse($d[1])-1]+$f1[[System.Int32]::Parse($d[2])-1]+$f1[[System.Int32]::Parse($d[3])-1]+$f2[[System.Int32]::Parse($d[4])-1]+$f2[[System.Int32]::Parse($d[5])-1]+$f3[[System.Int32]::Parse($d[6])-1]+$f3[[System.Int32]::Parse($d[7])-1]
$p 
   $ss=$p|ConvertTo-SecureString -AsPlainText -Force
    Set-LocalUser -Name $userName -Password $ss
}


function show {
	Write-Output "Scheduled job $scheduledJobName for user ${userName}:"
    $job=Get-ScheduledJob -name $scheduledJobName -ErrorAction SilentlyContinue
    if(!$job) { Write-Output "No scheduled job for $scheduledJobName"; exit 1 }
	$job
    $job | Format-List -Property Id,Command,Enabled
    $job.options
}

function disable {
	Write-Output "Disabling scheduled job $scheduledJobName for user $userName ..."
    $job=Get-ScheduledJob -name $scheduledJobName -ErrorAction SilentlyContinue
    if(!$job) { Write-Output "No scheduled job for $scheduledJobName"; exit 1 }
    Disable-ScheduledJob $job.Id -ErrorAction Stop
    $job
}

function enable {
	Write-Output "Enabling scheduled job $scheduledJobName for user $userName ..."
    $job=Get-ScheduledJob -name $scheduledJobName -ErrorAction SilentlyContinue
    if(!$job) { Write-Output "No scheduled job for $scheduledJobName"; exit 1 }
    Enable-ScheduledJob $job.Id -ErrorAction Stop
    $job
}

function register {
    Write-Output "Registering scheduled job $scheduledJobName for user $userName .."
    Unregister-ScheduledJob $scheduledJobName -ErrorAction SilentlyContinue
    Register-ScheduledJob -Name $scheduledJobName -FilePath ${PSCommandPath} -ArgumentList @("${userName}") -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:00:30) -ScheduledJobOption (New-ScheduledJobOption -RunElevated)
}

function unregister {
    Write-Output "Unregistering scheduled job $scheduledJobName for user $userName .."
    $job=Get-ScheduledJob -name $scheduledJobName -ErrorAction SilentlyContinue
	if(!$job) { Write-Output "No scheduled job for $scheduledJobName"; exit 1 }
    Unregister-ScheduledJob $scheduledJobName
}




if($register -OR $unregister -OR $enable -OR $disable -OR $show) { if([Environment]::UserName -ne $userName) { Write-Error "Exec as user: $userName"; exit 1 } }

if($register) 		{ register }
elseif($unregister) 	{ unregister }
elseif($enable) 	{ enable }
elseif($disable) 	{ disable }
elseif($show) 		{ show }
else 			{ rotatePassword }


