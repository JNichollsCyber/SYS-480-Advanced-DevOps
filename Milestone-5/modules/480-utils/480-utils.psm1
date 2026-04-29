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