# This script adds site, app-pool, app-folder and host-entry for IIS
import-module WebAdministration

# CONFIG ####################
$appname = "local-web.mydomain.com"
$appfolder = "c:\repos\myproject";
$owerwriteApp = "true";
$poolname = "local-no-managed-code";
$hostfile = "C:\Windows\System32\drivers\etc\hosts";
# CONFIG ####################


# exit if user do not want to owervrite existing 
if ( (Test-Path IIS:\Sites\$appname) -and ($owerwriteApp -eq 'false') ) 
{ 
    Write-Host "$appname already exists, change flag 'owerwriteApp' if needed "
    return;
}

# application pool
Write-Host "Checking Application Pool";
if(-Not (Test-Path IIS:\AppPools\$poolname)) 
{
    #Remove-WebAppPool $appname
    Write-Host "Making AppPool $poolname"
    $pool = New-WebAppPool -Name $poolname -Force 
    $pool.autoStart = "true"
    $pool.managedRuntimeVersion = "No Managed Code"    
}

# app-folder
Write-Host "Checking appfolder"
if(-Not (Test-Path $appfolder ))
{
    Write-Host "Making $appfolder"
    New-item -ItemType directory $appfolder
}

# site
Write-Host "Making Site $appname"
$site = New-WebSite -Force -Name $appname -Port 80 -HostHeader $appname -PhysicalPath $appfolder -ApplicationPool $poolname 

# host-file
Write-Host "Checking hostfile"
$el = Select-String -Path $hostfile -Pattern $appname
if ($el.length -eq 0){
    Write-Host "Writing to host-file"
    Add-Content -Path $hostfile -Value "$([Environment]::NewLine)127.0.0.1   $appname"
}

# browse to the site and show the host-file
Write-Host "Opening site"
Start-Process "http://$appname"
Start-Process notepad $hostfile
Write-Host "DONE"
