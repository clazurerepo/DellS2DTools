<#
    .Synopsis
       ToolBox.ps1
    .DESCRIPTION
       This script is a menu to the other tools 
    .EXAMPLES
       Invoke-ToolBox
#>
Function EndScript{ 
    break
}

Function Invoke-ToolBox{
Clear-Host
$Ver=1.0
$text = @"
v$Ver
  _____         _   ___          
 |_   _|__  ___| | | _ ) _____ __
   | |/ _ \/ _ \ | | _ \/ _ \ \ /
   |_|\___/\___/_| |___/\___/_\_\
                                 
                      by: Jim Gandy 
"@
Function ShowMenu{
    do
     {

         $selection=""
         Clear-Host
         Write-Host $text
         Write-Host ""
         Write-Host "This code is provided as-is and is not supported by Dell Technologies"
         Write-Host ""
         Write-Host "==================== Please make a selection ====================="
         Write-Host ""
         Write-Host "Press '1' to BOILER       - Finds Windows Update Errors"
         Write-Host "Press '2' to DART         - Installs Dell/MS Updates"
         Write-Host "Press '3' to FLEP         - Filters Event Logs"
         Write-Host "Press '4' to FLCkr        - Looks up Mini Filter Drivers"
         Write-Host "Press '5' to LogCollector - Make log collection easier"
         Write-Host "Press '6' to DriFT        - Driver and Firmware Tool ***INTERNAL ONLY***"
         Write-Host "Press '7' to CluChk       - Cluster Checker ***INTERNAL ONLY***"
         Write-Host "Press 'H' to Display Help"
         Write-Host "Press 'Q' to Quit"
         Write-Host ""
         $selection = Read-Host "Please make a selection"
     }
    until ($selection -match '[1-7,qQ,hH]')
    $Global:WindowsUpdates=$False
    $Global:DriverandFirmware=$False
    $Global:Confirm=$False
    IF($selection -imatch 'h'){
        Clear-Host
        Write-Host ""
        Write-Host "What's New in"$Ver":"
        Write-Host $WhatsNew 
        Write-Host ""
        Write-Host "Useage:"
        Write-Host "    Make a select by entering a number from the menu."
        Write-Host ""
        Write-Host "        Example: 1 will run BOILER."
        Write-Host ""
        Pause
        ShowMenu
    }
    IF($selection -match 1){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="BOILER";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/BOILER.ps1'));Invoke-BOILER
    }
    IF($selection -match 2){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="DART";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/DART.ps1'));Invoke-DART
    }
    IF($selection -match 3){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="FLEP";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/FLEP.ps1'));Invoke-FLEP
    }
    IF($selection -match 4){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="FLCkr";$repo="PowershellScripts"'+(new-object System.net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/FLCkr.ps1'));Invoke-FLCkr
    }
    IF($selection -match 5){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="LogCollector";$repo="PowershellScripts"'+(new-object System.net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/LogCollector.ps1'));Invoke-LogCollector
    }
    IF($selection -match 6){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="RunDriFT";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/rundrift.ps1'));Invoke-RunDriFT
    }
    IF($selection -match 7){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="RunCluChk";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/RunCluChk.ps1'));Invoke-RunCluChk
    }

    IF($selection -imatch 'q'){
        Write-Host "Bye Bye..."
        EndScript
    }
}#End of ShowMenu
ShowMenu
}
