Import-Module '480-utils' -Force

# Devin Code
480Banner
$conf = Get-480Config -config_path "/home/jnicholls/SYS-480-Advanced-DevOps/Milestone-5/480.json"
480Connect -server $conf.vcenter_server
#Write-Host "Selecting your VM"
#Select-VM -folder "BASE"
$selected_vm = Select-VM -folder $conf.vm_folder
cloneVM $conf $selected_vm
#New-Network $conf
#Set-Network

#Get-IP (Read-Host "Enter VM name")

#ChangeState

# Connect
#connectVCenter -server $config.vcenter_server

# Linked Clone
#$newname = Read-Host "Enter new base name for VMs"
#foreach ($i in 1..2) 
#    {
#    $newvm = New-VM -LinkedClone -Name "$newname-0$i" -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false
#    $newvm | New-Snapshot -Name $snapshot
#    }
