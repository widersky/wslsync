# WSLSync
# Author: Adrian Widerski
# Module: Reset config file to default variables
# Flag: -hardreset

#Requires -RunAsAdministrator

$settings.firstRun = 1
$settings.hostsPath = ""
$settings.lastKnownIP = ""
$settings.htdocsRoot = ""
$settings.extras.usingXampp = 0
$settings | ConvertTo-Json -depth 32| Set-Content $scriptSettings
Write-Host "`n>> ✅ Configuration restored to default values.`n" -f green