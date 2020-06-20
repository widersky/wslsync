# WSLSync v1.0.0
# Author: Adrian Widerski

#Requires -RunAsAdministrator

Clear-Host

$scriptConfig = "config.json"
$v = "v0.9.5 Beta"

Write-Host "`n💻 WSLSync $v"
Write-Host "📋 Author: widersky (https://github.com/widersky/)"
Write-Host "✋ The script is at an early stage of development. You use it at your own risk!`n" -f Red
Write-Host "🐛 Issues? Ideas? Feel free to write here: https://github.com/widersky/wslsync/issues`n`n" -f Blue
Write-Host "***`n`n"

# Check config file and runn first run experience when it's not here
if (Test-Path "./$scriptConfig") {
  $config = Get-Content .\$scriptConfig | ConvertFrom-Json

  Import-Module -Name .\inc\helpers.psm1 -Force -ArgumentList "$scriptConfig" # Import helpers
  if (-Not (CommandExists wsl)) { exit } # Terminate script when wsl is not installed

  # ...or continue otherwise
  if ($args.count -gt 0) {
    $action = $args[0]
  
    # run action by flag (-r, -a, -i, -reset...)
    switch ($action) {
      "-help" { PrintHelp; break }
      # "-a" { .\actions\a.ps1; break }
      "-p" { ShowHostsContent; break }
    }
  } else {
    RewriteWSLSyncHosts
  }
  
  exit
} else {
  $commonPath = "C:/Windows/System32/drivers/etc/hosts"
  $path = ":/Windows/System32/drivers/etc/hosts"

  $defaultHtdocsPath = "/opt/lampp/htdocs/web/"
  $defaultWSLDomain = ".test"

  Write-Host "👀 Looks like this is first run of this script! Let's make some preparations then!`n" -f Green
  Write-Host "We'll do the following:"
  Write-Host "> Check if WSL is installed"
  Write-Host "> Check Windows hosts file location"
  Write-Host "> Check WSL htdocs location"
  Write-Host "> Set domain to use in your projects"
  Write-Host "> Check if XAMPP is used`n"

  Write-Host "💡 This script will not overwrite existing entries in the hosts file. It will create its own range between specific lines of text based on the directories in the WSL project location.`n" -f Yellow

  Write-Host ">> Ready?" -f green
  Read-Host "[Enter to continue / CTRL + C to abort]"

  # Get Windows installation partition letter
  Write-Host ">> Checking if hosts file is in the common location..." -f green
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
  $checkWSLhtdocs = Read-Host "[Type exact path. Default: $defaultHtdocsPath]"
  if (!$checkWSLhtdocs) {
    $WSLhtdocs = $defaultHtdocsPath
  } else {
    $WSLhtdocs = $checkWSLhtdocs
  }

  # Get custom domain
  Write-Host "`n>> What's the domain you would like to use?" -f green
  $checkWSLDomain = Read-Host "[Type just domain. Default: .test]"
  if (!$checkWSLDomain) {
    $WSLDomain = $defaultWSLDomain
  } else {
    $WSLDomain = $checkWSLDomain
  }

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

  # Generate config file
  Write-Host "`n`n>> Done! Here's your config details:" -f green
  Write-Host "📄 Windows hosts located at: $fullPath"
  Write-Host "📁 Projects location in WSL: $WSLhtdocs"
  Write-Host "🌍 Domain used to run projects: $WSLDomain"
  Write-Host "🤔 WSL uses XAMPP: $WSLXamppString"

  if (Test-Path $fullPath -PathType leaf) {
    $config = New-Object -TypeName PSObject -Property @{
      hostsPath = $fullPath.Trim()
      htdocsRoot = $WSLhtdocs
      localDomain = $WSLDomain
      usingXampp = $WSLXampp
    }
    $config | ConvertTo-Json -depth 32| Out-File .\$scriptConfig
    Write-Host "`n>> Config created. Now you can re-run this script to work!`n" -f green
    .\actions\help.ps1;
  } else {
    Write-Host "`n >> Oops! Looks like hosts file does not exist in given path. Try again maybe?" -f red
    exit
  }
  exit
}