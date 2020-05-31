# WSLSync
# Author: Adrian Widerski
# Module: Add new virtual host
# Flag: -a

# Requires -RunAsAdministrator

Write-Host ">> We're going to add new virtual host to your Windows / WSL hosts file. Do you want to continue?" -f green
Read-Host "[Enter to continue / CTRL + C to abort]"

$newHost = Read-Host "[Enter new host domain]"
$WSLIP = wsl hostname -I # get IP address from WSL distro

# $scriptSettings = "config.json"
# $settings = Get-Content .\$scriptSettings | ConvertFrom-Json

$newHostLine = "$WSLIP`t$newHost"
Add-Content $settings.hostsPath $newHostLine
Write-Host "`n>> ✅ Added new virtual host: $newHostLine" -f green

# Restart WSL session
.\modules\restart.ps1

Write-Host ">> ✅ Done!`n" -f green