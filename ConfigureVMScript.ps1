#Add firewall rule for port 80
New-NetFirewallRule -DisplayName "Allow Inbound Port 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

#Install IIS
Add-WindowsFeature Web-Server

#Create our HTML file for load balancing demonstration
$env:COMPUTERNAME | Out-File c:\inetpub\wwwroot\default.html -Force

#Disable IE enhanced security configuration
#courtesy of https://sharepointryan.com/2011/06/23/disable-ie-enhanced-security-configuration-esc-using-powershell/
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer