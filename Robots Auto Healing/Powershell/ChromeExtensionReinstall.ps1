<#   
DESCRIPTION
    Adds the UiPath Google Chrome extension to the forced install list.
    Can be used for forcing installaiton of any Google Chrome extension.
    Takes existing extensions into account which might be added by other means, such as GPO and MDM.
    Assuming a maximum of possible installed extensions never exceeds a count of 20.

AUTHORS
    .ORIGINAL SCRIPT
        Martin Bengtsson (Blog: www.imab.dk, Twitter: @mwbengtsson)    
    .UIPATH ADAPTED
        Andrei Oros (Website: https://uipath.com/it-automation)
#>


# Function to enumerate registry values
Function Get-RegistryValues {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Push-Location
    Set-Location -Path $Path
    Get-Item . | Select-Object -ExpandProperty property | ForEach-Object {
        New-Object psobject -Property @{'Property'=$_;'Value' = (Get-ItemProperty -Path . -Name $_).$_}
    }
    Pop-Location
} 



Function Add-RegistryEntries {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$NewEntryValue
    )
    # Registry path for the ExtensionInstallForcelist
    $RegistryPath = $Path # "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    $KeyType = "String"

    # UiPath Chrome Extension
    $ExtensionID = $NewEntryValue # 'dkgencfabioofgdmhhjljpkbbchbikbh;https://clients2.google.com/service/update2/crx'


    # Registry path does not exist. Creating the path
    if (-not(Test-Path -Path $RegistryPath)) {
        Write-Host -ForegroundColor Red "Registry patch on $RegistryPath does not exist - trying to create it"
        try {
            New-Item -Path $RegistryPath -Force
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to create registry path"
        }
    }

    # Loop through the existing values and properties in the registry
    $InstalledExtensionsProperties = Get-RegistryValues -Path $RegistryPath | Select-Object Property
    $InstalledExtensions = Get-RegistryValues -Path $RegistryPath | Select-Object Value

    # Assuming that the list of forced extensions will never exceed a count of 20
    $Values = 1..20

    # If no registry key properties found, continue do something. No need to do something complicated, if no extensions exists already.
    if ($InstalledExtensionsProperties -ne $null) { 
    
        # Finding next available number for use in KeyName
        $NextNumber = Compare-Object $InstalledExtensionsProperties.Property $Values | Select-Object -First 1
        $KeyName = $NextNumber.InputObject
    
        # If the extension is not installed already, install it
        if ($InstalledExtensions -match $ExtensionID) {
            Write-Host -ForegroundColor Green "$ExtensionID is already added."
        
        }
        # else try to add the extension please
        else {
            Write-Host -ForegroundColor Red "The extenion $ExtensionID is not found. Adding it."
            try {
                New-ItemProperty -Path $RegistryPath -Name $KeyName -PropertyType $KeyType -Value $ExtensionID
            }
            catch {
                Write-Host -ForegroundColor Red "Failed to create registry key"   
            }    
        }
    }
    # Else just add the extension as the first extension
    else {
    
        Write-Host -ForegroundColor Red "No extensions already added. Adding the extensions as the first one"
        try {
            New-ItemProperty -Path $RegistryPath -Name 1 -PropertyType $KeyType -Value $ExtensionID
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to create registry key"   
        }
    }
}



# Stop  running Chrome instances
Stop-Process -Name 'Chrome' -Force -ErrorAction SilentlyContinue;

# Uninstall extension
cd 'C:\Program Files\UiPath\Studio\UiPath'; .\SetupExtensions.exe /chromecleanup /silent;


# Install extension from local sources
cd 'C:\Program Files\UiPath\Studio\UiPath'; .\SetupExtensions.exe /chromepolicyglobal /silent;
#cd 'C:\Program Files\UiPath\Studio\UiPath'; .\SetupExtensions.exe /chromeglobal /silent;



Write-Host "Processing ExtensionInstallForcelist..."
Add-RegistryEntries -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' -NewEntryValue 'dkgencfabioofgdmhhjljpkbbchbikbh;https://clients2.google.com/service/update2/crx'


#Write-Host "Processing NativeMessagingAllowlist..."
Add-RegistryEntries -Path "HKLM:\Software\Policies\Google\Chrome\NativeMessagingAllowlist" -NewEntryValue 'com.uipath.chromenativemsg_v2'


