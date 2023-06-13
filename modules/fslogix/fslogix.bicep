targetScope = 'subscription'

param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param ActiveDirectoryConnection string
param AzureFilesPrivateDnsZoneResourceId string
param ClientId string
param DelegatedSubnetId string
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DnsServers string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param FileShares array
param FslogixShareSizeInGB int
param FslogixSolution string
param FslogixStorage string
param KerberosEncryption string
param KeyVaultName string
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
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string

// Fslogix Management VM
// This module is required to fully configure any storage option for FSLogix
module managementVirtualMachine 'managementVirtualMachine.bicep' = if (!contains(DomainServices, 'None')) {
  name: 'ManagementVirtualMachine_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    KeyVaultName: KeyVaultName
    Location: Location
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    ResourceGroupManagement: ResourceGroupManagement
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmPassword: VmPassword
    VmUsername: VmUsername
  }

}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (StorageSolution == 'AzureNetAppFiles' && !contains(DomainServices, 'None')) {
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
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
  dependsOn: [
    managementVirtualMachine
  ]
}

// Azure Files for FSLogix
module azureFiles 'azureFiles/azureFiles.bicep' = if (StorageSolution == 'AzureStorageAccount' && !contains(DomainServices, 'None')) {
  name: 'AzureFiles_${Timestamp}'
  scope: resourceGroup(ResourceGroupStorage)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AzureFilesPrivateDnsZoneResourceId: AzureFilesPrivateDnsZoneResourceId
    ClientId: ClientId
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainServices: DomainServices
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
    Tags: Tags
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
