# Connect to vSphere Server

$server = "vcenter01.james.local"
Connect-VIServer($server)

# Source VM Info

$vm=Get-VM -Name "MGMT01-JNicholls"
$snapshot = Get-Snapshot -VM $vm -Name "base"
$vmhost = Get-VMHost -Name "192.168.3.229"
$ds = Get-Datastore datastore2-super29
$linkedname = "{0}.linked" -f $vm.name

# Create temp VM

$linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false

# Create Full VM from temp

$newvm = New-VM -Name "BASE-MGMT" -VM $linkedvm -VMHost $vmhost -Datastore $ds -Confirm:$false

# Snapshot for new VM

$newvm | New-Snapshot -Name 'base'

# Cleanup temp linked clone VM

Get-VM $linkedname | Remove-VM -Confirm:$false
