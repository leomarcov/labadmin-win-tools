#Requires -RunAsAdministrator

#### PARAMETERS ##################################################
Param(
  [Switch]$Create,           # Create RP
  [Switch]$DeleteAll,        # Delete ALL restore points
  [Switch]$Restore           # Restore RP
)



#### ACTION CREATE ###############################################
if$($create) {
    Checkpoint-Computer -Description "labadmin-freezer-main"
} elseif($deleteall) {
  
#### ACTION RESTORE ###############################################
} elseif($restore) {
    Restore-Computer -RestorePoint 1
#### ACTION LIST ##################################################
} else {
   Get-ComputerRestorePoint
}
