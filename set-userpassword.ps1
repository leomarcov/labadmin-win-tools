#Requires -RunAsAdministrator

Param(
  [parameter(Mandatory=$true, ParameterSetName="remove")]
  [parameter(Mandatory=$true, ParameterSetName="change")]
  [String]$User,
  [parameter(Mandatory=$true, ParameterSetName="change")]
  [String]$Passowrd,
  [parameter(Mandatory=$true, ParameterSetName="remove")]
  [Switch]$NoPassowrd
)

if($NoPassword) {
	Set-LocalUser -name $user -Password ([securestring]::new())
} else {
 	$ss=$Password|ConvertTo-SecureString -AsPlainText -Force
 	Set-LocalUser -Name $user -Password $ss
}
