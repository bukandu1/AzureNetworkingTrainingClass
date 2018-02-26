$resourceGroupName="rgAzureNetworkingLEAP2"
$location="westus"

$context =  Get-AzureRmContext
if ($context.Environment -eq $null) {
    Login-AzureRmAccount
}

for ($i = 0; $i -lt 3; $i++) {
    $VMName = "Lab1VM$($i)"

   ##call the custom script extension to configure the VMs
   Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroupName `
    -VMName $VMName `
    -Location $location `
    -FileUri https://raw.githubusercontent.com/EvanBasalik/AzureNetworkingTrainingClass/master/ConfigureVMScript.ps1 `
    -Run 'ConfigureVMScript.ps1' `
    -Name "Lab1Prep"
}

