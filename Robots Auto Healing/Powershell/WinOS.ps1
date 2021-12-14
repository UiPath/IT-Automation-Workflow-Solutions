<#   
DESCRIPTION
     Retrieves the list of installed Windows updates and their details (version, install date, ..)

AUTHORS    
    .UIPATH
        Andrei Oros (Website: https://uipath.com/it-automation)
#>


$results = get-wmiobject -class win32_quickfixengineering | Select-Object HotFixID, Description, InstalledBy, InstalledOn | Sort-Object InstalledOn -Descending;
$outText = "";
foreach ($r in $results)
{
  if(! [string]::IsNullOrEmpty($r.HotFixID)) {
    $outText += $r.HotFixID+','+$r.InstalledOn+','+$r.InstalledBy+','+$r.Description+';';
  }
}
$outText.Substring(0,$outText.Length-1);