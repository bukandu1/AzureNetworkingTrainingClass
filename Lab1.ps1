$nsgName="Lab1-nsg"
$resourceGroupName="rgAzureNetworkingLEAP2"
$location="westus"

#check if we need to log in
$context =  Get-AzureRmContext
if ($context.Environment -eq $null) {
    Login-AzureRmAccount
}

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

#add NSG rule to allow port 80 inbound from anywhere
New-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -Location $location
$nsg=Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName | `
    Add-AzureRmNetworkSecurityRuleConfig -Name "Allow_Port_80" -Access `
    Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix * `
    -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 80 |`
    Set-AzureRmNetworkSecurityGroup 
$nsg=Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName | `
    Add-AzureRmNetworkSecurityRuleConfig -Name "Allow_RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389 | `
    Set-AzureRmNetworkSecurityGroup 


#VNETs
for ($i = 0; $i -lt 2; $i++) {
    $NetworkName = "VNET$($i)"
    $SubnetName = "Subnet1"
    $SubnetAddressPrefix = "10.0.0.0/24"
    $VnetAddressPrefix = "10.0.0.0/16"
    $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $Vnet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet

    ##add the NSG
    Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name $SubnetName -AddressPrefix $SubnetAddressPrefix -NetworkSecurityGroup $nsg
    Set-AzureRmVirtualNetwork -VirtualNetwork $Vnet
}

#credentials for all the VMs
$cred = Get-Credential -Message "Enter information for the local administrator on all VMs"

#create availability set for the load balanced VMs in VNET0
$as = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name "Lab1AvailabilitySet" -Location $location `
    -Sku aligned `
    -PlatformFaultDomainCount 2 `
    -PlatformUpdateDomainCount 2

##two VMs in VNET0
for ($i = 0; $i -lt 2; $i++) {

    #names, etc.
    $ComputerName = "Lab1VM$($i)"
    $VMName = "Lab1VM$($i)"
    $VMSize = "Standard_B2ms"
    $NICName = "Lab1VM$($i)-NIC"
    $PublicIPAddressName = "Lab1VM$($i)-PIP"

    $Vnet = Get-AzureRmVirtualNetwork -Name  "VNET0" -ResourceGroupName $resourceGroupName
    $PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic
    $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

    # Create a virtual machine configuration
    $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $as.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $VMName -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $NIC.Id

    #create the VM
    New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -vm $vmConfig -Verbose
}

##one VM in VNET1
#names, etc.
$ComputerName = "Lab1VM2"
$VMName = $ComputerName
$VMSize = "Standard_B2ms"
$NICName = "$($ComputerName)-NIC"
$PublicIPAddressName = "$($ComputerName)-PIP"

$Vnet = Get-AzureRmVirtualNetwork -Name  "VNET1" -ResourceGroupName $resourceGroupName
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $VMName -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
-Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $NIC.Id

#create the VM
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -Verbose

#install IIS on all three VMs
for ($i = 0; $i -lt 3; $i++) {
    $VMName = "Lab1VM$($i)"

    $commandBase = "powershell "
    $commandFirewall="New-NetFirewallRule -DisplayName ""Allow Inbound Port 80"" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow;"
    $commandIIS = "Add-WindowsFeature Web-Server;"
    $commandHTML = '$TargetFile=c:\inetpub\wwwroot\default.html;New-Item $TargetFile -Type File -Force;$htmltext=$env:COMPUTERNAME;$htmltext | Out-File $TargetFile;'
    $commandAll = ($commandBase + $commandFirewall + $commandIIS + $commandHTML) | ConvertTo-Json
    $command = "'{""commandToExecute"":$($commandAll)}'"

    ##call the custom script extension with the above commands
    Set-AzureRmVMExtension -ExtensionName "Lab1Prep" -ResourceGroupName $resourceGroupName -VMName $VMName `
        -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion 1.4 `
        -SettingString $command -Location $location
}

#create dummy html file
$TargetFile="c:\inetpub\wwwroot\default.html"
New-Item $TargetFile -Type File -Force
$htmltext=$env:COMPUTERNAME
$htmltext | Out-File $TargetFile

'{"commandToExecute":"powershell $TargetFile="c:\\inetpub\\wwwroot\\default.html";New-Item $TargetFile -Type File -Force;$htmltext=$env:COMPUTERNAME;$htmltext | Out-File $TargetFile;"}'
    

#allow HTTP traffic through the firewall
#New-NetFirewallRule -DisplayName "Allow Inbound Port 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow



#Add an ILB in VNET1 via the portal -> Choose unassociated
#Add an ELB in VNET1 via the portal

#Add Demo1 and Demo2 to the backend pool for ILB
