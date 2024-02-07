#Requires -RunAsAdministrator

Param(
  [Parameter(Mandatory)]
  [String]$UserName,
  [Switch]$Hide,
  [Switch]$Unhide,
  [Switch]$Disable,
  [Switch]$Enable
)

Get-LocalUser -Name $UserName -ErrorAction Stop | Out-Null

if($Hide) {
  New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $UserName -Value 0 -PropertyType DWord -Force
}
if($Unhide) {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name $UserName -Force
}
if($Disable) {
	Disable-LocalUser -Name $UserName
    Get-LocalUser -Name $UserName
}
if($Enable) {
	Enable-LocalUser -Name $UserName
    Get-LocalUser -Name $UserName
}
