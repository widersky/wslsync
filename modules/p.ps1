# WSLSync
# Author: Adrian Widerski
# Module: Preview Windows hosts file
# Flag: -a

#Requires -RunAsAdministrator

Write-Host ">> Here's how Windows hosts file looks right now:`n`n" -f green
Write-Host "=================================================`n`n"
Get-Content $settings.hostsPath