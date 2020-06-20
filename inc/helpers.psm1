# WSLSync
# Author: Adrian Widerski
# Module: Helpers to make script more readable

# Get params
# 0 - config path
param(
  [parameter(Position = 0, Mandatory = $true)][string]$scriptConfig
)

$config = Get-Content .\$scriptConfig | ConvertFrom-Json


# Helpful variables
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
  try { if (Get-Command $cmd){ RETURN $true } }
  Catch { Write-Host "Command $cmd does not exist!" -f Red; RETURN $false }
  Finally { $ErrorActionPreference = $pref }
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

  Write-Host "`n>> Hosts regenerated"

  RestartWSLDistro
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
  
  foreach ($folder in $folders) {
    Write-Host "📁 Found: " -NoNewline
    Write-Host $folder -f Green

    [void]$hostsList.Add("$WSLIP`t$folder$domain")
  }

  Write-Host "`n>> Wrote this lines into hosts file:`n"

  foreach ($line in $hostsList) {
    Write-Host $line -f Green

    $domainName = $line.split("`t")[1]
    Set-Content -Path $hostsFile -Value (Get-Content -Path $hostsFile | Select-String -Pattern $domainName -NotMatch) # check if host exists, if yes - remove
    Add-Content $hostsFile $line # ... and re-add in proper place
  }
}


# =======================================
# Re-add vhosts in XAMPP // TODO
# =======================================
Function RestartWSLDistro {
  $regex = '[^a-zA-Z0-9-.]'
  $runningDistro = (wsl --list --running -q | Out-String -NoNewLine).Trim() -replace $regex, ''

  # we don't use --shutdown flag because every shutdown makes new WSL IP.
  # TODO: make it possible to terminate more than one running distros
  wsl --terminate $runningDistro
  wsl --distribution $runningDistro exit
  Write-Host ">> Detected running distro: $runningDistro, restarted to sync virtual hosts`n"
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
  # Write-Host "-a  Add new virtual host [WIP]"
  # Write-Host "-i  Add new virtual host with choosen software installation (look at readme for details) [WIP]"
  Write-Host "-p  Preview current Windows hosts file`n"
  Write-Host "❓ HOW TO:`n" -f Yellow
  Write-Host "* Reset everything: Just remove config.json file and re-run wslconfig.ps1 file"
  Write-Host "`n"
}