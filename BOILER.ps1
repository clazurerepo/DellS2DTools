﻿  
<#
    .Synopsis
       BOILER.ps1
    .DESCRIPTION
       This script Filters the CBS/DISM logs for Errors/Fails/Warnings.
          Quickly identifies failing KB's, Language Tags or
          corruption and provides Suggested fixes 
    .EXAMPLES
       Invoke-BOILER
#>
Function Invoke-BOILER{
#region Opening Banner and menu
$Ver="1.0"
Clear-Host
$text = @"
v$Ver
  ___  ___ ___ _    ___ ___ 
 | _ )/ _ \_ _| |  | __| _ \
 | _ \ (_) | || |__| _||   /
 |___/\___/___|____|___|_|_\
                               
                      by: Jim Gandy 
"@
Write-Host $text
Write-Host ""
Write-Host "Filters the CBS/DISM logs for Errors/Fails/Warnings."
Write-Host "Quickly identifies failing KB's, Language Tags or"
Write-Host "corruption and provides Suggested fixes"
Write-Host ""
Do{$ReadyToRun = Read-Host "Ready to run? (Y/N)"}
until ($ReadyToRun -match '[yY,nN]')
IF($ReadyToRun -imatch 'n'){
        Write-Host "Bye Bye..."
        break script
    }
$Host.UI.RawUI.BufferSize.Width='192'
#Change buffer width to make reader frindly
    $pshost = get-host
    $pswindow = $pshost.ui.rawui
    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $newsize.width = 1024
    $pswindow.buffersize = $newsize
    $newsize = $pswindow.windowsize
Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{MultiSelect = $true}
    $OpenFileDialog.Title = "Please Select CBS/DISM Log File(s)."
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "Logs (*.zip,*.txt,*.log)| *.zip;*.TXT;*.log"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filenames
}

#region unzip files
        function Unzip
        {
            param([string]$zipfile, [string]$outpath)
            Write-Host "    Expanding: "
            Write-Host "      $zipfile "
            Write-Host "    To:"
            Write-Host "      $outpath"
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
        }
#Endregion end of unzip files

Write-Host "Please Select CBS/DISM Log File(s) to use..."
$CBSLogs=Get-FileName("$env:USERPROFILE\Documents\SRs")
$UnzipPath2Remove=@()
$LogsToProcess=@()
IF($CBSLogs -imatch '.zip'){
    $CBSLogsInZip=@()
    IF($CBSLogs.count -gt 1){
        ForEach($Zip in $CBSLogs){
            IF($Zip -imatch '.zip'){
                $UnzipPath=$Zip -replace ".zip"
                New-Item -ItemType Directory -Force -Path $UnzipPath
                Unzip $Zip $UnzipPath
                $CBSLogsInZip+=dir $UnzipPath -include ('*.log', '*.txt') -recurse
                $UnzipPath2Remove+=$UnzipPath
            }
        }
    }Else{
        ForEach($Zip in $CBSLogs){
            IF($Zip -imatch '.zip'){
                $UnzipPath=$($CBSLogs -replace ".zip")
                New-Item -ItemType Directory -Force -Path $UnzipPath
                Unzip $CBSLogs $UnzipPath
                $CBSLogsInZip = dir $UnzipPath -include ('*.log', '*.txt') -recurse
                $UnzipPath2Remove+=$UnzipPath
            }
        }
    }
    $LogsToProcess=$CBSLogsInZip
}
IF($CBSLogs -imatch '.log' -or $CBSLogs -imatch '.txt'){
    ForEach($Log in $CBSLogs){
       IF($Log -inotmatch '.zip'){
            $LogsToProcess+=$Log
       }
    }
}

$CBSLog=""
#Region $CBSLogs foreach
ForEach($CBSLog in $LogsToProcess){
    $BadKBs=@()
    $BadLangPacks=@()
    Write-Host "Processing: $CBSLog"
    $CBSErrors=Get-Content $CBSLog | Select-String -SimpleMatch "failed",", Error",", Warning" | Select LineNumber,line
    # known list of language tags
    $LangTags="ar-SA","bg-BG","ca-ES","cs-CZ","da-DK","de-DE","el-GR","en-GB","en-US","es-ES","es-MX","et-EE","eu-ES","fi-FI","fr-CA","fr-FR","gl-ES","he-IL","hr-HR","hu-HU","id-ID","it-IT","ja-JP","ko-KR","lt-LT","lv-LV","nb-NO","nl-NL","pl-PL","pt-BR","pt-PT","ro-RO","ru-RU","sk-SK","sl-SI","sr-Latn-CS","sr-Latn-RS","sv-SE","th-TH","tr-TR","uk-UA","vi-VN","zh-CN","zh-HK","zh-TW”
    $BadKBs=@()
    $BadLangPacks=@()
    $CBSErrorBadKBs=@()
    $CBSErrorBadLangTags=@()
    ForEach($CBSError in $CBSErrors){
        # check for bad KBs
        IF($CBSError -imatch "KB[0-9]{7}"){
            $BadKBs+=[regex]::match($($CBSError.line),"KB[0-9]{7}").Groups[0].Value 
            $CBSErrorBadKBs+=$CBSError
        }
        # Check for lang packs
        ForEach($LangTag in $LangTags){
            IF($CBSError -imatch $LangTag){
                $BadLangPacks+=[regex]::match($($CBSError.line),$LangTag).Groups[0].Value
                $CBSErrorBadLangTags+=$CBSError
            }
        }
    }
    IF($BadLangPacks){
        Write-Host ""
        ForEach($CBSErrorBadLangTag in $CBSErrorBadLangTags){
            Write-Host "    $($CBSErrorBadLangTag.LineNumber) $($CBSErrorBadLangTag.Line)" -BackgroundColor Red -ForegroundColor White
        }
        Write-Host ""
        Write-Host "        Failing Language Tag(s):"$($BadLangPacks|sort -Unique)
        Write-Host ""
        Write-Host "            Suggested Fix:"
        Write-host "                1. Download identified Language Tag(s) above"
        Write-Host "                2. DISM install identified Language Tag(s)"
        Write-host "                       Example: DISM /online /add-package /packagepath:c:\dell\x64fre_Server_ro-ro_lp.cab"
        Write-Host ""
    }
    $BadKBNumberLink=@()
    IF($BadKBs){
        $objKBList=@()
        ForEach($KB in $BadKBs | sort -Unique){
        # Seach for URI to retrieve the latest KB information
            $uri = "http://www.catalog.update.microsoft.com/Search.aspx?q=$KB"
            $kbPage = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction SilentlyContinue -UseDefaultCredentials
        # Extracting the KBGUID from the KBPage
            $KBGUID=$kbPage.links|Where-Object{$_.ID -match "_link"} | Where-Object{$_.outerHTML -match '_link' -and $_.outerHTML -match 'Windows Server'}|ForEach-Object{$_.id.replace('_link','')} 
        # Use the KBGUID to find the actual download link for the KB 
            $Post1='https://www.catalog.update.microsoft.com/DownloadDialog.aspx?updateIDs=[{%22size%22%3A0%2C%22languages%22%3A%22%22%2C%22uidInfo%22%3A%22'
            $post2='%22%2C%22updateID%22%3A%22'
            $post3='%22}]&updateIDsBlockedForImport=&wsusApiPresent=&contentImport=&sku=&serverName=&ssl=&portNumber=&version='
            $PostText=$post1+$kbGUID+$post2+$kbGUID+$post3
            $KBDLUriContent=(Invoke-WebRequest -Uri $PostText).content
            $KBDLUriSource=[regex]::matches( $KBDLUriContent,'downloadInformation\[0\].files\[0\].url\s\=.+').value -replace 'downloadInformation\[0\].files\[0\].url\s\=\s' -replace '\;' -replace"'"
            If($KBDLUriSource.Length -lt 1){$KBDLUriSource = "Link no longer available"}
            $objKB = New-Object PSObject 
            $objKB | Add-Member -MemberType NoteProperty -Name "            KBNumber" -Value $KB -PassThru | Add-Member -MemberType NoteProperty -Name "            KBDownloadLink" -Value $KBDLUriSource
            $objKBList +=$objKB
        }
        Write-Host ""
        ForEach($CBSErrorBadKB in $CBSErrorBadKBs){
            Write-Host "    $($CBSErrorBadKB.LineNumber) $($CBSErrorBadKB.Line)" -BackgroundColor Red -ForegroundColor White
        }
        ForEach($objkb in $objKBList){
            Write-Host ""
            Write-Host "        Failing KB(s):"
            $objkb | Format-List *
            IF($objkb -notmatch "Link no longer available"){
                Write-Host "           Suggested Fix: "
                Write-host "                1. Download KB with provided link above"
                Write-host '                2. Expand KB '
                Write-host '                       Example: expand "C:\Dell\windows10.0-kb4570332-x64_e6d793a79a9424f23feef4e4bcc00c5a883b78da.msu" . -F:*"'
                Write-host "                3. DISM install identified KB(s) "
                Write-host "                       Example: dism /online /add-package /packagepath:C:\Dell\Windows10.0-KB4570332-x64.cab"
                Write-host ""
            }ElseIF($objkb -match "Link no longer available"){
                Write-Host "            Suggested Fix: "
                Write-Host "                Remove KB from registry. See Josh's CBS reg cleaner script"
                Write-host ""
            }
        }
    }
    IF($CBSErrors){
        IF(-not($BadKBs -or $BadLangPacks)){
            Write-Host "    Error/Fail/Warning List:"
            ForEach($CBSError in $CBSErrors){
                IF($CBSError -imatch 'corrupt'){Write-Host "        $($CBSError.LineNumber) $($CBSError.Line)" -BackgroundColor Red -ForegroundColor White}
                Else{Write-Host "        $($CBSError.LineNumber) $($CBSError.Line)"}
            }
            IF($CBSErrors -imatch 'corrupt'){
                Write-Host ""
                Write-Host "        Found: Corruption"
                Write-Host ""
                Write-Host "        Suggested Fix: "
                Write-host "            Restore health with eval ISO"
		        Write-host "                1. Download eval ISO"
                Write-host "                2. Mount ISO"
                Write-host "                3. Copy the install.wim to C:\dell"
                Write-host "                4. DISM /online /cleanup-image /restorehealth /source:WIM:C:\Dell\install.wim:2 /limitaccess"
                Write-host "                5. SFC /Scannow"
                Write-host ""
            }
        }
    }Else{Write-Host "    No Error/Warning found" -ForegroundColor Green}
    Write-Host ""
 } #endregion $CBSLogs foreach
   
 # Cleanup expanded zips            
 IF($UnzipPath2Remove.Count -gt 0){Remove-Item $UnzipPath2Remove -Recurse}
 }