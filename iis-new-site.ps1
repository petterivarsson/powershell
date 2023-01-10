# This script adds site, app-pool, app-folder and host-entry for IIS
import-module WebAdministration

# CONFIG ####################
$sitename = "local-myapp.se"
$sitefolder = "C:\Projects\myapp";
$owerwritesite = "true"; # true/false
$poolname = "local-no-managed-code";
$hostfile = "C:\Windows\System32\drivers\etc\hosts";
$openhostfile = "false"; # true/false
# CONFIG ####################


# exit if user do not want to owervrite existing 
if ( (Test-Path IIS:\Sites\$sitename) -and ($owerwritesite -eq 'false') ) 
{ 
    Write-Host "$sitename already exists, change flag 'owerwritesite' if needed "
    return;
}

# application pool
Write-Host "Checking Application Pool";
if(-Not (Test-Path IIS:\AppPools\$poolname)) 
{
    #Remove-WebAppPool $sitename
    Write-Host "Making AppPool $poolname"
    $pool = New-WebAppPool -Name $poolname -Force 
    $pool.autoStart = "true"
    $pool.managedRuntimeVersion = "No Managed Code"    
}
Start-WebAppPool -Name $poolname

# app-folder
Write-Host "Checking sitefolder"
if(-Not (Test-Path $sitefolder ))
{
    Write-Host "Making $sitefolder"
    New-item -ItemType directory $sitefolder
}

# site
Write-Host "Making Site $sitename"
$site = New-WebSite -Force -Name $sitename -Port 80 -HostHeader $sitename -PhysicalPath $sitefolder -ApplicationPool $poolname 
Start-WebSite -Name $sitename

# host-file
Write-Host "Checking hostfile"
$el = Select-String -Path $hostfile -Pattern $sitename
if ($el.length -eq 0){
    Write-Host "Writing to host-file"
    Add-Content -Path $hostfile -Value "$([Environment]::NewLine)127.0.0.1   $sitename"
}

# browse to the site
Write-Host "Opening site"
Start-Process "http://$sitename"

# show the host-file
if($openhostfile -eq 'true'){
    Start-Process notepad $hostfile
}

Write-Host "DONE"
