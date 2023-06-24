param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param ActiveDirectoryConnection string
param ActiveDirectorySolution string
param Availability string
param AzureFilesPrivateDnsZoneResourceId string
param ClientId string
param DelegatedSubnetId string
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DiskEncryptionSetResourceId string
param DiskSku string
param DnsServers string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param FileShares array
param FslogixShareSizeInGB int
param FslogixSolution string
param FslogixStorage string
param KerberosEncryption string
param Location string
param ManagementVmName string
param NamingStandard string
param NetAppAccountName string
param NetAppCapacityPoolName string
param Netbios string
param OuPath string
param PrivateEndpoint bool
param ResourceGroupManagement string
param ResourceGroupStorage string
param SecurityPrincipalIds array
param SecurityPrincipalNames array
param SmbServerLocation string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSku string
param StorageSolution string
param Subnet string
param TagsDeploymentScripts object
param TagsNetAppAccount object
param TagsNetworkInterfaces object
param TagsPrivateEndpoints object
param TagsStorageAccounts object
param TagsVirtualMachines object
param Timestamp string
param TrustedLaunch string
param UserAssignedIdentityResourceId string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VirtualMachinePassword string
param VirtualMachineUsername string

// Fslogix Management VM
// This module is required to fully configure any storage option for FSLogix
module managementVirtualMachine 'managementVirtualMachine.bicep' = if (contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'ManagementVirtualMachine_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: DiskEncryptionSetResourceId
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    Location: Location
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    Subnet: Subnet
    TagsNetworkInterfaces: TagsNetworkInterfaces
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineUsername: VirtualMachineUsername
  }
}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (StorageSolution == 'AzureNetAppFiles' && contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'AzureNetAppFiles_${Timestamp}'
  scope: resourceGroup(ResourceGroupStorage)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    ActiveDirectoryConnection: ActiveDirectoryConnection
    DelegatedSubnetId: DelegatedSubnetId
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DnsServers: DnsServers
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    FileShares: FileShares
    FslogixSolution: FslogixSolution
    Location: Location
    ManagementVmName: ManagementVmName
    NetAppAccountName: NetAppAccountName
    NetAppCapacityPoolName: NetAppCapacityPoolName
    OuPath: OuPath
    ResourceGroupManagement: ResourceGroupManagement
    SecurityPrincipalNames: SecurityPrincipalNames
    SmbServerLocation: SmbServerLocation
    StorageSku: StorageSku
    StorageSolution: StorageSolution
    TagsDeploymentScripts: TagsDeploymentScripts
    TagsNetAppAccount: TagsNetAppAccount
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
  dependsOn: [
    managementVirtualMachine
  ]
}

// Azure Files for FSLogix
module azureFiles 'azureFiles/azureFiles.bicep' = if (StorageSolution == 'AzureStorageAccount' && contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'AzureFiles_${Timestamp}'
  scope: resourceGroup(ResourceGroupStorage)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    ActiveDirectorySolution: ActiveDirectorySolution
    Availability: Availability
    AzureFilesPrivateDnsZoneResourceId: AzureFilesPrivateDnsZoneResourceId
    ClientId: ClientId
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    FslogixSolution: FslogixSolution
    FslogixStorage: FslogixStorage
    KerberosEncryption: KerberosEncryption
    Location: Location
    ManagementVmName: ManagementVmName
    Netbios: Netbios
    OuPath: OuPath
    PrivateEndpoint: PrivateEndpoint
    ResourceGroupManagement: ResourceGroupManagement
    ResourceGroupStorage: ResourceGroupStorage
    SecurityPrincipalIds: SecurityPrincipalIds
    SecurityPrincipalNames: SecurityPrincipalNames
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSku: StorageSku
    StorageSolution: StorageSolution
    Subnet: Subnet
    TagsDeploymentScripts: TagsDeploymentScripts
    TagsPrivateEndpoints: TagsPrivateEndpoints
    TagsStorageAccounts: TagsStorageAccounts
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
  dependsOn: [
    managementVirtualMachine
  ]
}

output netAppShares array = StorageSolution == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
