#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Manage Windows Restore Points
.PARAMETER List
	List all current saved restore points
.PARAMETER Enable
	Enable use of restore points with 5GB of max use
.PARAMETER Create
	Create restore point with description "labadmin-main"
.PARAMETER Restore
	Restore restore point with description "labadmin-main"
.PARAMETER DelteAll
	Delete all saved restore points

.NOTES
    File Name      : labadmin-manage-restorepoints.ps1
    Author         : Leonardo Marco
#>


#### PARAMETERS ##################################################
Param(
  [Switch]$List              # List RPs
  [Switch]$Enable,           # Enable RPs
  [Switch]$Create,           # Create RP
  [Switch]$Restore,          # Restore RP 1
  [Switch]$DeleteAll,        # Delete ALL restore points
)

#### ACTION LIST ##################################################
if($list) {
   Get-ComputerRestorePoint
}

#### ACTION ENABLE ###############################################
if($enable) {
    Enable-ComputerRestore -Drive c:
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB
}

#### ACTION CREATE ###############################################
if($create) {
    Checkpoint-Computer -Description "labadmin-main"
}

#### ACTION RESTORE ###############################################
if($restore) {
  $labadmin_rpn=(Get-ComputerRestorePoint | where-object { $_.Description -eq "labadmin-freezer-main" }).SequenceNumber
  Restore-Computer -RestorePoint $labadmin_rpn
}

#### ACTION DELETE ###############################################
if($deleteall) {
  vssadmin delete shadows /all /quiet
}



