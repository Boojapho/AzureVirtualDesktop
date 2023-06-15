param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AcceleratedNetworking string
param Availability string
param AvailabilitySetCount int
param AvailabilitySetIndex int
param AvailabilitySetPrefix string
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
param ImageVersion string
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
param ScreenCaptureProtection bool
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
param Tags object
param Timestamp string
param TrustedLaunch string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string
@secure()
param VmPassword string
param VmSize string
param VmUsername string

var VirtualMachineUserLoginRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')

resource availabilitySets 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetCount): if (PooledHostPool && Availability == 'AvailabilitySet') {
  name: '${AvailabilitySetPrefix}${padLeft((i + AvailabilitySetIndex), 2, '0')}'
  location: Location
  tags: Tags
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
    Availability: Availability
    AvailabilityZones: AvailabilityZones
    AvailabilitySetPrefix: AvailabilitySetPrefix
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DiskName: DiskName
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    ActiveDirectorySolution: ActiveDirectorySolution
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixSolution: FslogixSolution
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagedIdentityResourceId: ManagedIdentityResourceId
    Monitoring: Monitoring
    NamingStandard: NamingStandard
    NetAppFileShares: NetAppFileShares
    OuPath: OuPath
    ResourceGroupManagement: ResourceGroupManagement
    ScreenCaptureProtection: ScreenCaptureProtection
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
    Tags: Tags
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    VmPassword: VmPassword
    VmSize: VmSize
    VmUsername: VmUsername
    DiskEncryptionSetResourceId: DiskEncryptionSetResourceId
  }
  dependsOn: [
    availabilitySets
  ]
}]
