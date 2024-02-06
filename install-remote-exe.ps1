#Requires -RunAsAdministrator
Param(
  [parameter(Mandatory=$true)]
  $URL,
  [parameter(Mandatory=$true)]
  $filename
)
  


$url="http://ftp.cifpcarlos3.net:8181/?r=/download&path=L2xhYmFkbWluLWF1dG9tYXRlZC1pbnN0YWxsYXRpb24vU0VCXzMuNi4wLjYzM19TZXR1cEJ1bmRsZS5leGU%3D"
Invoke-WebRequest -URI $url -outfile "c:\seb.exe"
Start-Process -FilePath "c:\seb.exe" -ArgumentList '/S','/v','/qn' -Verb runas -Wait
Remove-Item -Path "c:\seb.exe" -Force

