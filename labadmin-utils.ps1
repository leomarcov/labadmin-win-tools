#Requires -RunAsAdministrator
Param(
  [Switch]$EnableUSBStorages,
  [Switch]$DisableUSBStorages,
  [Switch]$StatusUSBStorages,

  [Switch]$EnableRestorePoints,
  [Switch]$ListRestorePoints,  
  [Switch]$CreateLabadminRestorePoint,
  [Switch]$RestoreLabadminRestorePoint,
  [Switch]$DeleteAllRestorePoints,  

  [parameter(ParameterSetName="users")]
  [Switch]$HideUser,
  [parameter(ParameterSetName="users")]
  [Switch]$UnhideUser,
  
  [parameter(Mandatory=$true, ParameterSetName="users")]
  [String[]]$Users,

  [parameter(Mandatory=$true, ParameterSetName="user")]
  [String]$User,
  
  [parameter(Mandatory=$true, ParameterSetName="password")]
  [String[]]$Password,

  [parameter(ParameterSetName="user")]
  [Switch]$SetUserPassword
  
)

#### USB STORAGE
if($EnableUSBStorages) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 4
} 
if($DisableUSBSTorages) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\" -Name "Start" -Value 3
} 
if($StatusUSBStorages) {
  if ((Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR\' -Name "Start") -eq 4) { Write-Output "Disabled" } else { Write-Output "Enabled" }
}


#### RESTORE POINTS
if($EnableRestorePoints) {
    Enable-ComputerRestore -Drive c:
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB
}
if($ListRestorePoints) {
   Get-ComputerRestorePoint
}
if($CreateLabadminRestorePoint) {
    Checkpoint-Computer -Description "labadmin-main"
}
if($RestoreLabadminRestorePoint) {
  $labadmin_rpn=(Get-ComputerRestorePoint | where-object { $_.Description -eq "labadmin-freezer-main" }).SequenceNumber
  Restore-Computer -RestorePoint $labadmin_rpn
}
if($DeleteAllRestorePoints) {
  vssadmin delete shadows /all /quiet
}

#### HIDE USER
if($HideUser) {
  New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $user -Value 0 -PropertyType DWord -Force
}
if($UnhideUser) {
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name $user -Force
}
