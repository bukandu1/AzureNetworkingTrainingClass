    $VMName = "Lab1VM4"
    $resourceGroupName="rgAzureNetworkingLEAP2"
$location="westus"

    $commandBase = "powershell " 
    $commandFirewall="New-NetFirewallRule -DisplayName 'Allow Inbound Port 80' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow;"
    $commandIIS = "Add-WindowsFeature Web-Server;"
    $commandHTML = '$TargetFile=c:\inetpub\wwwroot\default.html;New-Item $TargetFile -Type File -Force;$htmltext=$env:COMPUTERNAME;$htmltext | Out-File $TargetFile;'
    #$commandAll = ($commandBase + $commandFirewall + $commandIIS + $commandHTML) | ConvertTo-Json
    $commandAll = "$($commandBase)"
    $commandAll
    $command = '"{""commandToExecute"":" + "($($commandAll)) | ConvertTo-Json)" + "}"'
    ##$command = '{"commandToExecute":"powershell Add-WindowsFeature Web-Server"}'



    ##call the custom script extension with the above commands
    Set-AzureRmVMExtension -ExtensionName "Lab1Prep" -ResourceGroupName $resourceGroupName -VMName $VMName `
        -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion 1.4 `
        -SettingString $commandAll -Location $location


     #{"commandToExecute":"powershell Add-WindowsFeature Web-Server"}
     '{"commandToExecute":"powershell "}'
     '{"commandToExecute":"powershell Add-WindowsFeature Web-Server"}'
