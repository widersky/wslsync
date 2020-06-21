# WSLSync v1.0.0
# Author: Adrian Widerski

#Requires -RunAsAdministrator

[CmdletBinding()]param(
  [Parameter( Mandatory = $false )][string]$a,
  [Parameter( Mandatory = $false )][switch]$p,
  [Parameter( Mandatory = $false )][switch]$help
)

$scriptConfig = "config.json"
  
Clear-Host

Import-Module -Name .\inc\helpers.psm1 -Force -ArgumentList "$scriptConfig" # Import helpers
if (-Not (CommandExists wsl)) { exit } # Terminate script when wsl is not installed

# Check if config.json exists
if (Test-Path "./$scriptConfig") {
  
  MakeHostsFileBackup
  if ( $PSBoundParameters.Count -eq 0 ) { RewriteWSLSyncHosts } # Rewrite all hosts when there are not parameters given
  else { CheckParams($PSBoundParameters) } # Check given parameters otherwise

# Do first config otherwise
} else { FirstConfig }