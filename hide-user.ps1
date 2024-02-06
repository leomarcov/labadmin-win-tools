#Requires -RunAsAdministrator

Param(
  [parameter(Mandatory=$true)]
  [Switch]$Hide,
  [parameter(Mandatory=$true)]
  [Switch]$Unhide
)

if($Hide) {
  New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $user -Value 0 -PropertyType DWord -ForceNam
}
elseif($Unhide) {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name $user -Force
}
