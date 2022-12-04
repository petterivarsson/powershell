# This script adds site, app-pool, app-folder and host-entry for IIS

# CONFIG ####################
$appname = "local-web.mydomain.com"
$appfolder = "c:\repos\myproject";
$owerwritexisting = "true";
# CONFIG ####################


import-module WebAdministration
Write-Host $appname
Write-Host $appfolder

# exit if user do not want to owervrite existing
if ( (Test-Path IIS:\Sites\$($appname)) -and ($owerwritexisting -eq 'false') ) { 
    
    Write-Host "$appname already exists, change flag 'owerwritexisting' if needed "
    return
}

# app-pool
if(Test-Path IIS:\AppPools\$($appname))
{
    Remove-WebAppPool $appname
}
Write-Host "Making AppPool"
$pool = New-WebAppPool -Name $appname -Force 
$pool.autoStart = "true"
$pool.managedRuntimeVersion = "No Managed Code"

# app-folder
Write-Host "Checking appfolder"
if(-Not (Test-Path $appfolder ))
{
    Write-Host "Making $appfolder"
    New-item –itemtype directory $appfolder
}

# site
Write-Host "Making Site"
$site = New-WebSite -Force -Name $appname -Port 80 -HostHeader $appname -PhysicalPath $appfolder -ApplicationPool $appname 

# host-file
Write-Host "Checking hostfile"
$el = Select-String -Path C:\Windows\System32\drivers\etc\hosts -Pattern $appname
if ($el.length -eq 0){
    Write-Host "Writing to host-file"
    Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$([Environment]::NewLine)127.0.0.1   $appname"
}

# browse to the site
Write-Host "Opening site"
Start-Process "http://$appname"

Write-Host "DONE"
