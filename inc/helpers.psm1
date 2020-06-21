# WSLSync
# Author: Adrian Widerski
# Module: Helpers to make script more readable

param(
  [parameter(Position = 0, Mandatory = $true)][string]$scriptConfig
)
  
$v = "v0.9.6 Beta"
$config = Get-Content .\$scriptConfig | ConvertFrom-Json


# =======================================
# Helpful variables
# =======================================
$WSLSyncHostsBeggining = "# WSLSyncStart"
$WSLSyncHostsEnding = "# WSLSyncEnd"
$hostsFile = $config.hostsPath

# =======================================
# Check if command exists
# =======================================
Function CommandExists {
  Param ($cmd)
  $pref = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  try { if (Get-Command $cmd) { RETURN $true } }
  Catch { Write-Host "Command $cmd does not exist!" -f Red; RETURN $false }
  Finally { $ErrorActionPreference = $pref }
}


# Check given params
Function CheckParams($boundParams) {
  switch ( $boundParams.Keys ) {
    "a" { ActionAddProject $boundParams['a']; RestartWSLDistro; break }
    "p" { ShowHostsContent; break }
    "help" { PrintHelp; break }
  }
}


Function ShowHostsContent {
  Write-Host ">> Here's how Windows hosts file looks right now:`n`n" -f Yellow
  Get-Content $config.hostsPath
  Write-Host "`n`n"
}


# =======================================
# Check if WSLSync range exists in hosts file
# =======================================
Function RewriteWSLSyncHosts {
  Set-Content -Path $hostsFile -Value (Get-Content -Path $hostsFile | Select-String -Pattern $WSLSyncHostsBeggining -NotMatch)
  Set-Content -Path $hostsFile -Value (Get-Content -Path $hostsFile | Select-String -Pattern $WSLSyncHostsEnding -NotMatch)

  Add-Content $hostsFile $WSLSyncHostsBeggining
  GenerateHosts
  Add-Content $hostsFile $WSLSyncHostsEnding

  Write-Host "> " -f Green -NoNewline
  Write-Host "Hosts refreshed"
}


# =======================================
# Generate virtual hosts by folders names in htdocs location
# =======================================
Function GenerateHosts {
  $WSLProjectsPath = $config.htdocsRoot
  $folders = wsl ls $WSLProjectsPath # get folders list from htdocs
  $WSLIP = wsl hostname -I # get IP address from WSL distro
  $domain = $config.localDomain
  $hosts = @() # create empty hosts array
  [System.Collections.ArrayList]$hostsList = $hosts # use System.Collections.ArrayList to ensure that we can modify this array
  
  Write-Host "> " -f Green -NoNewline
  Write-Host "Refreshing hosts...`n"

  foreach ($folder in $folders) {
    Write-Host "📁 Found: " -NoNewline
    Write-Host $folder -f Green

    [void]$hostsList.Add("$WSLIP`t$folder$domain")
  }

  Write-Host "`n"
  Write-Host "> " -f Green -NoNewline
  Write-Host "Wrote those lines into hosts file:`n"

  foreach ($line in $hostsList) {
    Write-Host $line -f Green

    $domainName = $line.split("`t")[1]
    Set-Content -Path $hostsFile -Value (Get-Content -Path $hostsFile | Select-String -Pattern $domainName -NotMatch) # check if host exists, if yes - remove
    Add-Content $hostsFile $line # ... and re-add in proper place
  }

  # Restart WSL session
  Write-Host "`n"
}


# =======================================
# Restart Linux
# =======================================
Function RestartWSLDistro {
  $regex = '[^a-zA-Z0-9-.]'
  $runningDistro = (wsl --list --running -q | Out-String -NoNewLine).Trim() -replace $regex, ''

  # we don't use --shutdown flag because every shutdown makes new WSL IP
  wsl --terminate $runningDistro
  wsl --distribution $runningDistro exit
  Write-Host "! " -f Red -NoNewline
  Write-Host "Detected running distro: $runningDistro, restarted to sync virtual hosts`n"
}


# =======================================
# Re-add vhosts in XAMPP // TODO
# =======================================
Function GenerateXAMPPHosts {

}


# =======================================
# Just print help text
# =======================================
Function PrintHelp {
  Write-Host "💡 HOW IT WORKS:`n" -f Yellow
  Write-Host "Running WSLSync without any flags results in rewriting all hosts based on directory names in project folder defined in config file.`n"
  Write-Host "🏁 AVAILABLE FLAGS: `n" -f Yellow
  # Write-Host "-a  Add new project [WIP]"
  Write-Host "-p  Preview current Windows hosts file`n"
  Write-Host "-help  Show this message`n"
  Write-Host "❓ HOW TO:`n" -f Yellow
  Write-Host "* Reset everything: Just remove config.json file and re-run wslconfig.ps1 file"
  Write-Host "`n"
}


# =======================================
# Print script header info
# =======================================
Function PrintInfo {
  Write-Host "`n💻 WSLSync $v"
  Write-Host "📋 Author: widersky (https://github.com/widersky/)"
  Write-Host "✋ The script is at an early stage of development. You use it at your own risk!`n" -f Red
  Write-Host "🐛 Issues? Ideas? Feel free to write here: https://github.com/widersky/wslsync/issues`n`n" -f Blue
  Write-Host "***`n`n"
}


Function MakeHostsFileBackup {
  $date = Get-Date -Format "ddMMyyyy-HHmmss"
  $backupName = "hostsbackup_$date"
  Copy-Item $config.hostsPath -Destination .\backups\$backupName
}


# =======================================
# Go through first config
# =======================================
Function FirstConfig {
  $commonHostsPath = "C:/Windows/System32/drivers/etc/hosts"
  $path = ":/Windows/System32/drivers/etc/hosts"

  $defaultHtdocsPath = "~/web/"
  $defaultWSLDomain = ".test"

  Write-Host "👀 Looks like this is first run of this script! Let's make some preparations then!`n" -f Green
  Write-Host "💡 This script will not overwrite existing entries in the hosts file. It will create its own range between specific lines of text based on the directories in the WSL project location.`n" -f Yellow

  Write-Host "? " -f Green -NoNewline
  Write-Host "Ready?"
  Read-Host "[Enter to continue / CTRL + C to abort]"

  # Get Windows installation partition letter
  Write-Host "> " -f Green -NoNewline
  Write-Host "Checking if hosts file is in the common location..."
  if (Test-Path "C:/Windows/System32/drivers/etc/hosts") {
    Write-Host "✅ Yup, it's there" -f green
    $fullPath = $commonHostsPath
  } else {
    Write-Host "? " -f Green -NoNewline
    Write-Host "Looks like your Windows installation path is customised. Specify the partition letter on which Windows is installed:"
    $windowsLetter = Read-Host "[Just type letter and hit Enter]"
    $windowsLetter = $windowsLetter.toUpper()
    $fullPath = "$windowsLetter$path"
    Write-Host ">> 🧐 OK then! Looks like your hosts file is located under $fullPath"
  }

  # Get WSL's htdocs root
  Write-Host "? " -f Green -NoNewline
  Write-Host "What's the htdocs root path on your WSL?"
  $checkWSLhtdocs = Read-Host "[Type exact path. Default: $defaultHtdocsPath]"
  if (!$checkWSLhtdocs) {
    $WSLhtdocs = $defaultHtdocsPath
  } else {
    $WSLhtdocs = $checkWSLhtdocs
  }

  # Get custom domain
  Write-Host "? " -f Green -NoNewline
  Write-Host "What's the domain you would like to use?"
  $checkWSLDomain = Read-Host "[Type just domain. Default: .test]"
  if (!$checkWSLDomain) {
    $WSLDomain = $defaultWSLDomain
  } else {
    $WSLDomain = $checkWSLDomain
  }

  # Whether the user uses xampp
  Write-Host "? " -f Green -NoNewline
  Write-Host "Do you use XAMPP software on WSL?"
  $Xampp = Read-Host "[y/N]"
  if ($Xampp.toUpper() -eq "Y") {
    $WSLXampp = 1
    $WSLXamppString = "Yes"
  } else {
    $WSLXampp = 0
    $WSLXamppString = "No"
  }

  # Generate config file
  Write-Host "! " -f Yellow -NoNewline
  Write-Host "Done! Here's your config details:"
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
    Write-Host "> " -f Green -NoNewline
    Write-Host "Config created. Now you can re-run this script to work!`n"
    PrintHelp
  } else {
    Write-Host "! " -f Red -NoNewline
    Write-Host "Oops! Looks like hosts file does not exist in given path. Try again maybe?"
    exit
  }
  exit
}


# =======================================
# Add new project action
# =======================================
Function ActionAddProject([string]$name) {
  $WSLIP = wsl hostname -I # get IP address from WSL distro
  $localDomain = $config.localDomain
  $htdocsRoot = $config.htdocsRoot
  $newVHost = $name + $localDomain
  $newVHostLine = "$WSLIP`t$newVHost"

  PrintInfo

  Write-Host "? " -f Green -NoNewline
  Write-Host "Create new project '$name'?"
  Read-Host "[Enter to continue / CTRL + C to abort]"

  $newProjectPath = "$htdocsRoot$name"

  wsl mkdir $newProjectPath
  Write-Host "> " -f Green -NoNewline
  Write-Host "Created project folder $newProjectPath"

  RewriteWSLSyncHosts

  # Extra XAMPP support
#   if ($config.usingXampp -eq 1) {
#     $vHostsFile = "/opt/lampp/etc/extra/httpd-vhosts.conf"
#     $vHostString = @"

# # $name$localDomain
# <VirtualHost 127.0.0.3:80>
#   DocumentRoot `"$htDocsRoot$name`"
#   DirectoryIndex index.php
  
#   <Directory `"$htDocsRoot$name`">
#     Options All
#     AllowOverride All
#     Require all granted
#   </Directory>
# </VirtualHost>
# "@
#     Write-Host ">> Using XAMPP installation. Adding new virtual host to $vHostsFile`n" -f green
#     Write-Host ">> Remember, you must enable virtual hosts support in '/opt/lampp/etc/httpd.conf' file by uncommenting 'Include etc/extra/httpd-vhosts.conf' line`n" -f yellow
#     wsl sudo su -c "echo '$vHostString' >> $vHostsFile"
  # }

  Write-Host "> " -f Green -NoNewline
  Write-Host "Done!`n"
}