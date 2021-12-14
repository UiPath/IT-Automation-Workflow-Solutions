<#   
DESCRIPTION
     Retrieves the list of installed Windows updates and their details (version, install date, ..)

AUTHORS    
    .UIPATH
        Andrei Oros (Website: https://uipath.com/it-automation)
#>

$s = Get-Service -Name 'UiRobotSvc' -ErrorAction SilentlyContinue;
if($s -ne $null)
{
    if($s.Status -eq 'Running')
    {
        # Restart not necessary
        'Running';
    }
    else 
    {
        # Service is stopped, restart necessary, returning True
        Start-Service -Name 'UiRobotSvc' -ErrorAction SilentlyContinue | Out-null;
        
        # Check if restart was successful
        $s = Get-Service -Name 'UiRobotSvc' -ErrorAction SilentlyContinue;
        if($s.Status -eq 'Running')
        {  
            'Restarted';
        }
        else 
        {
            'RestartFailed';
        }    
    }
}
else
{
    'NotFound';
}