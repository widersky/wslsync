# WSLSync
# Author: Adrian Widerski
# Module: Rewrite WSL IP's to fresh
# Flag: -r

# Requires -RunAsAdministrator

Write-Host ">> We're going to change old WSL IP's to new. Do you want to continue?" -f green
Read-Host "[Enter to continue / CTRL + C to abort]"

$scriptSettings = "config.json"
$settings = Get-Content .\$scriptSettings -raw | ConvertFrom-Json
$lastIP = $settings.lastKnownIP

$hostsPath = "hosts-example"
$hostsTemp = "hosts-temp"
$backupDate = Get-Date -Format "ddMMyyyy_HHmmss"
$hostsBackup = "hosts-backup-$backupDate"
$hostsBackupDir = "backups"
$newIP = wsl hostname -I # get IP address from WSL distro
Write-Host ">> 🤔 Last known WSL IP: $lastIP"
Write-Host ">> 🤖 Current WSL IP: $newIP `n"

if ($lastIP.Trim() -eq $newIP.Trim()) {
  Write-Host ">> 👀 Looks like WSL IP does not changed.`n" -f yellow
  exit
}

Remove-Item .\$hostsTemp -Recurse -ErrorAction Ignore
[void](mkdir -Force $hostsBackupDir)
Get-Content .\$hostsPath | Out-File .\$hostsBackupDir\$hostsBackup

$i = 0
foreach ($line in Get-Content .\$hostsPath) {
  if($line -like "*$lastIP*") {
    $newLine = $line -replace $lastIP, $newIP
    $i++
    Write-Host ">> 📋 Refreshed entry: $newLine"
  } else {
    $newLine = $line
  }

  [void](Add-Content $hostsTemp -Value $newLine -PassThru)
}

Write-Host "`n>> 📋 Refreshed $i entries`n"

Remove-Item $hostsPath -Recurse -ErrorAction Ignore
Get-Content $hostsTemp | Out-File $hostsPath

# Update settings json with new WSL IP
$settings.lastKnownIP = $newIP -replace ' ', ''
$settings | ConvertTo-Json -depth 32| Set-Content $scriptSettings
Write-Host ">> ✅ Updated config" -f green

# Restart WSL session
.\modules\restart.ps1

Write-Host ">> ✅ Done!`n" -f green