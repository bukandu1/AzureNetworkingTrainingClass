for ($i = 0; $i -lt 100; $i++) {
    Write-Host "Attempt $($i)"

    #$targetIP = "40.112.151.80"
    #$targetIP = "rgazurenetworkingleap.trafficmanager.net"
    $url= "http://$($targetIP)/default.html"

    $html = ""
    $html = Invoke-WebRequest -Uri $url -DisableKeepAlive
    $htmlbytes1 = [System.Text.Encoding]::ASCII.GetBytes($html.Content)
    $htmlbytes2 = [System.Text.Encoding]::Convert([System.Text.Encoding]::Unicode, [System.Text.Encoding]::ASCII, $htmlbytes1)
    $chars = New-Object char[] 100
    $out = [System.Text.Encoding]::ASCII.GetChars($htmlbytes2, 0, $htmlbytes2.Length, $chars, 0)
    $html = [System.String]::new($chars)


    if ($html -like "*VM0*")
    {
        write-host $html -ForegroundColor Green
    }

    if ($html -like "*VM1*")
    {
        write-host $html -ForegroundColor Yellow
    }

    if ($html -like "*VM2*")
    {
        write-host $html -ForegroundColor Blue
    }

    Start-Sleep -Seconds 2
}