# Labadmin Freezer
<img align="left" src="https://www.iconfinder.com/icons/8610360/download/png/128">
Labadmin freezer is a collection of PowerShell scripts to manage Windows 10 systems in a lab school environment. Inclues functions to autoclean user profiles, disable USB storage, manage Windows Restoration Points, etc.
<br>
<br>
<br>
<br>

## Install
* Download and copy scripts files to `Program Files` folder:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-freezer/main/install.ps1'))
```

### Install profiles-cleaner
* Create first backup for each user:
```
& 'C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1' -CreateBackup -Users user1,user2
```
* Config Group Policies in `gpedit.msc`:
  * `Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts`
    * Script to exec: `C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1`
  * `Computer Configuration > Administrative Templates > System > Scripts > Run startup scripts asynchronously`
    * Set to **Disabled**
 
* Config frecuency in days and skip users in each `username.conf` file in `C:\Users\profiles-cleaner\` hidden folder.
