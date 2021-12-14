<#   
DESCRIPTION
     Retrieves performance counters (cpu, memory, free space on C:\ drive)

AUTHORS    
    .UIPATH
        Andrei Oros (Website: https://uipath.com/it-automation)
#>

$server = $env:computername;
$disksResult = '';
$cpuResult = '';
$ramResult = '';


$drives=Get-WmiObject Win32_LogicalDisk -ComputerName $server;
foreach ($drive in $drives)
{
            
    $drivename=$drive.DeviceID -split ':';
    if($drivename -eq 'C'){
        $freespace=[int]($drive.FreeSpace/1GB);
        $totalspace = [int]($drive.Size/1GB);
        $usedspace = $totalspace - $freespace;
        $disksResult = $drivename+'('+$freespace + '/' + $totalspace+'GB free)';
        $disksResultForParsing = $freespace;
        break;
    }
}

$cpu=Get-WmiObject Win32_Processor -ComputerName $server;
$cpuResult = $cpu.LoadPercentage;

$ComputerMemory = Get-WmiObject -ComputerName $server -Class win32_operatingsystem -ErrorAction Stop;
$Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize);
$ramResult = [math]::Round($Memory, 0);

$output = "`nServer: "+$server+"`nCPU usage: %"+$cpuResult+"`nMemory usage: %"+$ramResult+"`nDisks usage: "+$disksResult+"`n"
$output

$outputForParsing = $cpuResult.ToString()+','+$ramResult.ToString()+','+$disksResultForParsing.ToString();
$outputForParsing;