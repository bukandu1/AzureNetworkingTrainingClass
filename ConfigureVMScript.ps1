#Add firewall rule for port 80
New-NetFirewallRule -DisplayName "Allow Inbound Port 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

#Install IIS
Add-WindowsFeature Web-Server

#Create our HTML file for load balancing demonstration
$env:COMPUTERNAME | Out-File c:\inetpub\wwwroot\default.html -Force