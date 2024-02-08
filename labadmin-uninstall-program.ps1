#Requires -RunAsAdministrator
Param(
  [String]$Name,                  # Name of program
  [String]$ID,                     # Identifying Number of program
  [Switch]$List
)

if($list) { Get-Package -Provider Programs -IncludeWindowsInstaller }

