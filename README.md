# Labadmin Freezer
<img align="left" src="https://www.iconfinder.com/icons/8610360/download/png/128">
Labadmin freezer is a collection of PowerShell scripts for manage Windows system restoration points and user profiles autocleaner in a lab school environment.




## Install
* Download and copy files:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-freezer/main/install.ps1'))
```
* Create first backup for each user:
```
& 'C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1' -CreateBackup -Users user1,user2
```
* Config Group Policy (`gpedit.msc`) startup script:
  * `Computer Configuracion > Windows Settings > Scripts > Startup > PowerShell Scripts`
  * Script to exec: `C:\Program Files\labadmin\labadmin-freezer\profiles-cleaner.ps1`
 
* Config frecuency in days and skip users in each `username.conf` file in `C:\Users\profiles-cleaner\` hidden folder.
