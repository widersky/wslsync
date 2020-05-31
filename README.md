# WSLSync

This is PowerShell utility to make Windows10 and WSL2 hosts files in sync - with some extras.

> WSL2 synchronizes virtual hosts towards Windows -> Linux. Unfortunately, every time we run a WSL virtual machine, it receives a new IP address. This makes it difficult to work with virtual hosts. This script was created to automate changing WSL IP addresses in Windows `hosts` file.

## How it works?

The script backs up an existing `hosts` file, then searches its contents for old IP addresses and replaces them with new ones. Finally, it restarts detected Linux distribution without restarting VM (so as to preserve IP address).

> 🛑 For now, this script works only for one dsitro 🛑

## Using

* Run `wslsync.ps1` with admin rights

> 💡 Running script without any flags prints short help message 💡

💡 First script run initializes `config.json` generator. This file stores some helpful values to make sure that everything works OK:

`firstRun` - `1` or `0` - indicates whether the script is launched for the first time\
`hostsPath` - stores path to Windows hosts file\
`lastKnownIP` - stores last known WSL IP address\
`htdocsRoot` - stores htdocs root directory in WSL (currently does nothing)

### Available flags

`-r` - Refreshes IP addresses in Windows `hosts` file\
`-a` - Adds new virtual host