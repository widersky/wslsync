# WSLSync
# Author: Adrian Widerski
# Module: Terminate and start again WSL distro to ensure that changes are applied

# Requires -RunAsAdministrator

# For some reason wsl --list --running -q command returns many empty extra-characters - we need to remove them to properly terminate WSL session
$regex = '[^a-zA-Z0-9-.]'
$runningDistro = (wsl --list --running -q | Out-String -NoNewLine).Trim() -replace $regex, ''

# we don't use --shutdown flag because every shutdown makes new WSL IP.
# TODO: make it possible to terminate more than one running distros
wsl --terminate $runningDistro
Write-Host "`n>> 💀 Detected running distro: $runningDistro, terminated to sync virtual hosts"
wsl --distribution $runningDistro exit
Write-Host ">> 🐧 Running previously terminated $runningDistro`n"