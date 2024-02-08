# Labadmin Win Tools
<img align="right" src="https://cdn4.iconfinder.com/data/icons/online-marketing-hand-drawn-vol-3/52/online__options__services__setting__gear__option__support-128.png">
Labadmin Win Tools is a collection of PowerShell scripts to admin Windows 10 systems in a lab school environment. Includes functions to:

  * **Autoclean user profiles (hot!)**
  * Disable USB storage
  * Manage Windows Restoration Points
  * Download and install files (.exe and .msi)
  * Users config: hide from login, disable, delete/change password, etc.
  * Set gateway address
  * Enable/disable antivirus realtime protection
<br>

## Package Install
* Download and copy scripts files to `Program Files\labadmin\labadmin-win-tools` folder and add to PATH:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-win-tools/main/install.ps1'))
```
<br>

## labadmin-profiles-cleaner.ps1
`labadmin-profiles-cleaner.ps1` is a script to automate user profiles cleaning. 
  * Fresh user profiles are backup in a secure place and are autorestored periodically (each reboot, once a day, once in some days, etc.).
  * Each user has is own autorestore settings.
  * Some folders in user profile can be restored on each reboot (userfull to remove personal data, like browser settings).
  * Restore can be forced programatically.

### Install 
* Create first backup for each user:
```
& 'C:\Program Files\labadmin\labadmin-win-tools\labadmin-profiles-cleaner.ps1' -BackupProfiles -Users user1,user2
```
* Config Group Policies in `gpedit.msc`:
  * **Exec script at startup**
    * `Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts`
    * Script to exec: `C:\Program Files\labadmin\labadmin-win-tools\labadmin-profiles-cleaner.ps1`
    * Params: `-RestoreProfile -Log`
  * **Disable run start asynchronously**
    * `Computer Configuration > Administrative Templates > System > Scripts > Run startup scripts asynchronously`
    * Set to **Disabled**

### Configuration
Each user can be config in **`<username>.cfg`** JSON file in `C:\Users\labadmin-profiles-cleaner\`:
  * `cleanAfterDays`: number of days from last clean to next autoclean (0 clean in each reboot, 1 clean every day, etc).
  * `skipUserp`: boolean to skip this user from autoclean (skips cleanAfterDays and cleanAllways).
  * `cleanAllways`: array of realtive profile paths to clean on every call.
  * `lastClean`: date where last clean was executed.

### Usage
```
SYNTAX
labadmin-profiles-cleaner.ps1 -BackupProfiles -Users <String[]> [-Log] 
labadmin-profiles-cleaner.ps1 -RestoreProfiles [-Users <String[]>] [-Force] [-Log] 

EXAMPLES
labadmin-profiles-cleaner.ps1 -BackupProfiles -Users u1,u2   # Create or update backup profile folder for u1 and u2
labadmin-profiles-cleaner.ps1 -RestoreProfiles               # Clean all users with saved backup according his config file
labadmin-profiles-cleaner.ps1 -RestoreProfiles -Force        # Force clean of all users with saved bakcup
labadmin-profiles-cleaner.ps1 -RestoreProfiles -Users u1     # Try clean user u1 only
```

