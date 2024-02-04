# Labadmin Freezer
<img align="left" src="https://www.iconfinder.com/icons/8610360/download/png/128">
Labadmin freezer is a collection of PowerShell scripts to manage Windows 10 systems in a lab school environment. Inclues functions to autoclean user profiles, disable USB storage, manage Windows Restoration Points, etc.
<br>
<br>
<br>
<br>

## Package Install
* Download and copy scripts files to `Program Files` folder:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-freezer/main/install.ps1'))
```
<br>

## profiles-cleaner.ps1
`profiles-cleaner.ps1` is a script to automate user profiles cleaning. 
  * User profiles are backup in a secure place and are autorestored periodically (each reboot, once a day, once in some days, etc.).
  * Each user has is own autorestore settings.
  * Some folders in user profile can be restored on each reboot (userfull for browser history).
  * Restore con be forced programatically.

### Install 
* Create first backup for each user:
```
& 'C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1' -CreateBackup -Users user1,user2
```
* Config Group Policies in `gpedit.msc`:
  * **Exec script at startup**
    * `Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts`
    * Script to exec: `C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1`
    * Param: `-Log` (save logs in `c:\users\profiles-clenaer\logs.txt`
  * **Disable run start asynchronously**
    * `Computer Configuration > Administrative Templates > System > Scripts > Run startup scripts asynchronously`
    * Set to **Disabled**

### Configuration
Each user can be config in **`<username>.cfg`** JSON file in `C:\Users\profiles-cleaner\`:
  * `cleanAfterDays`: number of days from last clean to next autoclean (0 clean in each reboot, 1 clean every day, etc).
  * `skipUserp`: boolean value to skip this user from autoclean (skips `cleanAfterDays`).
  * `cleanAllways`: array of realtive profile paths to clean on every call.
  * `lastClean`: date where last clean was executed.
