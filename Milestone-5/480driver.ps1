Import-Module '480-utils' -Force

480Banner
$conf = Get-480Config -config_path = "/home/jnicholls/SYS-480-Advanced-DevOps/Milestone-5/480.json"
480Connect -server $conf.vcenter_server
Write-Host "Selecting your VM"
Select-VM -folder "BASE"