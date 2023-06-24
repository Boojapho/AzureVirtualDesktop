param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AcceleratedNetworking string
param Availability string
param AvailabilitySetsCount int
param AvailabilitySetsIndex int
param AvailabilitySetsPrefix string
param AvailabilityZones array
param DeploymentScriptNamePrefix string
param DiskEncryption bool
param DiskEncryptionSetResourceId string
param DiskName string
param DiskSku string
param DivisionRemainderValue int
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param ActiveDirectorySolution string
param DrainMode bool
param FslogixSolution string
param Fslogix bool
param HostPoolName string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageVersionResourceId string
param Location string
param LogAnalyticsWorkspaceName string
param ManagedIdentityResourceId string
param MaxResourcesPerTemplateDeployment int
param Monitoring bool
param NamingStandard string
param NetAppFileShares array
param OuPath string
param PooledHostPool bool
param ResourceGroupHosts string
param ResourceGroupManagement string
param SecurityPrincipalObjectIds array
param Sentinel bool
param SentinelWorkspaceId string
param SentinelWorkspaceResourceId string
param SessionHostBatchCount int
param SessionHostIndex int
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSolution string
param StorageSuffix string
param Subnet string
param TagsAvailabilitySets object
param TagsDeploymentScripts object
param TagsNetworkInterfaces object
param TagsVirtualMachines object
param Timestamp string
param TrustedLaunch string
param VirtualMachineLocation string
@secure()
param VirtualMachinePassword string
param VirtualMachineSize string
param VirtualMachineUsername string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string

var VirtualMachineUserLoginRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')

resource availabilitySets 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetsCount): if (PooledHostPool && Availability == 'AvailabilitySets') {
  name: '${AvailabilitySetsPrefix}${padLeft((i + AvailabilitySetsIndex), 2, '0')}'
  location: VirtualMachineLocation
  tags: TagsAvailabilitySets
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}]

// Role Assignment for Virtual Machine Login User
// This module deploys the role assignments to login to Azure AD joined session hosts
module roleAssignments '../roleAssignment.bicep' = [for i in range(0, length(SecurityPrincipalObjectIds)): if (!contains(ActiveDirectorySolution, 'DomainServices')) {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    PrincipalId: SecurityPrincipalObjectIds[i]
    RoleDefinitionId: VirtualMachineUserLoginRoleDefinitionResourceId
  }
}]

@batchSize(1)
module virtualMachines 'virtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'VirtualMachines_${i - 1}_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AcceleratedNetworking: AcceleratedNetworking
    ActiveDirectorySolution: ActiveDirectorySolution
    Availability: Availability
    AvailabilityZones: AvailabilityZones
    AvailabilitySetsPrefix: AvailabilitySetsPrefix
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: DiskEncryptionSetResourceId
    DiskName: DiskName
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixSolution: FslogixSolution
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersionResourceId: ImageVersionResourceId
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagedIdentityResourceId: ManagedIdentityResourceId
    Monitoring: Monitoring
    NamingStandard: NamingStandard
    NetAppFileShares: NetAppFileShares
    OuPath: OuPath
    ResourceGroupManagement: ResourceGroupManagement
    Sentinel: Sentinel
    SentinelWorkspaceId: SentinelWorkspaceId
    SentinelWorkspaceResourceId: SentinelWorkspaceResourceId
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    TagsDeploymentScripts: TagsDeploymentScripts
    TagsNetworkInterfaces: TagsNetworkInterfaces
    TagsVirtualMachines: TagsVirtualMachines
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    VirtualMachineLocation: VirtualMachineLocation
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineSize: VirtualMachineSize
    VirtualMachineUsername: VirtualMachineUsername
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    
  }
  dependsOn: [
    availabilitySets
  ]
}]
