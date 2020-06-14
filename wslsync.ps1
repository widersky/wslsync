# WSLSync v1.0.0
# Author: Adrian Widerski

#Requires -RunAsAdministrator

Clear-Host

$scriptSettings = "config.json"
$settings = Get-Content .\$scriptSettings | ConvertFrom-Json
$firstRun = $settings.firstRun
$v = "v1.0.0 Beta"

Write-Host "`n💻 WSLSync $v"
Write-Host "📋 Author: widersky (https://github.com/widersky/)"
Write-Host "🐛 Issues? Ideas? Feel free to write here: https://github.com/widersky/wslsync/issues`n" -f blue
Write-Host "✋ The script is at an early stage of development. You use it at your own risk!`n`n" -f red
Write-Host "======================================================================================`n`n"

# Check first run and update config file
if ($firstRun -eq 1) {
  $commonPath = "C:/Windows/System32/drivers/etc/hosts"
  $path = ":/Windows/System32/drivers/etc/hosts"

  Write-Host ">> 👀 Looks like this is first run of this script! Let's make some preparations then!`n" -f yellow

  # Get Windows installation partition letter
  Write-Host ">> Checking if hosts file is in the default location..." -f green
  if (Test-Path "C:/Windows/System32/drivers/etc/hosts") {
    Write-Host ">> ✅ Yup, it's there" -f green
    $fullPath = $commonPath
  } else {
    Write-Host ">> Looks like your Windows installation path is customised. Specify the partition letter on which Windows is installed:" -f green
    $windowsLetter = Read-Host "[Just type letter and hit Enter]"
    $windowsLetter = $windowsLetter.toUpper()
    $fullPath = "$windowsLetter$path"
    Write-Host ">> 🧐 OK then! Looks like your hosts file is located under $fullPath"
  }

  # Get WSL's htdocs root
  Write-Host "`n>> What's the htdocs root path on your WSL?" -f green
  $WSLhtdocs = Read-Host "[Type exact path, e.g. ~/Web/]"
  Write-Host ">> 🧐 Good, your projects are located under $WSLhtdocs"

  # Generate config file
  Clear-Content .\$scriptSettings
  $wslIP = wsl hostname -I

  if (Test-Path $fullPath -PathType leaf) {
    $settings.firstRun = 0
    $settings.hostsPath = $fullPath -replace ' ', ''
    $settings.lastKnownIP = $wslIP -replace ' ', ''
    $settings.htdocsRoot = $WSLhtdocs
    $settings.extras.usingXampp = 0
    $settings | ConvertTo-Json -depth 32| Set-Content $scriptSettings
    Write-Host "`n>> ✅ Config created. Now you can re-run this script to work!`n" -f green
  } else {
    Write-Host "`n >> 🛑 Oops! Looks like hosts file does not exist in given path. Try again maybe?" -f red
    exit
  }
  exit
} else {
  if ($args.count -gt 0) {
    $action = $args[0]
  
    # run action by flag (-r, -a, -i, -reset...)
    switch ($action) {
      "-r" { .\modules\r.ps1; break }
      "-a" { .\modules\a.ps1; break }
      "-p" { .\modules\p.ps1; break }
      "-hardreset" { .\modules\hardreset.ps1; break }
    }
  } else {
    Write-Host "Use the flags below for your chosen purpose: `n"
  
    Write-Host "-r  Rewrite all WSL IP's to new"
    Write-Host "-a  Add new virtual host"
    Write-Host "-p  Preview current Windows hosts file"
    Write-Host "-i  Add new virtual host with choosen software installation (look at readme for details) [WIP]"
    Write-Host "-hardreset  Reset config file to default variables"
    Write-Host "`n"
  }
  
  exit
}