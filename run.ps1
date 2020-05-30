# WSL2 Hosts Refresher v1.0.0
# Author: Adrian Widerski

# Requires -RunAsAdministrator

Clear-Host

Write-Host "🤚 Welcome to WSL2 Hosts Refresher!"
Write-Host "🧐 We will find old WSL IP's in Windows hosts and replace them with new ones!`n"

$scriptSettings = "config.json"
$settings = Get-Content .\$scriptSettings | ConvertFrom-Json
$firstRun = $settings.firstRun

# Check first run and update config file
if ($firstRun -eq 1) {
  Write-Host "👀 Looks like this is first run of this script!"
  Write-Host "Let's make some preparations then!`n"
  Write-Host "What's the letter of drive where is installed your Windows?" -f green
  $windowsLetter = Read-Host "[Just type letter and hit Enter]"
  $windowsLetter = $windowsLetter.toUpper()
  $path = ":/Windows/System32/drivers/etc/hosts"
  $fullPath = "$windowsLetter$path"
  Write-Host "`n🧐 OK then! Looks like your hosts file is located under $fullPath"

  if (Test-Path $fullPath -PathType leaf) {
    Write-Host "✅ Yup it's there!"
    $params = '{
  "firstRun": 0,
  "windowsOn": "' + $windowsLetter + '"
}'
    Clear-Content .\$scriptSettings
    Set-Content -Path .\$scriptSettings -Value $params
    Write-Host "✅ Config updated. Now you can re-run this script to work!`n"
  } else {
    Write-Host "🛑 Oops! Looks like we're missed. Try again maybe?" -f red
    exit
  }
  exit
} else {
  Write-Host "Do you want to continue?" -f green
  Read-Host "[Enter to continue / CTRL + C to abort]"
}

# Magic here
$hostsPath = "hosts-example"
$hostsTemp = "hosts-temp"
$backupDate = Get-Date -Format "ddMMyyyy_HHmmss"
$hostsBackup = "hosts-backup-$backupDate"
$hostsBackupDir = "backups"
$IPv4Regex = '(?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)'
$WSLHostsLineBegin = "# WSL Hosts Begin"
$WSLHostsLineEnd = "# WSL Hosts End"
$NewLinuxIP = wsl hostname -I # get IP address from WSL distro
Write-Host "🤖 Current Linux IP: $NewLinuxIP `n"
$newWSLIP = $NewLinuxIP

Remove-Item .\$hostsTemp -Recurse -ErrorAction Ignore
[void](mkdir -Force $hostsBackupDir)
Get-Content .\$hostsPath | Out-File .\$hostsBackupDir\$hostsBackup

# Check if Windows hosts file is prepared to use with this script
$CheckHostsFileValidity = @(Get-Content $hostsPath | Where-Object { $_.Contains($WSLHostsLineBegin) }).Count
if ($CheckHostsFileValidity -eq 0) {
  Write-Host "😣 OOPS! Looks like your Windows hosts file aren't prepared to use with this tool...`n" -f red
  Write-Host "Don't worry! Here, how's to do that:"
  Write-Host "1. Open C:/Windows/System32/drivers/etc/hosts file with admin rights"
  Write-Host "2. Place this line just above hosts that are related to WSL2: $WSLHostsLineBegin"
  Write-Host "3. Place this line just below hosts that are related to WSL2: $WSLHostsLineEnd"
  Write-Host "4. Save file"
  Write-Host "5. That's it! Now you can re-run this script!`n"
  exit
} else {
  Write-Host "✅ Found some WSL hosts!"
}

$i = 0

foreach ($line in Get-Content .\$hostsPath) {
  if ($line -eq $WSLHostsLineBegin) { $changeState = 1 } # change state to begin IP matching
  if ($line -eq $WSLHostsLineEnd) { Clear-Variable changeState } # change state to end IP matching

  if ($changeState) {
    # We don't need to match designation line - only IP's
    if ($i -gt 0) {
      $newLine = $line -replace $IPv4Regex, $newWSLIP
      Write-Host "📋 Refreshed entry: $newLine"
    } else {
      $newLine = $line
    }
    $i++
  } else {
    $newLine = $line
  }

  [void](Add-Content $hostsTemp -Value $newLine -PassThru)
}

Remove-Item $hostsPath -Recurse -ErrorAction Ignore
Get-Content $hostsTemp | Out-File $hostsPath

# wsl.exe --terminate
# TODO: really terminate WSL instances
Write-Host "💀 WSL terminated"
Write-Host "✅ Done! Now you can re-reun your distro to see changes!`n"