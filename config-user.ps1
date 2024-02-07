#Requires -RunAsAdministrator

Param(
  [Parameter(Mandatory)]
  [String]$User,
  [Switch]$Hide,
  [Switch]$Unhide,
  [Switch]$Disable,
  [Switch]$Enable
)

if($Hide) {
  New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $user -Value 0 -PropertyType DWord -ForceNam
}
if($Unhide) {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name $user -Force
}
if($Disable) {
	Disable-LocalUser -Name $user
}
if($Enable) {
	Enable-LocalUser -Name $user
}
