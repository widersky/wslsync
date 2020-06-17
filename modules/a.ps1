# WSLSync
# Author: Adrian Widerski
# Module: Add new virtual host
# Flag: -a

#Requires -RunAsAdministrator

Write-Host ">> We're going to add new virtual host to your Windows / WSL hosts file. Do you want to continue?" -f green
Read-Host "[Enter to continue / CTRL + C to abort]"

$newHost = Read-Host "[Enter new virtual host name]"
$WSLIP = wsl hostname -I # get IP address from WSL distro

$localDomain = $settings.localDomain
$htDocsRoot = $settings.htdocsRoot
$newVHost = $newHost + $localDomain
$newVHostLine = "$WSLIP`t$newVHost"
Add-Content $settings.hostsPath $newVHostLine
Write-Host "`n>> ✅ Added new virtual host: $newVHostLine$localDomain" -f green

# Extra XAMPP support
if ($settings.usingXampp -eq 1) {
    $vHostsFile = "/opt/lampp/etc/extra/httpd-vhosts.conf"
    $vHostString = @"

# $newHost$localDomain
<VirtualHost 127.0.0.3:80>
    DocumentRoot `"$htDocsRoot$newHost`"
    DirectoryIndex index.php
    
    <Directory `"$htDocsRoot$newHost`">
        Options All
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

"@
    Write-Host ">> Using XAMPP installation. Adding new virtual host to $vHostsFile`n" -f green
    Write-Host ">> Remember, you must enable virtual hosts support in '/opt/lampp/etc/httpd.conf' file by uncommenting 'Include etc/extra/httpd-vhosts.conf' line`n" -f yellow
    wsl sudo su -c "echo '$vHostString' >> $vHostsFile"
}

# Restart WSL session
.\modules\restart.ps1

Write-Host ">> ✅ Done!`n" -f green