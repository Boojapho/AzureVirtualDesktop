param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AcceleratedNetworking string
param AvailabilitySetPrefix string
param Availability string
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DiskName string
param DiskSku string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param DrainMode bool
param EphemeralOsDisk string
param Fslogix bool
param FslogixSolution string
param HostPoolName string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageVersion string
param KeyVaultName string
param Location string
param LogAnalyticsWorkspaceName string
param ManagedIdentityResourceId string
param Monitoring bool
param NamingStandard string
param NetworkSecurityGroupName string
param NetAppFileShares array
param OuPath string
param ResourceGroupManagement string
param ScreenCaptureProtection bool
param Sentinel bool
param SentinelWorkspaceId string
param SentinelWorkspaceResourceId string
param SessionHostCount int
param SessionHostIndex int
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSolution string
param StorageSuffix string
param Subnet string
param Tags object
param Timestamp string
param TrustedLaunch string
param UserAssignedIdentity string = ''
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string
@secure()
param VmPassword string
param VmSize string
param VmUsername string

var AmdVmSizes = [
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
]
var AmdVmSize = contains(AmdVmSizes, VmSize)
var FslogixExclusions = '${FslogixExclusionsLocal}${FslogixExclusionsProfileContainersString}${FslogixExclusionsOfficeContainersString}${FslogixExclusionsCloudCache}'
var FslogixExclusionsCloudCache = ';"%ProgramData%\\FSLogix\\Cache\\*";"%ProgramData%\\FSLogix\\Proxy\\*"'
var FslogixExclusionsLocal = ';"%TEMP%\\*\\*.VHDX";"%Windir%\\TEMP\\*\\*.VHDX"'
var FslogixExclusionsOfficeContainersArray = [for Share in FslogixOfficeShares: ';"${Share}*\\*.VHDX";"${Share}*\\*.VHDX.lock";"${Share}*\\*.VHDX.meta";"${Share}*\\*.VHDX.metadata"']
var FslogixExclusionsOfficeContainersString = join(FslogixExclusionsOfficeContainersArray, ';')
var FslogixExclusionsProfileContainersArray = [for Share in FslogixProfileShares: ';"${Share}*\\*.VHDX";"${Share}*\\*.VHDX.lock";"${Share}*\\*.VHDX.meta";"${Share}*\\*.VHDX.metadata"']
var FslogixExclusionsProfileContainersString = join(FslogixExclusionsProfileContainersArray, ';')
var FslogixOfficeShares = [for i in range(0, StorageCount): '\\\\${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}.file.${StorageSuffix}\\office-containers\\']
var FslogixProfileShares = [for i in range(0, StorageCount): '\\\\${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}.file.${StorageSuffix}\\profile-containers\\']
var Intune = DomainServices == 'NoneWithIntune' ? true : false
var NvidiaVmSizes = [
  'Standard_NV6'
  'Standard_NV12'
  'Standard_NV24'
  'Standard_NV12s_v3'
  'Standard_NV24s_v3'
  'Standard_NV48s_v3'
  'Standard_NC4as_T4_v3'
  'Standard_NC8as_T4_v3'
  'Standard_NC16as_T4_v3'
  'Standard_NC64as_T4_v3'
  'Standard_NV6ads_A10_v5'
  'Standard_NV12ads_A10_v5'
  'Standard_NV18ads_A10_v5'
  'Standard_NV36ads_A10_v5'
  'Standard_NV36adms_A10_v5'
  'Standard_NV72ads_A10_v5'
]
var NvidiaVmSize = contains(NvidiaVmSizes, VmSize)
var PooledHostPool = (split(HostPoolType, ' ')[0] == 'Pooled')
var SentinelWorkspaceKey = Sentinel ? listKeys(SentinelWorkspaceResourceId, '2021-06-01').primarySharedKey : 'NotApplicable'
var VmIdentityType = (contains(DomainServices, 'None') ? ((!empty(UserAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned') : ((!empty(UserAssignedIdentity)) ? 'UserAssigned' : 'None'))
var VmIdentityTypeProperty = {
  type: VmIdentityType
}
var VmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', UserAssignedIdentity)}': {}
  }
}
var VmIdentity = ((!empty(UserAssignedIdentity)) ? union(VmIdentityTypeProperty, VmUserAssignedIdentityProperty) : VmIdentityTypeProperty)

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, SessionHostCount): {
  name: 'nic-${NamingStandard}-${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(subscription().subscriptionId, VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: AcceleratedNetworking == 'True' ? true : false
    enableIPForwarding: false
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  zones: Availability == 'AvailabilityZones' ? [
    string((i % 3) + 1)
  ] : null
  identity: VmIdentity
  properties: {
    availabilitySet: Availability == 'AvailabilitySet' ? {
      id: resourceId('Microsoft.Compute/availabilitySets', '${AvailabilitySetPrefix}-${(i + SessionHostIndex) / 200}')
    } : null
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      imageReference: {
        publisher: ImagePublisher
        offer: ImageOffer
        sku: ImageSku
        version: ImageVersion
      }
      osDisk: {
        name: '${DiskName}${padLeft((i + SessionHostIndex), 3, '0')}'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: EphemeralOsDisk == 'None' ? 'ReadWrite' : 'ReadOnly'
        deleteOption: 'Delete'
        managedDisk: EphemeralOsDisk == 'None' ? {
          storageAccountType: DiskSku
        } : null
        diffDiskSettings: EphemeralOsDisk == 'None' ? null : {
          option: 'Local'
          placement: EphemeralOsDisk
        }
      }
      dataDisks: []
    }
    osProfile: {
      computerName: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
      adminUsername: VmUsername
      adminPassword: VmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic-${NamingStandard}-${padLeft((i + SessionHostIndex), 3, '0')}')
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      uefiSettings: TrustedLaunch == 'true' ? {
        secureBootEnabled: true
        vTpmEnabled: true
      } : null
      securityType: TrustedLaunch == 'true' ? 'TrustedLaunch' : null
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: ((ImagePublisher == 'MicrosoftWindowsServer') ? 'Windows_Server' : 'Windows_Client')
  }
  dependsOn: [
    networkInterface
  ]
}]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (DiskEncryption) {
  name: KeyVaultName
  scope: resourceGroup(ResourceGroupManagement)
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' existing = if (DiskEncryption) {
  name: '${DeploymentScriptNamePrefix}kek'
  scope: resourceGroup(ResourceGroupManagement)
}

resource extension_AzureDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = [for i in range(0, SessionHostCount): if (DiskEncryption) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AzureDiskEncryption'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: DiskEncryption ? keyVault.properties.vaultUri : ''
      KeyVaultResourceId: DiskEncryption ? keyVault.id : ''
      KeyEncryptionKeyURL: DiskEncryption ? deploymentScript.properties.outputs.text : ''
      KekVaultResourceId: DiskEncryption ? keyVault.id : ''
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
  dependsOn: [
    virtualMachine
  ]
}]

resource extension_MicrosoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (Monitoring) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/MicrosoftMonitoringAgent'
  location: Location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: Monitoring ? reference(resourceId(ResourceGroupManagement, 'Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName), '2015-03-20').customerId : null
    }
    protectedSettings: {
      workspaceKey: Monitoring ? listKeys(resourceId(ResourceGroupManagement, 'Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName), '2015-03-20').primarySharedKey : null
    }
  }
  dependsOn: [
    virtualMachine
  ]
}]

resource extension_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${_artifactsLocation}Set-SessionHostConfiguration.ps1${_artifactsLocationSasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -AmdVmSize ${AmdVmSize} -DomainName ${DomainName} -DomainServices ${DomainServices} -Environment ${environment().name} -FSLogix ${Fslogix} -FslogixSolution ${FslogixSolution} -HostPoolName ${HostPoolName} -HostPoolRegistrationToken ${reference(resourceId(ResourceGroupManagement, 'Microsoft.DesktopVirtualization/hostpools', HostPoolName), '2019-12-10-preview').registrationInfo.token} -ImageOffer ${ImageOffer} -ImagePublisher ${ImagePublisher} -NetAppFileShares ${NetAppFileShares} -NvidiaVmSize ${NvidiaVmSize} -PooledHostPool ${PooledHostPool} -ScreenCaptureProtection ${ScreenCaptureProtection} -Sentinel ${Sentinel} -SentinelWorkspaceId ${SentinelWorkspaceId} -SentinelWorkspaceKey ${SentinelWorkspaceKey} -StorageAccountPrefix ${StorageAccountPrefix} -StorageCount ${StorageCount} -StorageIndex ${StorageIndex} -StorageSolution ${StorageSolution} -StorageSuffix ${StorageSuffix}'
    }
  }
  dependsOn: [
    extension_AzureDiskEncryption
    extension_MicrosoftMonitoringAgent
    virtualMachine
  ]
}]

// Enables drain mode on the session hosts so users cannot login to hosts immediately after the deployment
module drainMode '../deploymentScript.bicep' = if (DrainMode) {
  name: 'DeploymentScript_DrainMode_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    Arguments: '-ResourceGroup ${ResourceGroupManagement} -HostPool ${HostPoolName}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}drainMode'
    Script: 'param([Parameter(Mandatory)][string]$HostPool,[Parameter(Mandatory)][string]$ResourceGroup); $SessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool).Name; foreach($SessionHost in $SessionHosts){$Name = ($SessionHost -split "/")[1]; Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $Name -AllowNewSession:$False}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["hostPool"] = $HostPool'
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: ManagedIdentityResourceId
  }
  dependsOn: [
    extension_CustomScriptExtension
    virtualMachine
  ]
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (contains(DomainServices, 'ActiveDirectory')) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/JsonADDomainExtension'
  location: Location
  tags: Tags
  properties: {
    forceUpdateTag: Timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: DomainName
      User: DomainJoinUserPrincipalName
      Restart: 'true'
      Options: '3'
      OUPath: OuPath
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
  dependsOn: [
    drainMode
    virtualMachine
  ]
}]

resource extension_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (contains(DomainServices, 'None')) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AADLoginForWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: Intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : null
  }
  dependsOn: [
    extension_CustomScriptExtension
    virtualMachine
  ]
}]

resource extension_AmdGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (AmdVmSize) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AmdGpuDriverWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'AmdGpuDriverWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    extension_JsonADDomainExtension
    virtualMachine
  ]
}]

resource extension_NvidiaGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (NvidiaVmSize) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/NvidiaGpuDriverWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    extension_JsonADDomainExtension
    virtualMachine
  ]
}]

resource extension_IaasAntimalware 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/IaaSAntimalware'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: 'true'
      ScheduledScanSettings: {
        isEnabled: 'true'
        day: '7' // Day of the week for scheduled scan (1-Sunday, 2-Monday, ..., 7-Saturday)
        time: '120' // When to perform the scheduled scan, measured in minutes from midnight (0-1440). For example: 0 = 12AM, 60 = 1AM, 120 = 2AM.
        scanType: 'Quick' //Indicates whether scheduled scan setting type is set to Quick or Full (default is Quick)
      }
      Exclusions: Fslogix ? {
        Paths: FslogixExclusions
      } : {}
    }
  }
  dependsOn: [
    virtualMachine
  ]
}]
