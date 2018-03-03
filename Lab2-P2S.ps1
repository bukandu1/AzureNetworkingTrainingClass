$resourceGroupName="rgAzureNetworkingLEAP"
$location="westus"
$GWSubName = "GatewaySubnet"
$GWSubPrefix = "10.1.0.0/27"
$VNetName = "VNET1"
$GWIPName = "GW-IP"
$GWIPconfName = "gwipconf"
$GWName = "VNet1GW"

#check if we need to log in
$context =  Get-AzureRmContext
if ($context.Environment -eq $null) {
    Login-AzureRmAccount
}

#create the GW subnet
$gwsub = New-AzureRmVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix
$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $resourceGroupName
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $gwsub.Name -VirtualNetwork $vnet

#need a PIP for the gateway
$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $resourceGroupName -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip

#create the VNET gateway
New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $resourceGroupName `
	-Location $Location -IpConfigurations $ipconf -GatewayType Vpn `
	-VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientProtocol "IKEv2, SSTP"

#create the client IP pool
$Gateway = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $resourceGroupName -Name $GWName
Set-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VPNClientAddressPool