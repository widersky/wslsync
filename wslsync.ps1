# WSLSync v1.0.0
# Author: Adrian Widerski

#Requires -RunAsAdministrator

Clear-Host

$scriptSettings = "config.json"
$v = "v1.0.0 Beta 2"

Write-Host "`n💻 WSLSync $v"
Write-Host "📋 Author: widersky (https://github.com/widersky/)"
Write-Host "🐛 Issues? Ideas? Feel free to write here: https://github.com/widersky/wslsync/issues`n" -f blue
Write-Host "✋ The script is at an early stage of development. You use it at your own risk!`n`n" -f red
Write-Host "======================================================================================`n`n"

# Check config file and runn first run experience when it's not here
if (Test-Path "./$scriptSettings") {
  $settings = Get-Content .\$scriptSettings | ConvertFrom-Json

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
    .\modules\help.ps1;
  }
  
  exit
} else {
  $commonPath = "C:/Windows/System32/drivers/etc/hosts"
  $path = ":/Windows/System32/drivers/etc/hosts"

  Write-Host ">> 👀 Looks like this is first run of this script! Let's make some preparations then!`n" -f yellow

  # Get Windows installation partition letter
  Write-Host ">> Checking if hosts file is in the default location..." -f green
  if (Test-Path "C:/Windows/System32/drivers/etc/hosts") {
    Write-Host "✅ Yup, it's there" -f green
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
  $WSLhtdocs = Read-Host "[Type exact path, e.g. /opt/lampp/htdocs/web/]"

  # Get custom domain
  Write-Host "`n>> What's the domain you would like to use?" -f green
  $WSLDomain = Read-Host "[Type just domain, e.g. .test]"

  # Whether the user uses xampp
  Write-Host "`n>> Do you use XAMPP software on WSL?" -f green
  $Xampp = Read-Host "[y/N]"
  if ($Xampp.toUpper() -eq "Y") {
    $WSLXampp = 1
    $WSLXamppString = "Yes"
  } else {
    $WSLXampp = 0
    $WSLXamppString = "No"
  }
  
  # Get WSL IP
  $wslIP = wsl hostname -I

  # Generate config file
  Write-Host "`n`n>> Done! Here's your config details:" -f green
  Write-Host "📄 Windows hosts located at: $fullPath"
  Write-Host "📁 Projects location in WSL: $WSLhtdocs"
  Write-Host "🌍 Domain used to run projects: $WSLDomain"
  Write-Host "💻 WSL IP: $wslIP"
  Write-Host "🤔 WSL uses XAMPP: $WSLXamppString"

  if (Test-Path $fullPath -PathType leaf) {
    $settings = New-Object -TypeName PSObject -Property @{
      hostsPath = $fullPath.Trim()
      lastKnownIP = $wslIP.Trim()
      htdocsRoot = $WSLhtdocs
      localDomain = $WSLDomain
      usingXampp = $WSLXampp
    }
    $settings | ConvertTo-Json -depth 32| Out-File .\$scriptSettings
    Write-Host "`n>> 🎉 Config created. Now you can re-run this script to work!`n" -f green
    .\modules\help.ps1;
  } else {
    Write-Host "`n >> 😩 Oops! Looks like hosts file does not exist in given path. Try again maybe?" -f red
    exit
  }
  exit
}