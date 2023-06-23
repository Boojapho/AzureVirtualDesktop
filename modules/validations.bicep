param ActiveDirectorySolution string
param Availability string
param DeploymentScriptNamePrefix string
param DiskSku string
param DomainName string
param Fslogix bool
param HostPoolType string
param ImageSku string
param KerberosEncryption string
param Location string
param SecurityPrincipalIdsCount int
param SecurityPrincipalNamesCount int
param SessionHostCount int
param StorageCount int
param StorageSolution string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualMachineSize string
param VnetName string
param VnetResourceGroupName string

var CpuCountMax = contains(HostPoolType, 'Pooled') ? 32 : 128
var CpuCountMin = contains(HostPoolType, 'Pooled') ? 4 : 2

module acceleratedNetworking 'deploymentScript.bicep' = if (SessionHostCount > 0) {
  name: 'DeploymentScript_AcceleratedNetworkingValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}acceleratedNetworkingValidation'
    Script: 'param([string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["enabled"] = ($Sku.capabilities | Where-Object {$_.name -eq "AcceleratedNetworkingEnabled"}).value'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module availabilityZones 'deploymentScript.bicep' = if (Availability == 'AvailabilityZones') {
  name: 'DeploymentScript_AvailabilityZoneValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}availabilityZonesValidation'
    Script: 'param([string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["zones"] = $Sku.locationInfo.zones | Sort-Object | ConvertTo-Json -AsArray'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module azureNetAppFiles 'deploymentScript.bicep' = if (Availability == 'AvailabilityZones') {
  name: 'DeploymentScript_AzureNetAppFilesValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -StorageSolution ${StorageSolution} -VnetName ${VnetName} -VnetResourceGroupName ${VnetResourceGroupName}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}azureNetAppFilesValidation'
    Script: 'param([string]$Location,[string]$StorageSolution,[string]$VnetName,[string]$VnetResourceGroupName); $ErrorActionPreference = "Stop"; $DeploymentScriptOutputs = @{}; if($StorageSolution -eq "AzureNetAppFiles"){$Vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $VnetResourceGroupName; $DnsServers = "$($Vnet.DhcpOptions.DnsServers[0]),$($Vnet.DhcpOptions.DnsServers[1])"; $SubnetId = ($Vnet.Subnets | Where-Object {$_.Delegations[0].ServiceName -eq "Microsoft.NetApp/volumes"}).Id; if($null -eq $SubnetId -or $SubnetId -eq ""){Write-Error -Exception "INVALID AZURE NETAPP FILES CONFIGURATION: A dedicated subnet must be delegated to the ANF resource provider."}; Install-Module -Name "Az.NetAppFiles" -Force; $DeployAnfAd = "true"; $Accounts = Get-AzResource -ResourceType "Microsoft.NetApp/netAppAccounts" | Where-Object {$_.Location -eq $Location}; foreach($Account in $Accounts){$AD = Get-AzNetAppFilesActiveDirectory -ResourceGroupName $Account.ResourceGroupName -AccountName $Account.Name; if($AD.ActiveDirectoryId){$DeployAnfAd = "false"}}; $DeploymentScriptOutputs["anfDnsServers"] = $DnsServers; $DeploymentScriptOutputs["anfSubnetId"] = $SubnetId; $DeploymentScriptOutputs["anfActiveDirectory"] = $DeployAnfAd} else {$DeploymentScriptOutputs["anfDnsServers"] = "NotApplicable"; $DeploymentScriptOutputs["anfSubnetId"] = "NotApplicable"; $DeploymentScriptOutputs["anfActiveDirectory"] = "false"}'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module diskSku 'deploymentScript.bicep' = if (contains(DiskSku, 'Premium')) {
  name: 'DeploymentScript_DiskSkuValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}diskSkuValidation'
    Script: 'param([string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; if(($Sku.capabilities | Where-Object {$_.name -eq "PremiumIO"}).value -eq $false){Write-Error -Exception "INVALID DISK SKU: The selected VM Size does not support the Premium SKU for managed disks."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["premiumIo"] = ($Sku.capabilities | Where-Object {$_.name -eq "PremiumIO"}).value'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module hyperVGeneration 'deploymentScript.bicep' = if (contains(ImageSku, '-g2') || contains(ImageSku, 'win11')) {
  name: 'DeploymentScript_HyperVGenerationValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}hyperVGenerationValidation'
    Script: 'param([string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; if(($Sku.capabilities | Where-Object {$_.name -eq "HyperVGenerations"}).value -notlike "*2"){Write-Error -Exception "INVALID HYPER-V GENERATION: The selected VM size does not support the selected Image Sku."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["hyperVGenerations"] = ($Sku.capabilities | Where-Object {$_.name -eq "HyperVGenerations"}).value'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module kerberosEncryption 'deploymentScript.bicep' = if (ActiveDirectorySolution == 'AzureActiveDirectoryDomainServices') {
  name: 'DeploymentScript_KerberosEncryptionValidation_${Timestamp}'
  params: {
    Arguments: '-DomainName ${DomainName} -KerberosEncryption ${KerberosEncryption}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}kerberosEncryptionValidation'
    Script: 'param([string]$DomainName,[string]$KerberosEncryption); $ErrorActionPreference = "Stop"; $KerberosRc4Encryption = (Get-AzResource -Name $DomainName -ExpandProperties).Properties.domainSecuritySettings.kerberosRc4Encryption; if($KerberosRc4Encryption -eq "Enabled" -and $KerberosEncryption -eq "AES256"){Write-Error -Exception "INVALID KERBEROS ENCRYPTION: The Kerberos Encryption on Azure AD DS does not match your Kerberos Encyrption selection."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["kerberosRc4Encryption"] = $KerberosRc4Encryption'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module storage 'deploymentScript.bicep' = if (Fslogix) {
  name: 'DeploymentScript_StorageValidation_${Timestamp}'
  params: {
    Arguments: '-SecurityPrincipalIdsCount ${SecurityPrincipalIdsCount} -SecurityPrincipalNamesCount ${SecurityPrincipalNamesCount} -StorageCount ${StorageCount}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}storageValidation'
    Script: 'param([int]$SecurityPrincipalIdsCount,[int]$SecurityPrincipalNamesCount,[int]$StorageCount); $ErrorActionPreference = "Stop"; if(($StorageCount -ne $SecurityPrincipalIdsCount -or $StorageCount -ne $SecurityPrincipalNamesCount) -and $StorageCount -gt 0){Write-Error -Exception "INVALID ARRAYS: The "SecurityPrinicaplIdsCount", "SecurityPrincipalNamesCount", and "StorageCount" must be equal in length."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["storageOutOfBounds"] = ($StorageCount -ne $SecurityPrincipalIdsCount -or $StorageCount -ne $SecurityPrincipalNamesCount) -and $StorageCount -gt 0'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module trustedLaunch 'deploymentScript.bicep' = if (contains(ImageSku, '-g2') || contains(ImageSku, 'win11')) {
  name: 'DeploymentScript_TrustedLaunchValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}trustedLaunchValidation'
    Script: 'param([string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $DeploymentScriptOutputs = @{}; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; if($null -eq ($Sku.capabilities | Where-Object {$_.name -eq "TrustedLaunchDisabled"}).value){$DeploymentScriptOutputs["enabled"] = "true"}else{$DeploymentScriptOutputs["enabled"] = "false"}'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

// vCPU Count Validation
// Recommended minimum vCPU is 4 for multisession hosts and 2 for single session hosts.
// Recommended maximum vCPU is 32 for multisession hosts and 128 for single session hosts.
// https://learn.microsoft.com/windows-server/remote/remote-desktop-services/virtual-machine-recs
module cpuCount 'deploymentScript.bicep' = {
  name: 'DeploymentScript_CpuCountValidation_${Timestamp}'
  params: {
    Arguments: '-CpuCountMax ${CpuCountMax} -CpuCountMin ${CpuCountMin} -Location ${Location} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}cpuCountValidation'
    Script: 'param([int]$CpuCountMax,[int]$CpuCountMin,[string]$Location,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; $vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq "vCPUs"}).value; if($vCPUs -lt $CpuCountMin -or $vCPUs -gt $CpuCountMax){Write-Error -Exception "INVALID VCPU COUNT: The selected VM Size does not contain the appropriate amount of vCPUs for Azure Virtual Desktop. https://learn.microsoft.com/windows-server/remote/remote-desktop-services/virtual-machine-recs"}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["vcpus"] = $vCPUs'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module cpuQuota 'deploymentScript.bicep' = {
  name: 'DeploymentScript_CpuQuotaValidation_${Timestamp}'
  params: {
    Arguments: '-Location ${Location} -SessionHostCount ${SessionHostCount} -VmSize ${VirtualMachineSize}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}cpuQuotaValidation'
    Script: 'param([string]$Location,[int]$SessionHostCount,[string]$VmSize); $ErrorActionPreference = "Stop"; $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VmSize}; $vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq "vCPUs"}).value; $RequestedCores = $vCPUs * $SessionHostCount; $Family = (Get-AzComputeResourceSku -Location $Location | Where-Object {$_.Name -eq $VmSize}).Family; $CpuData = Get-AzVMUsage -Location $Location | Where-Object {$_.Name.Value -eq $Family}; $AvailableCores = $CpuData.Limit - $CpuData.CurrentValue; $RequestedCores = $vCPUs * $SessionHostCount; if($RequestedCores -gt $AvailableCores){Write-Error -Exception "INSUFFICIENT CORE QUOTA: The selected VM size, $VmSize, does not have adequate core quota in the selected location."}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["requestedCores"] = $RequestedCores; $DeploymentScriptOutputs["availableCores"] = $AvailableCores'
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

output acceleratedNetworking string = acceleratedNetworking.outputs.properties.enabled
output anfActiveDirectory string = azureNetAppFiles.outputs.properties.anfActiveDirectory
output anfDnsServers string = azureNetAppFiles.outputs.properties.anfDnsServers
output anfSubnetId string = azureNetAppFiles.outputs.properties.anfSubnetId
output availabilityZones array = Availability == 'AvailabilityZones' ? json(availabilityZones.outputs.properties.zones) : [ '1' ]
output trustedLaunch string = trustedLaunch.outputs.properties.enabled
