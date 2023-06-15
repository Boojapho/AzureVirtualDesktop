[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $AmdVmSize,

    [parameter(Mandatory)]
    [string]
    $DomainName,

    [parameter(Mandatory)]
    [string]
    $DomainServices,

    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $Fslogix,

    [parameter(Mandatory)]
    [string]
    $FslogixSolution,

    [parameter(Mandatory)]
    [string]
    $HostPoolName,

    [parameter(Mandatory)]
    [string]
    $HostPoolRegistrationToken,    

    [parameter(Mandatory)]
    [string]
    $ImageOffer,
    
    [parameter(Mandatory)]
    [string]
    $ImagePublisher,

    [parameter(Mandatory)]
    [string]
    $NetAppFileShares,

    [parameter(Mandatory)]
    [string]
    $NvidiaVmSize,

    [parameter(Mandatory)]
    [string]
    $PooledHostPool,

    [parameter(Mandatory)]
    [string]
    $ScreenCaptureProtection,

    [parameter(Mandatory)]
    [string]
    $Sentinel,

    [parameter(Mandatory)]
    [string]
    $SentinelWorkspaceId,

    [parameter(Mandatory)]
    [string]
    $SentinelWorkspaceKey,

    [parameter(Mandatory)]
    [string]
    $StorageAccountPrefix,

    [parameter(Mandatory)]
    [int]
    $StorageCount,

    [parameter(Mandatory)]
    [int]
    $StorageIndex,

    [parameter(Mandatory)]
    [string]
    $StorageSolution,

    [parameter(Mandatory)]
    [string]
    $StorageSuffix   
)


##############################################################
#  Functions
##############################################################
function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}


function Get-WebFile
{
    param(
        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [string]$URL
    )
    $Counter = 0
    do
    {
        Invoke-WebRequest -Uri $URL -OutFile $FileName -ErrorAction 'SilentlyContinue'
        if($Counter -gt 0)
        {
            Start-Sleep -Seconds 30
        }
        $Counter++
    }
    until((Test-Path $FileName) -or $Counter -eq 9)
}


$ErrorActionPreference = 'Stop'


try 
{
    # Convert NetAppFiles share names from a JSON array to a PowerShell array
    [array]$NetAppFileShares = $NetAppFileShares.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "Azure NetApp Files, Shares:" -Type 'INFO'
    $NetAppFileShares | Add-Content -Path 'C:\cse.txt' -Force


    ##############################################################
    #  Run the Virtual Desktop Optimization Tool (VDOT)
    ##############################################################
    # https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
    if($ImagePublisher -eq 'MicrosoftWindowsDesktop' -and $ImageOffer -ne 'windows-7')
    {
        # Download VDOT
        $URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
        $ZIP = 'VDOT.zip'
        Invoke-WebRequest -Uri $URL -OutFile $ZIP
        
        # Extract VDOT from ZIP archive
        Expand-Archive -LiteralPath $ZIP -Force
        
        # Fix to disable AppX Packages
        # As of 2/8/22, all AppX Packages are enabled by default
        $Files = (Get-ChildItem -Path .\VDOT\Virtual-Desktop-Optimization-Tool-main -File -Recurse -Filter "AppxPackages.json").FullName
        foreach($File in $Files)
        {
            $Content = Get-Content -Path $File
            $Settings = $Content | ConvertFrom-Json
            $NewSettings = @()
            foreach($Setting in $Settings)
            {
                $NewSettings += [pscustomobject][ordered]@{
                    AppxPackage = $Setting.AppxPackage
                    VDIState = 'Disabled'
                    URL = $Setting.URL
                    Description = $Setting.Description
                }
            }

            $JSON = $NewSettings | ConvertTo-Json
            $JSON | Out-File -FilePath $File -Force
        }

        # Run VDOT
        & .\VDOT\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations 'AppxPackages','Autologgers','DefaultUserSettings','LGPO','NetworkOptimizations','ScheduledTasks','Services','WindowsMediaPlayer' -AdvancedOptimizations 'Edge','RemoveLegacyIE' -AcceptEULA


        Write-Log -Message 'Optimized the operating system using VDOT' -Type 'INFO'
    }

    ##############################################################
    #  Add Recommended AVD Settings
    ##############################################################
    $Settings = @(

        # Disable Automatic Updates: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
        [PSCustomObject]@{
            Name = 'NoAutoUpdate'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
            PropertyType = 'DWord'
            Value = 1
        },

        # Enable Time Zone Redirection: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
        [PSCustomObject]@{
            Name = 'fEnableTimeZoneRedirection'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )


    ##############################################################
    #  Add GPU Settings
    ##############################################################
    # This setting applies to the VM Size's recommended for AVD with a GPU
    if ($AmdVmSize -eq 'true' -or $NvidiaVmSize -eq 'true') 
    {
        $Settings += @(

            # Configure GPU-accelerated app rendering: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-app-rendering
            [PSCustomObject]@{
                Name = 'bEnumerateHWBeforeSW'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                PropertyType = 'DWord'
                Value = 1
            },

            # Configure fullscreen video encoding: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-fullscreen-video-encoding
            [PSCustomObject]@{
                Name = 'AVC444ModePreferred'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                PropertyType = 'DWord'
                Value = 1
            }
        )
    }

    # This setting applies only to VM Size's recommended for AVD with a Nvidia GPU
    if($NvidiaVmSize -eq 'true')
    {
        $Settings += @(

            # Configure GPU-accelerated frame encoding: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-frame-encoding
            [PSCustomObject]@{
                Name = 'AVChardwareEncodePreferred'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                PropertyType = 'DWord'
                Value = 1
            }
        )
    }


    ##############################################################
    #  Add Screen Capture Protection Setting
    ##############################################################
    if($ScreenCaptureProtection -eq 'true')
    {
        $Settings += @(

            # Enable Screen Capture Protection: https://learn.microsoft.com/azure/virtual-desktop/screen-capture-protection
            [PSCustomObject]@{
                Name = 'fEnableScreenCaptureProtect'
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                PropertyType = 'DWord'
                Value = 1
            }
        )
    }


    ##############################################################
    #  Add Fslogix Settings
    ##############################################################
    if($Fslogix -eq 'true')
    {
        $FilesSuffix = '.file.' + $StorageSuffix
        $CloudCacheOfficeContainers = @()
        $CloudCacheProfileContainers = @()
        $OfficeContainers = @()
        $ProfileContainers = @()
        switch($StorageSolution)
        {
            'AzureStorageAccount' {
                for($i = $StorageIndex; $i -lt $($StorageIndex + $StorageCount); $i++)
                {
                    $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $StorageAccountPrefix + $i.ToString() + $FilesSuffix + '\office-containers;'
                    $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $StorageAccountPrefix + $i.ToString() + $FilesSuffix + '\profile-containers;'
                    $OfficeContainers += '\\' + $StorageAccountPrefix + $i.ToString() + $FilesSuffix + '\office-containers'
                    $ProfileContainers += '\\' + $StorageAccountPrefix + $i.ToString() + $FilesSuffix + '\profile-containers'
                }
            }
            'AzureNetAppFiles' {
                $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $NetAppFileShares[0] + ';'
                $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $NetAppFileShares[1] + ';'
                $OfficeContainers += '\\' + $NetAppFileShares[0]
                $ProfileContainers += '\\' + $NetAppFileShares[1]
            }
        }
        
        $Shares = @()
        $Shares += $OfficeContainers
        $Shares += $ProfileContainers
        $SharesOutput = if($Shares.Count -eq 1){$Shares}else{$Shares -join ', '}
        Write-Log -Message "File Shares: $SharesOutput" -Type 'INFO'

        $Settings += @(

            # Enables Fslogix profile containers: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#enabled
            [PSCustomObject]@{
                Name = 'Enabled'
                Path = 'HKLM:\SOFTWARE\Fslogix\Profiles'
                PropertyType = 'DWord'
                Value = 1
            },

            # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
            [PSCustomObject]@{
                Name = 'DeleteLocalProfileWhenVHDShouldApply'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 1
            },

            # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
            [PSCustomObject]@{
                Name = 'FlipFlopProfileDirectoryName'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 1
            },

            # Specifies the number of retries attempted when a VHD(x) file is locked: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#lockedretrycount
            [PSCustomObject]@{
                Name = 'LockedRetryCount'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 3
            },

            # Specifies the number of seconds to wait between retries: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#lockedretryinterval
            [PSCustomObject]@{
                Name = 'LockedRetryInterval'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 15
            },

            # Specifies if the profile container can be accessed concurrently: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#profiletype
            [PSCustomObject]@{
                Name = 'ProfileType'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 0
            },

            # Specifies the number of seconds to wait between retries when attempting to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#reattachintervalseconds
            [PSCustomObject]@{
                Name = 'ReAttachIntervalSeconds'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 15
            },

            # Specifies the number of times the system should attempt to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#reattachretrycount
            [PSCustomObject]@{
                Name = 'ReAttachRetryCount'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 3
            },

            # Specifies the maximum size of the user's container in megabytes. Newly created VHD(x) containers are of this size: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#sizeinmbs
            [PSCustomObject]@{
                Name = 'SizeInMBs'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'DWord'
                Value = 30000
            },

            # Specifies the file extension for the profile containers: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#volumetype
            [PSCustomObject]@{
                Name = 'VolumeType'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'String'
                Value = 'VHDX'
            }
        )

        if($FslogixSolution -like "CloudCache*")
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'CCDLocations'
                    Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                    PropertyType = 'MultiString'
                    Value = $CloudCacheProfileContainers
                }
            )           
        }
        else
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'VHDLocations'
                    Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                    PropertyType = 'MultiString'
                    Value = $ProfileContainers
                }
            )
        }

        if($FslogixSolution -like "*OfficeContainer")
        {
            $Settings += @(

                # Enables Fslogix office containers: https://learn.microsoft.com/fslogix/office-container-configuration-reference#enabled
                [PSCustomObject]@{
                    Name = 'Enabled'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },

                # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://learn.microsoft.com/fslogix/office-container-configuration-reference#flipflopprofiledirectoryname
                [PSCustomObject]@{
                    Name = 'FlipFlopProfileDirectoryName'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },         
                
                # Teams data is redirected to the container: https://learn.microsoft.com/fslogix/office-container-configuration-reference#includeteams
                [PSCustomObject]@{
                    Name = 'IncludeTeams'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 1
                },                  

                # Specifies the number of retries attempted when a VHD(x) file is locked: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#lockedretrycount
                [PSCustomObject]@{
                    Name = 'LockedRetryCount'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 3
                },

                # Specifies the number of seconds to wait between retries: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#lockedretryinterval
                [PSCustomObject]@{
                    Name = 'LockedRetryInterval'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 15
                },

                # Specifies the number of seconds to wait between retries when attempting to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#reattachintervalseconds
                [PSCustomObject]@{
                    Name = 'ReAttachIntervalSeconds'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 15
                },

                # Specifies the number of times the system should attempt to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#reattachretrycount
                [PSCustomObject]@{
                    Name = 'ReAttachRetryCount'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 3
                },

                # Specifies the maximum size of the user's container in megabytes: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#sizeinmbs
                [PSCustomObject]@{
                    Name = 'SizeInMBs'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'DWord'
                    Value = 30000
                },

                # Specifies the type of container: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#volumetype
                [PSCustomObject]@{
                    Name = 'VolumeType'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'String'
                    Value = 'VHDX'
                }
            )

            if($FslogixSolution -like "CloudCache*")
            {
                $Settings += @(
                    # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
                    [PSCustomObject]@{
                        Name = 'CCDLocations'
                        Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                        PropertyType = 'MultiString'
                        Value = $CloudCacheOfficeContainers
                    }
                )           
            }
            else
            {
                $Settings += @(
                    # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/office-container-configuration-reference#vhdlocations
                    [PSCustomObject]@{
                        Name = 'VHDLocations'
                        Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                        PropertyType = 'MultiString'
                        Value = $OfficeContainers
                    }
                )
            }
        }
    }


    # Set registry settings
    foreach($Setting in $Settings)
    {
        # Create registry key(s) if necessary
        if(!(Test-Path -Path $Setting.Path))
        {
            New-Item -Path $Setting.Path -Force
        }

        # Checks for existing registry setting
        $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
        $LogOutputValue = 'Path: ' + $Setting.Path + ', Name: ' + $Setting.Name + ', PropertyType: ' + $Setting.PropertyType + ', Value: ' + $Setting.Value
        
        # Creates the registry setting when it does not exist
        if(!$Value)
        {
            New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force
            Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
        }
        # Updates the registry setting when it already exists
        elseif($Value.$($Setting.Name) -ne $Setting.Value)
        {
            Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force
            Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
        }
        # Writes log output when registry setting has the correct value
        else 
        {
            Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
        }
        Start-Sleep -Seconds 1
    }


    ##############################################################
    #  Install the AVD Agent
    ##############################################################
    # Disabling this method for installing the AVD agent until AAD Join can completed successfully
    $BootInstaller = 'AVD-Bootloader.msi'
    Get-WebFile -FileName $BootInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $BootInstaller /quiet /qn /norestart /passive" -Wait -Passthru
    Write-Log -Message 'Installed AVD Bootloader' -Type 'INFO'
    Start-Sleep -Seconds 5

    $AgentInstaller = 'AVD-Agent.msi'
    Get-WebFile -FileName $AgentInstaller -URL 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $AgentInstaller /quiet /qn /norestart /passive REGISTRATIONTOKEN=$HostPoolRegistrationToken" -Wait -PassThru
    Write-Log -Message 'Installed AVD Agent' -Type 'INFO'
    Start-Sleep -Seconds 5


    ##############################################################
    #  Dual-home Microsoft Monitoring Agent for Azure Sentinel
    ##############################################################
    if($Sentinel -eq 'true')
    {
        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $mma.AddCloudWorkspace($SentinelWorkspaceId, $SentinelWorkspaceKey)
        $mma.ReloadConfiguration()
    }

    ##############################################################
    #  Restart VM
    ##############################################################
    if($DomainServices -like "None*" -and $AmdVmSize -eq 'false' -and $NvidiaVmSize -eq 'false')
    {
        Start-Process -FilePath 'shutdown' -ArgumentList '/r /t 30'
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}
