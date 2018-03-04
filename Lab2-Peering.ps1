$resourceGroupName="rgAzureNetworkingLEAP"

#check if we need to log in
$context =  Get-AzureRmContext
if ($context.Environment -eq $null) {
    Login-AzureRmAccount
}

#Grab both VNETs
Write-Host "Grabbing pointers to both VNETs..." -ForegroundColor Yellow
$vnet0 = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name VNET0
$vnet1 = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name VNET1

# Peer VNet0 to VNet1
Write-Host "Adding peering to VNET0..." -ForegroundColor Yellow
Add-AzureRmVirtualNetworkPeering -Name 'Lab2V0toV1Peering' -VirtualNetwork $vnet0 -RemoteVirtualNetworkId $vnet1.Id
Write-Host "Added peering to VNET0..." -ForegroundColor Green

# Peer VNet2 to VNet1
Write-Host "Adding peering to VNET1..." -ForegroundColor Yellow
Add-AzureRmVirtualNetworkPeering -Name 'Lab2V1toV0Peering' -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet0.Id
Write-Host "Added peering to VNET1..." -ForegroundColor Green

for ($i = 0; $i -lt 2; $i++) {
	Get-AzureRmVirtualNetworkPeering -ResourceGroupName $resourceGroupName -VirtualNetworkName "vnet$($i)" `
		| Format-Table VirtualNetworkName, PeeringState
}