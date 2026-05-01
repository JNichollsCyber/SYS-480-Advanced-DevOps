function 480Banner()
{
    Write-Host "
       ___   ___      __          ____    
      / / | / (_)____/ /_  ____  / / /____
 __  / /  |/ / / ___/ __ \/ __ \/ / / ___/
/ /_/ / /|  / / /__/ / / / /_/ / / (__  ) 
\____/_/ |_/_/\___/_/ /_/\____/_/_/____/  
                                          
"
}
Function 480Connect([string] $server)
{
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn

        Write-Host -ForegroundColor Green $msg
    }else
    {
        $conn = Connect-VIServer -Server $server   
    }
}
Function Get-480Config([string] $config_path)
{
    Write-Host "Reading " $config_path
    $conf=$null
    if(Test-Path $config_path)
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor "Green" $msg
    } else
    {
        Write-Host -ForegroundColor "Yellow" "No Configurations"
    }
    return $conf
}
Function Select-VM([string] $folder)
{
    $selected_vm=$null
    try
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        $selected_vm = $vms[$pick_index -1]
        Write-Host "You picked " $selected_vm.name
        return $selected_vm
    }
    catch
    {
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"
    }
}
function cloneVM($conf, $selected_vm)
{
    $newname = Read-Host "Enter name for new vm"
    try {
        Get-VM -name $newname -ErrorAction Stop | Out-Null
        Write-Host "---------------------------"
        Write-Host "ERROR: VM '$newname' already exists" -ForegroundColor Yellow
        Write-Host "Select Different Name"
        Write-Host "---------------------------"
    }
    catch {
        Write-Host $selected_vm
        $vm = $selected_vm
        $snapshot = Get-Snapshot -VM $vm -Name $conf.snapshot | Select-Object -First 1
        $vmhost = Get-VMHost -name $conf.esxi_host
        $ds = Get-Datastore -name $conf.datastore
        $vmnetwork = $conf.default_network

        Write-Host "The following will be used"
        Write-Host "---------------------------"
        Write-Host "Base VM: $vm"
        Write-Host "Base Snapshot: $snapshot"
        Write-Host "ESXi Host: $vmhost"
        Write-Host "Datastore: $ds"
        Write-Host "New VM Name: $newname"
        Write-Host "Network: $vmnetwork"
        Write-Host "---------------------------"
        $checking = Read-Host "Please Select Deployment Type: [F]ull Clone, [L]inked Clone, or [Q]uit"

        if ($checking.Trim().Substring(0,1).ToUpper() -eq "F") {
            Write-Host "---------------------------"
            $check_again = Read-Host "Confirm VM Deployment? (Y/N)"
            if ($check_again.Substring(0,1).ToUpper() -eq "Y")
                {
                $newvm = New-VM -Name "$newname" -VM $vm -VMHost $vmhost
                $newvm | New-Snapshot -Name "base"
                }
            else {
                Write-Host "Aborting" -ForegroundColor Yellow
            }}
        elseif ($checking.Trim().Substring(0,1).ToUpper() -eq "L"){
            Write-Host "---------------------------"
            $check_again = Read-Host "Confirm Deployment (Y/N)"
            if ($check_again.Substring(0,1).ToUpper() -eq "Y")
            {
                $newvm = New-VM -LinkedClone -Name "$newname" -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false
                $newvm | New-Snapshot -Name "base"
            }
            else {
                Write-Host "Aborting" -ForegroundColor Yellow
            }
        }else {
            Write-Host "Aborting" -ForegroundColor Yellow
        }
    }
}
function New-Network([PSCustomObject]$config){
    $netname = Read-Host "Enter network name"
    $vmhost = Get-VMHost -Name $config.esxi_host

    # Port Group
    try {
        New-VirtualSwitch -VMHost "$vmhost" -Name "$netname-vswitch" -ErrorAction Stop | Out-Null
        $vswitch = Get-VirtualSwitch -VMHost $vmhost -Name "$netname-vswitch"
        Write-Host "'$netname-vswitch' successfully deployed" -ForegroundColor Yellow
    } 
    catch {
        Write-Host "'$netname-vswitch' already exists" -ForegroundColor Yellow
    }

    try {
        New-VirtualPortGroup -VirtualSwitch $vswitch -Name "$netname-LAN" -ErrorAction Stop | Out-Null

        Write-Host "'$netname-LAN' successfully deployed" -ForegroundColor Yellow
    }
    catch {
         Write-Host "'$netname-LAN' already exists" -ForegroundColor Yellow
    }
}   

function Get-IP([String]$vm) {
    $mac = (Get-VM -Name $vm | Get-NetworkAdapter)[0].MacAddress
    $getnet = Get-VM -Name $vm

    Write-Host "Grabbing IP and MAC Address for: '$vm'" -ForegroundColor Yellow
    Write-Host "---------------------------"

    #IP
    Write-Host "IP: " $getnet.Guest.IPAddress[0]

    #MAC
    Write-Host "MAC: " $mac
}
function ChangeState() {
    
    #Select VM to Change Power State
    Write-Host "Select VM to Power On/Off"
    $index = 1
    $vmlist = Get-VM

    foreach($i in $vmlist) {
        Write-Host "[$($index)] $($i.Name)"
        $index += 1
    }

    $select = Read-Host "Enter Index Number"

    if ($select -in 1..$vmlist.count) {
        $selected_vm = $vmlist[$select -1].Name
        Write-Host "VM '$selected_vm' was selected" -ForegroundColor Yellow
    } else {
        Write-Host "Index not in range, Select and option in the range" -ForegroundColor Yellow
        return
    }
    #Change Power State
    $vmstate = (Get-VM -Name "$selected_vm").PowerState
    Write-Host "Current power state of VM '$selected_vm': $vmstate"
    $setState = Read-Host "Are you turning the VM On or Off (on/off)"

    if ($setState -ilike "on") {
        if ($vmstate -eq "PoweredOn") {
            Write-Host "VM '$selected_vm' is already Powered On" -ForegroundColor Yellow
        } else {
            Write-Host "Powering On VM..." -ForegroundColor Yellow
            Start-VM -VM $selected_vm -RunAsync -Confirm:$true
            Write-Host "VM is now Powered On" -ForegroundColor Green
        }
    } elseif ($setState -ilike "off") {
        if ($vmstate -eq "PoweredOff") {
            Write-Host "VM '$selectedVM' is already Powered Off" -ForegroundColor Yellow
        } else {
            Write-Host "Powering Off VM..." -ForegroundColor Yellow
            Stop-VM -VM $selected_vm -RunAsync -Confirm:$true
            Write-Host "VM is now Powered Off" -ForegroundColor Green
        }
    } else {
        Write-Host "Not a Valid Option, Select Again" -ForegroundColor Yellow
    }
}

function Set-Network () {
    Write-Host "Select VM to configure network"
    $index = 1
    $vms = Get-VM

    foreach($i in $vms) {
        Write-Host "[$($index)] $($i.Name)"
        $index += 1
    }

    $select = Read-Host "Enter Number Here: "

    if ($select -in 1..$vms.count) {
        $selected_vm = $vms[$select -1].Name
        Write-Host "'$selected_vm' was chosen" -ForegroundColor Yellow
    } else {
        Write-Host "Invalid Option, Select Again" -ForegroundColor Yellow
        return
    }

    #Show Available Adapters
    Write-Host "Select a Net Adapter on 'selected_vm'"
    $index2 = 1
    $net_adapt = Get-VM -Name $selected_vm | Get-NetworkAdapter

    foreach($iface in $net_adapt) {
        Write-Host "[$($index2)] $($iface.Name)"
        $index2 += 1
    }

    $select2 = Read-Host "Enter Index Number Here"

     if ($select2 -in 1..$net_adapt.count) {
        $config_adapt = $net_adapt[$select2 -1]
        Write-Host "Interface '$($config_adapt.Name)' was selected" -ForegroundColor Yellow
     } else {
        Write-Host "Invalid Option, Select Again" -ForegroundColor Yellow
        return
     }

     Write-Host "Select a network to assign to adapter"

     $index3 = 1
     $networks = Get-VirtualNetwork

     foreach ($network in $networks) {
        Write-Host "[$($index3)] $($network.Name)"
        $index3 += 1
     }

     $select3 = Read-Host "Enter Index Number"

     if ($select3 -in 1..$networks.count) {
        $networkSelection = $networks[$select3 -1].Name
        Write-Host "'$networkSelection' was selected" -ForegroundColor Yellow
        Write-Host "Configuring Network Adapter..."
        Set-NetworkAdapter -NetworkAdapter $config_adapt -NetworkName "$networkSelection" -Confirm:$true
     } else {
        Write-Host "Invalid Option, Select Again" -ForegroundColor Yellow
        return
     }
}