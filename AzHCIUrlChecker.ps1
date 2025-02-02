<#
    .Synopsis
       AzHCIUrlChecker.ps1
    .DESCRIPTION
       This script checks the URLs that the Azure Stack HCI operating system may need to access
    .EXAMPLES
       Invoke-AzHCIUrlChecker
    .Author
       Jim Gandy
#>

Function Invoke-AzHCIUrlChecker{
$Ver="1.0"
Clear-Host
$text = @"
v$Ver
    _       _  _  ___ ___ _   _     _  ___ _           _           
   /_\   __| || |/ __|_ _| | | |_ _| |/ __| |_  ___ __| |_____ _ _ 
  / _ \ |_ / __ | (__ | || |_| | '_| | (__| ' \/ -_) _| / / -_) '_|
 /_/ \_\/__|_||_|\___|___|\___/|_| |_|\___|_||_\___\__|_\_\___|_|  
                               
                                                      by: Jim Gandy 
"@
Write-Host $text
Write-Host ""
Write-Host "This script checks the URLs that the Azure Stack HCI "
Write-Host "operating system may need to access as per Microsoft"
Write-Host "Doc: https://docs.microsoft.com/en-us/azure-stack/hci/concepts/firewall-requirements"
Write-Host ""
# Scrape MS KB from URLs
    $URL='https://raw.githubusercontent.com/MicrosoftDocs/azure-stack-docs/main/azure-stack/hci/concepts/firewall-requirements.md'
    $Webpage=Invoke-WebRequest -Uri $URL -UseBasicParsing -Method Get -ContentType 'charset=utf-8'
    if ($Webpage.statuscode -eq '200') {
        $Webpage.RawContent|Out-File $env:TEMP\temp1.txt -encoding utf8 -Force
        $readfile=Get-Content $env:TEMP\temp1.txt
        Remove-Item $env:TEMP\temp1.txt -Force
        $URLs=@()
        $UrlList=@()
        $URLs2Check=@()
        $Add=""
        foreach($Line in $readfile){
            $URL=""
            $Port=""
            $Notes=""
            IF($Line -imatch '```json'){$Add=$true}
            IF($Line -imatch '----'){$Add=$false}
            IF($Add -eq $true){
                $URLs+=$Line -replace [char]8220,'"' -replace [char]8221,'"' -replace '`' -replace 'json' -replace 'http\:\/\/' -replace 'https\:\/\/' -replace '\/' -replace'\*\.' -replace '\[\{','{' -replace '\}\]','},' -replace '\}\s\]','}'
            }
        }
    }Else{Write-Host "ERROR: Failed to get URL list from: $URL" -ForegroundColor Red }
    $URLs2Convert2Json=@('[')
    $i=0
    foreach($Url in $URLs){
        IF($Url -imatch '^\{'){
            $i++
            IF($i -gt 1){
                $Url=$Url -replace '^\{','{'
            }
        }
        $URLs2Convert2Json+=$Url
    }
    $URLs2Convert2Json+=']'
    $HCIURLs=$URLs2Convert2Json | Out-String | ConvertFrom-Json
    $URLs2Check=$HCIURLs | sort URL -Unique
    
# Check for running on cluster
IF(Get-Command Get-ClusterNode -ErrorAction SilentlyContinue -WarningAction SilentlyContinue){
    $ServerList = (Get-ClusterNode -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).Name
}
IF(-not($ServerList)){
    $ServerList=$env:COMPUTERNAME
}

#Change buffer width to make reader frindly
    $pshost = get-host
    $pswindow = $pshost.ui.rawui
    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $newsize.width = 1024
    $pswindow.buffersize = $newsize
    $newsize = $pswindow.windowsize

# Test connections
    foreach($Url in $URLs2Check) {
        Write-Host "Checking $($Url.URL)..."
        Invoke-Command -ComputerName $ServerList -WarningAction SilentlyContinue -ScriptBlock {
            $Result = Test-NetConnection -ComputerName ($Using:Url.URL) -Port ($Using:Url.Port) -ErrorAction SilentlyContinue
            If($Result.TcpTestSucceeded -eq $true) {Write-Host "PASSED: From $($env:COMPUTERNAME) to $($Using:Url.URL)" -ForegroundColor Green}
            If($Result.TcpTestSucceeded -eq $false) {Write-Host "FAILED: From $($env:COMPUTERNAME) to $($Using:Url.URL) INFO:$($Using:Url.Notes)" -ForegroundColor Red}
        }
    }
}
