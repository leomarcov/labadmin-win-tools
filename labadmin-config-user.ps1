#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Config some user login authentication/login settings (hide from login list, remove password, disable account, etc).

.PARAMETER UserName
	Username of account to config
.PARAMETER SetPassword
	Config new account password
.PARAMETER Password
	Password in plain text to set
.PARAMETER NoPassword
	Remove user password for login without password
.PARAMETER Hide
	Hide user from login list
.PARAMETER Unhide
	Unhide user from login list
.PARAMETER Disable
	Disable user account
.PARAMETER Enable
 	Enable user account

.NOTES
    File Name      : labadmin-profiles-cleaner.ps1
    Author         : Leonardo Marco
#>



Param(
  [Parameter(Mandatory=$true)]
  [String]$UserName,

  [parameter(Mandatory=$true, ParameterSetName='password')]
  [Switch]$SetPassword,
  [parameter(Mandatory=$true, ParameterSetName='password')]
  [String]$Password,

  [Parameter(ParameterSetName='nopass')]
  [Switch]$NoPassword,

  [Parameter(ParameterSetName='hide')]
  [Switch]$Hide,
  
  [Parameter(ParameterSetName='hide')]
  [Switch]$Unhide,
  
  [Parameter(ParameterSetName='disable')]
  [Switch]$Disable,
  
  [Parameter(ParameterSetName='disable')]
  [Switch]$Enable
)

Get-LocalUser -Name $UserName -ErrorAction Stop | Out-Null

if($Hide) {
	New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $UserName -Value 0 -PropertyType DWord -Force
}
elseif($Unhide) {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name $UserName -Force
}

if($Disable) {
	Disable-LocalUser -Name $UserName
	Get-LocalUser -Name $UserName
}
elseif($Enable) {
	Enable-LocalUser -Name $UserName
    	Get-LocalUser -Name $UserName
}

if($NoPassword) {
	Set-LocalUser -Name $UserName -Password ([securestring]::new())
}
if($SetPassword){
 	$ss=$Password|ConvertTo-SecureString -AsPlainText -Force
 	Set-LocalUser -Name $UserName -Password $ss
}
