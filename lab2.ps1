##############################################################
##Use this to login to your Azure account for the first time##
##############################################################

$login = Read-Host "Do you need to login Y/N"

if($login -eq "Y")
{
Login-AzureRmAccount
}

else
{
Write-Host "You are logged in already" -ForegroundColor Green
}

###############################################
##Checks for multi subscritptions selects one##
###############################################

$multisubs = Read-Host "Do you have multiple subscriptions Y/N"

if($multisubs -eq "Y")
{
Get-AzureRmSubscription | Out-GridView

$subscript = Read-Host "Enter the subscription you want to create these resources on"

Set-AzureRmContext -Subscription $subscript
}
else 
{
Write-Host "Are you sure you dont have multiple subscriptions? Press stop if you do!" -ForegroundColor Cyan
}

###################################################
##switch used to allow the selection of locations##
###################################################

Write-Host "
 1 for East Asia
 2 for Southeast Asia
 3 for Central US
 4 for East US
 5 for East US 2
 6 for West US
 7 for North Central US
 8 for South Central US
 9 for North Europe
10 for West Europe
11 for Japan West
12 for Japan East
13 for Brazil South
14 for Australia East
15 for Australia Southeast
16 for South India
17 for Central India
18 for West India
19 for Canada Central
20 for Canada East
21 for UK South
22 for UK West
23 for West Central US
24 for West US 2
25 for Korea Central
26 for Korea South"; $number = Read-Host "Enter the coresponding number to select your location"

switch($number)
{
1{$location = "eastasia"}
2{$location = "southeastasia"}
3{$location = "centralus"}
4{$location = "eastus"}
5{$location = "eastus2"}
6{$location = "westus"}
7{$location = "northcentralus"}
8{$location = "southcentralus"}
9{$location = "northeurope"}
10{$location = "westeurope"}
11{$location = "japanwest"}
12{$location = "japaneast"}
13{$location = "brazilsouth"}
14{$location = "australiaeast"}
15{$location = "australiasoutheast"}
16{$location = "southindia"}
17{$location = "centralindia"}
18{$location = "westindia"}
19{$location = "canadacentral"}
20{$location = "canadaeast"}
21{$location = "uksouth"}
22{$location = "ukwest"}
23{$location = "westcentralus"}
24{$location = "westus2"}
25{$location = "koreacentral"}
26{$location = "koreasouth"}
}

################################################
##switch allowing the selection of your images##
################################################

Write-Host "
 1 for CentOS
 2 for CoreOS
 3 for Debian
 4 for openSUSE-Leap
 5 for RHEL
 6 for SLES
 7 for UbuntuLTS
 8 for Win2016Datacenter
 9 for Win2012R2Datacenter
10 for Win2012Datacenter
11 for Win2008R2SP1"; $switchnum = Read-Host "Enter the coresponding number to select your image"

switch($switchnum)
{
1{$image = "CentOS"}
2{$image = "CoreOS"}
3{$image = "Debian"}
4{$image = "openSUSE-Leap"}
5{$image = "RHEL"}
6{$image = "SLES"}
7{$image = "UbuntuLTS"}
8{$image = "Win2016Datacenter"}
9{$image = "Win2012R2Datacenter"}
10{$image = "Win2012Datacenter"}
11{$image = "Win2008R2SP1"}
}

###########################################
##Variables to allow reuse of this script##
###########################################

$VMname = Read-Host "Enter the name you would like for your vm/s"

$MyVnet = Read-Host "Enter the name for your Virtual Network"

#$Subname = Read-Host "Enter your Subnet name"

$NSG = Read-Host "Enter your Network Security Group name"

#$PublicIP = Read-Host "Enter your public IP name"

$OpenPs = Read-Host "Enter the ports you want open if any 3389, 80 etc."

$OpenPs = [int32]$OpenPs

################################################################
##If statements to take care of some of the default selections##
################################################################

$IPDefault = Read-Host "Do you want to keep the default IP length Y/N"

if($IPDefault -eq "N")
{
$IPlength = Read-Host "Enter desired IP prefix length"
}
else
{
$IPlength = "192.168.0.0/16"
}

$DefaultSize = Read-Host "Do you want the Default machine size etc Standard_DS1_v2 Y/N"

if($DefaultSize -eq "N")
{
$Size = Read-Host "Enter the Virtual machine size default is Standard_DS1_v2"
}
else
{
$Size = "Standard_DS1_v2"
}

$DefaultSub = Read-Host "Do you want the Default value for your subnet length Y/N"

if($DefaultSub -eq "N")
{
$subnetprefix = Read-Host "Enter the prefix length for you would like for your subnet ensure it is smaller than your IP length"
}
else
{
$subnetprefix = "192.168.1.0/24"
}

####################################
##If you want a new resource group##
####################################

Get-AzureRmResourceGroup | Out-GridView

$resoure = Read-Host "Do you need a resource group Y/N"

if ($resoure -eq "Y")
{
$resname = Read-Host "Enter the name you would like for your resource group"

New-AzureRmResourceGroup -Name $resname -Location $location
}
else
{
$resname = Read-Host "Enter the name of the resource group you are creating this VM on"
}

########################
##New Availability set##
########################

$available = Read-Host "Do you need an Availability Set Y/N"

if($available -eq "Y")
{

$managed = Read-Host "Managed Y/N"

if($managed -eq "Y")
{
$availability = Read-Host "Enter availability set name"

$updatedomain = Read-Host "Enter your desired update domain count 5 is default max is 20"

New-AzureRmAvailabilitySet -ResourceGroupName $resname -Name $availability -Location $location -Managed -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount $updatedomain

}

else
{
$availability = Read-Host "Enter availability set name"

$updatedomain = Read-Host "Enter your desired update domain count 5 is default max is 20"

New-AzureRmAvailabilitySet -ResourceGroupName $resname -Name $availability -Location $location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount $updatedomain
}

}

else
{
Write-Host "You selected No availability set" -ForegroundColor Red
}

#################
##Create new VM##
#################

$t = 1

$number = Read-Host "Enter number of Vms you want"

$number = [int64]$number

while($t -ile $number)
{

New-AzureRmVM -ResourceGroupName $resname -Name $VMname$t -Location $location -VirtualNetworkName $MyVnet `
-SubnetName $MyVnet -SecurityGroupName $NSG -PublicIpAddressName $MyVnet$t -OpenPorts $OpenPs -ImageName $image `
-AvailabilitySetName $availability -AddressPrefix $IPlength -Size $Size -SubnetAddressPrefix $subnetprefix 

$t++
}