$resourceGroupName="rgAzureNetworkingLEAP"
$location="westus"
$GWSubName = "GatewaySubnet"
$GWSubPrefix = "10.1.1.0/27"
$VNetName = "VNET1"
$GWIPName = "GW-IP"
$GWIPconfName = "gwipconf"
$GWName = "VNet1GW"
$VPNClientAddressPool = "172.16.201.0/24"
$P2SRootCertName = "P2SRootCert.cer"

#check if we need to log in
$context =  Get-AzureRmContext
if ($context.Environment -eq $null) {
    Login-AzureRmAccount
}

#create the GW subnet
$vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $resourceGroupName
Add-AzureRmVirtualNetworkSubnetConfig -Name $GWSubName -VirtualNetwork $vnet -AddressPrefix $GWSubPrefix
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

#grab a reference to the subnet we just created
$subnet = (Get-AzureRmVirtualNetwork -Name $vnet.Name -ResourceGroupName $resourceGroupName).Subnets `
	| Where-Object {$_.Name -eq $GWSubName}

#need a PIP for the gateway
$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $resourceGroupName -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip

#create the VNET gateway
New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $resourceGroupName `
	-Location $Location -IpConfigurations $ipconf -GatewayType Vpn `
	-VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientProtocol "IKEV2"

#create the client IP pool
$Gateway = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $resourceGroupName -Name $GWName
Set-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VPNClientAddressPool

#Create a self-signed root certificate for the gateway
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
	-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
	-HashAlgorithm sha256 -KeyLength 2048 `
	-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

#Generate a client certificate for the clients to present to the gateway
New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
	-Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
	-HashAlgorithm sha256 -KeyLength 2048 `
	-CertStoreLocation "Cert:\CurrentUser\My" `
	-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

#Export the certificate without the private key into a base-64 encoded CER
$OUTPUT= [System.Windows.Forms.MessageBox]::Show("Export the Root certificate to C:\cert\ without the private key into a base-64 encoded CER. Click OK when done." , `
    "Wait for certificate export" , [System.Windows.Forms.MessageBoxButtons]::OK)

#upload the certificate to the gateway
$filePathForCert = "C:\cert\P2SRootCert.cer"
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
Add-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName $P2SRootCertName `
	-VirtualNetworkGatewayname $GWName -ResourceGroupName $resourceGroupName -PublicCertData $CertBase64

#download the P2S client files
$profile=New-AzureRmVpnClientConfiguration -ResourceGroupName $resourceGroupName -Name $GWName -AuthenticationMethod "EapTls"
$url = $profile.VPNProfileSASUrl
$output = "vpnclientconfiguration.zip"
$wc=New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)

