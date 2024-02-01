#Requires -RunAsAdministrator

#### PARAMETERS ##################################################
Param(
  [Switch]$Enable,           # Enable RPs
  [Switch]$Create,           # Create RP
  [Switch]$DeleteAll,        # Delete ALL restore points
  [Switch]$Restore           # Restore RP
)


#### ACTION ENABLE ###############################################
} if($enable) {
    Enable-ComputerRestore -Drive c:
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB

#### ACTION CREATE ###############################################
elseif$($create) {
    Checkpoint-Computer -Description "labadmin-freezer-main"

#### ACTION DELETE ###############################################
} elseif($deleteall) {
  vssadmin delete shadows /all

#### ACTION RESTORE ###############################################
} elseif($restore) {
    Restore-Computer -RestorePoint 1

#### ACTION LIST ##################################################
} else {
   Get-ComputerRestorePoint
}
