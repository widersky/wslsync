# WSLSync
# Author: Adrian Widerski
# Module: Reset config file to default variables
# Flag: -hardreset

#Requires -RunAsAdministrator

Write-Host ">> Would you like to restore config file to default values?" -f green
Read-Host "[Enter to continue / CTRL + C to abort]"

$settings.hostsPath = ""
$settings.lastKnownIP = ""
$settings.htdocsRoot = ""
$settings.localDomain = ".test"
$settings.usingXampp = 0
$settings | ConvertTo-Json -depth 32| Set-Content $scriptSettings

Write-Host "`n>> ✅ Configuration restored to default values.`n" -f green