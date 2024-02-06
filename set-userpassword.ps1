#Requires -RunAsAdministrator

Param(
  [parameter(Mandatory=$true)]
  [Switch]$User,
  [parameter(Mandatory=$true)]
  [Switch]$Passowrd
)

if($SetUserPassword) {
	$ss=$Password|ConvertTo-SecureString -AsPlainText -Force
 	Set-LocalUser -Name $user -Password $ss
}
