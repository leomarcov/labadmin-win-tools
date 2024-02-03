#Requires -RunAsAdministrator

#### PARAMETERS ##################################################
Param(
  [Switch]$Enable,           # Enable RPs
  [Switch]$Create,           # Create RP
  [Switch]$DeleteAll,        # Delete ALL restore points
  [Switch]$Restore,          # Restore RP 1
  [Switch]$List              # List RPs
)


#### ACTION ENABLE ###############################################
if($enable) {
    Enable-ComputerRestore -Drive c:
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB
}

#### ACTION CREATE ###############################################
if($create) {
    Checkpoint-Computer -Description "labadmin-main"
}

#### ACTION DELETE ###############################################
if($deleteall) {
  vssadmin delete shadows /all /quiet
}

#### ACTION RESTORE ###############################################
if($restore) {
  $labadmin_rpn=(Get-ComputerRestorePoint | where-object { $_.Description -eq "labadmin-freezer-main" }).SequenceNumber
  Restore-Computer -RestorePoint $labadmin_rpn
}

#### ACTION LIST ##################################################
if($list) {
   Get-ComputerRestorePoint
}
