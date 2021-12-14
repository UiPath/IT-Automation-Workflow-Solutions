<#   
DESCRIPTION
     Retrieves the list of installed Windows Applications and their details (version, install date, ..)

AUTHORS    
    .UIPATH
        Andrei Oros (Website: https://uipath.com/it-automation)
#>

$result = "";

$appsLM1 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallDate | Sort-Object Displayname;
$appsLM2 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallDate | Sort-Object Displayname;
$appsCU = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallDate | Sort-Object Displayname;

$apps = $appsLM1 + $appsLM2 + $appsCU;

foreach($a in $apps)
{
    if(![string]::IsNullOrEmpty($a.DisplayName)) {
        $result += $a.DisplayName + ',' + $a.DisplayVersion  + ',' + $a.InstallDate + ';';
    }
}

$result.Substring(0,$result.Length-1);