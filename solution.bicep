targetScope = 'subscription'

@description('The URL prefix for linked resources.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/AzureVirtualDesktop/main/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@allowed([
  'ActiveDirectoryDomainServices'
  'AzureActiveDirectoryDomainServices'
  'AzureActiveDirectory'
  'AzureActiveDirectoryIntuneEnrollment'
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to properly configure the session hosts and if applicable, the Azure Storage Account.')
param ActiveDirectorySolution string

@allowed([
  'AvailabilitySets'
  'AvailabilityZones'
  'None'
])
@description('Set the desired availability / SLA with a pooled host pool.  The best practice is to deploy to Availability Zones for resilency.')
param Availability string = 'AvailabilityZones'

@description('The Object ID for the Windows Virtual Desktop Enterprise Application in Azure AD.  The Object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Azure AD.')
param AvdObjectId string

@description('If using private endpoints with Azure Files, input the Resource ID for the Private DNS Zone linked to your hub virtual network.')
param AzureFilesPrivateDnsZoneResourceId string = ''

@description('Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/clients/rdp-files')
param CustomRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;'

@description('Enable Server-Side Encrytion and Encryption at Host on the AVD session hosts and management VM.')
param DiskEncryption bool = true

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
@description('The storage SKU for the AVD session host disks.  Production deployments should use Premium_LRS.')
param DiskSku string = 'Premium_LRS'

@secure()
@description('The password of the privileged account to domain join the AVD session hosts to your domain')
param DomainJoinPassword string = ''

@description('The UPN of the privileged account to domain join the AVD session hosts to your domain. This should be an account the resides within the domain you are joining.')
param DomainJoinUserPrincipalName string = ''

@description('The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD')
param DomainName string = ''

@description('Enable drain mode on new sessions hosts to prevent users from accessing them until they are validated.')
param DrainMode bool = false

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The file share size(s) in GB for the Fslogix storage solution.')
param FslogixShareSizeInGB int = 100

@allowed([
  'CloudCacheProfileContainer' // FSLogix Cloud Cache Profile Container
  'CloudCacheProfileOfficeContainer' // FSLogix Cloud Cache Profile & Office Container
  'ProfileContainer' // FSLogix Profile Container
  'ProfileOfficeContainer' // FSLogix Profile & Office Container
])
param FslogixSolution string = 'ProfileContainer'

@allowed([
  'AzureNetAppFiles Premium' // ANF with the Premium SKU, 450,000 IOPS
  'AzureNetAppFiles Standard' // ANF with the Standard SKU, 320,000 IOPS
  'AzureStorageAccount Premium PublicEndpoint' // Azure Files Premium with the default public endpoint, 100,000 IOPS
  'AzureStorageAccount Premium PrivateEndpoint' // Azure Files Premium with a Private Endpoint, 100,000 IOPS
  'AzureStorageAccount Premium ServiceEndpoint' // Azure Files Premium with a Service Endpoint, 100,000 IOPs
  'AzureStorageAccount Standard PublicEndpoint' // Azure Files Standard with the Large File Share option and the default public endpoint, 20,000 IOPS
  'AzureStorageAccount Standard PrivateEndpoint' // Azure Files Standard with the Large File Share option and a Private Endpoint, 20,000 IOPS
  'AzureStorageAccount Standard ServiceEndpoint' // Azure Files Standard with the Large File Share option and a Service Endpoint, 20,000 IOPS
  'None'
])
@description('Enable an Fslogix storage option to manage user profiles for the AVD session hosts. The selected service & SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements')
param FslogixStorage string = 'AzureStorageAccount Standard PublicEndpoint'

@allowed([
  'Pooled DepthFirst'
  'Pooled BreadthFirst'
  'Personal Automatic'
  'Personal Direct'
])
@description('These options specify the host pool type and depending on the type provides the load balancing options and assignment types.')
param HostPoolType string = 'Pooled DepthFirst'

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

@description('Offer for the virtual machine image')
param ImageOffer string = 'office-365'

@description('Publisher for the virtual machine image')
param ImagePublisher string = 'MicrosoftWindowsDesktop'

@description('SKU for the virtual machine image')
param ImageSku string = 'win11-22h2-avd-m365'

@description('The resource ID for the Compute Gallery Image Version. Do not set this value if using a marketplace image.')
param ImageVersionResourceId string = ''

@allowed([
  'AES256'
  'RC4'
])
@description('The Active Directory computer object Kerberos encryption type for the Azure Storage Account or Azure NetApp Files Account.')
param KerberosEncryption string = 'RC4'

@description('The deployment location for the AVD management resources.')
param ControlPlaneLocation string = deployment().location

@maxValue(730)
@minValue(30)
@description('The retention for the Log Analytics Workspace to setup the AVD Monitoring solution')
param LogAnalyticsWorkspaceRetention int = 30

@allowed([
  'Free'
  'Standard'
  'Premium'
  'PerNode'
  'PerGB2018'
  'Standalone'
  'CapacityReservation'
])
@description('The SKU for the Log Analytics Workspace to setup the AVD Monitoring solution')
param LogAnalyticsWorkspaceSku string = 'PerGB2018'

@description('The maximum number of sessions per AVD session host.')
param MaxSessionLimit int

@description('Deploys the required monitoring resources to enable AVD Insights and monitor features in the automation account.')
param Monitoring bool = true

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param OuPath string

@description('Enable backups to an Azure Recovery Services vault.  For a pooled host pool this will enable backups on the Azure file share.  For a personal host pool this will enable backups on the AVD sessions hosts.')
param RecoveryServices bool = false

@description('Time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours e.g. 9:00 for 9am')
param ScalingBeginPeakTime string = '9:00'

@description('Time when session hosts will scale down and stay off to support low demand; Format 24 hours e.g. 17:00 for 5pm')
param ScalingEndPeakTime string = '17:00'

@description('The number of seconds to wait before automatically signing out users. If set to 0 any session host that has user sessions will be left untouched')
param ScalingLimitSecondsToForceLogOffUser string = '0'

@description('The minimum number of session host VMs to keep running during off-peak hours. The scaling tool will not work if all virtual machines are turned off and the Start VM On Connect solution is not enabled.')
param ScalingMinimumNumberOfRdsh string = '0'

@description('The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours')
param ScalingSessionThresholdPerCPU string = '1'

@description('Deploys the required resources for the Scaling Tool. https://docs.microsoft.com/en-us/azure/virtual-desktop/scaling-automation-logic-apps')
param ScalingTool bool = true

@description('An array of Security Principal object IDs to assign to the AVD Application Group and FSLogix Storage.')
param SecurityPrincipalObjectIds array = []

@description('An array of Security Principal names to assign NTFS permissions on the Azure File Share to support Fslogix. This is only required for pooled host pools using FSLogix. The names should align to the object IDs provided in the "SecurityPrincipalObjectIds" parameter.')
param SecurityPrincipalNames array = []

@description('The resource ID of the log analytics workspace used for Azure Sentinel. When using the Microsoft Monitoring Agent, this allows you to multihome the agent for Sentinel and AVD Insights.')
param SentinelLogAnalyticsWorkspaceResourceId string = ''

@maxValue(5000)
@minValue(0)
@description('The number of session hosts to deploy in the host pool. Ensure you have the approved quota to deploy the desired count.')
param SessionHostCount int = 1

@maxValue(4999)
@minValue(0)
@description('The starting number for the session hosts. This is important when adding virtual machines to ensure an update deployment is not performed on an exiting, active session host.')
param SessionHostIndex int = 0

@maxValue(9)
@minValue(0)
@description('The stamp index allows for multiple AVD stamps with the same business unit or project to support different use cases. For example, "0" could be used for an office workers host pool and "1" could be used for a developers host pool within the "finance" business unit.')
param StampIndex int = 0

@maxValue(10)
@minValue(0)
@description('The number of storage accounts to deploy to support the required use case for the AVD stamp. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param StorageCount int = 1

@maxValue(9)
@minValue(0)
@description('The starting number for the storage accounts to support the required use case for the AVD stamp. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param StorageIndex int = 0

@description('The resource ID of the subnet to place the network interfaces for the AVD session hosts.')
param SubnetResourceId string

@description('Key / value pairs of metadata for the Azure resource groups and resources.')
param Tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The value determines whether the hostpool should receive early AVD updates for testing.')
param ValidationEnvironment bool = false

@description('Input the desired location for the virtual machines and their associated resources.')
param VirtualMachineLocation string = deployment().location

@allowed([
  'AzureMonitorAgent'
  'LogAnalyticsAgent'
])
@description('Input the desired monitoring agent to send events and performance counters to a log analytics workspace.')
param VirtualMachineMonitoringAgent string = 'AzureMonitorAgent'

@secure()
@description('Local administrator password for the AVD session hosts')
param VirtualMachinePassword string

@description('The VM SKU for the AVD session hosts.')
param VirtualMachineSize string = 'Standard_D4ads_v5'

@description('The Local Administrator Username for the Session Hosts')
param VirtualMachineUsername string

/*  BEGIN BATCHING SESSION HOSTS */
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var MaxResourcesPerTemplateDeployment = 79 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var DivisionValue = SessionHostCount / MaxResourcesPerTemplateDeployment // This determines if any full batches are required.
var DivisionRemainderValue = SessionHostCount % MaxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var SessionHostBatchCount = DivisionRemainderValue > 0 ? DivisionValue + 1 : DivisionValue // This determines the total number of batches needed, whether full and / or partial.
/*  END BATCHING SESSION HOSTS */

/*  BEGIN BATCHING AVAILABILITY SETS */
// The following variables are used to determine the number of availability sets.
var MaxAvSetMembers = 200 // This is the max number of session hosts that can be deployed in an availability set.
var BeginAvSetRange = SessionHostIndex / MaxAvSetMembers // This determines the availability set to start with.
var EndAvSetRange = (SessionHostCount + SessionHostIndex) / MaxAvSetMembers // This determines the availability set to end with.
var AvailabilitySetsCount = length(range(BeginAvSetRange, (EndAvSetRange - BeginAvSetRange) + 1))
/*  END BATCHING AVAILABILITY SETS */

var AppGroupName = 'dag${NamingStandard}${Locations[ControlPlaneLocation].acronym}'
var AvailabilitySetsPrefix = 'as${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var AutomationAccountName = 'aa${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var DeploymentScriptNamePrefix = 'ds${NamingStandard}${Locations[VirtualMachineLocation].acronym}-'
var DesktopVirtualizationPowerOnContributorRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', '489581de-a3bd-480d-9518-53dea7416b33')
var DiskEncryptionSetName = 'des${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var DiskName = 'disk${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var FileShareNames = {
  CloudCacheProfileContainer: [
    'profile-containers'
  ]
  CloudCacheProfileOfficeContainer: [
    'office-containers'
    'profile-containers'
  ]
  ProfileContainer: [
    'profile-containers'
  ]
  ProfileOfficeContainer: [
    'office-containers'
    'profile-containers'
  ]
}
var FileShares = FileShareNames[FslogixSolution]
var Fslogix = FslogixStorage == 'None' || !contains(ActiveDirectorySolution, 'DomainServices') ? false : true
var HostPoolName = 'hp${NamingStandard}${Locations[ControlPlaneLocation].acronym}'
var KeyVaultName = 'kv${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var Locations = loadJsonContent('artifacts/locations.json')
var LogAnalyticsWorkspaceName = 'law${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var ManagementVmName = '${VmName}mgt'
var NamingStandard = '-avd-${Identifier}-${Environment}-${StampIndex}-'
var NetAppAccountName = 'naa${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var NetAppCapacityPoolName = 'nacp${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var Netbios = split(DomainName, '.')[0]
var PooledHostPool = split(HostPoolType, ' ')[0] == 'Pooled' ? true : false
var PrivateEndpoint = contains(FslogixStorage, 'PrivateEndpoint') ? true : false
var ReaderRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var RecoveryServicesVaultName = 'rsv${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var ResourceGroupControlPlane = 'rg${NamingStandard}${Locations[ControlPlaneLocation].acronym}-controlPlane'
var ResourceGroupHosts = 'rg${NamingStandard}${Locations[VirtualMachineLocation].acronym}-hosts'
var ResourceGroupManagement = 'rg${NamingStandard}${Locations[VirtualMachineLocation].acronym}-management'
var ResourceGroups = Fslogix ? [
  ResourceGroupControlPlane
  ResourceGroupHosts
  ResourceGroupManagement
  ResourceGroupStorage
] : [
  ResourceGroupControlPlane
  ResourceGroupHosts
  ResourceGroupManagement
]
var ResourceGroupStorage = 'rg${NamingStandard}${Locations[VirtualMachineLocation].acronym}-storage'
var SecurityPrincipalIdsCount = length(SecurityPrincipalObjectIds)
var SecurityPrincipalNamesCount = length(SecurityPrincipalNames)
var Sentinel = empty(SentinelLogAnalyticsWorkspaceResourceId) ? false : true
var SentinelLogAnalyticsWorkspaceName = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[8]
var SentinelResourceGroup = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[4]
var SentinelSubscriptionId = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[2]
var StorageAccountPrefix = 'sa${Identifier}${Environment}${StampIndex}${Locations[VirtualMachineLocation].acronym}'
var StorageSku = FslogixStorage == 'None' ? 'None' : split(FslogixStorage, ' ')[1]
var StorageSolution = split(FslogixStorage, ' ')[0]
var StorageSuffix = environment().suffixes.storage
var UserAssignedIdentityName = 'uai${NamingStandard}${Locations[VirtualMachineLocation].acronym}'
var VmName = 'vm${Identifier}${Environment}${Locations[VirtualMachineLocation].acronym}${StampIndex}'
var VmTemplate = '{"domain":"${DomainName}","galleryImageOffer":"${ImageOffer}","galleryImagePublisher":"${ImagePublisher}","galleryImageSKU":"${ImageSku}","imageType":"Gallery","imageUri":null,"customImageId":null,"namePrefix":"${VmName}","osDiskType":"${DiskSku}","useManagedDisks":true,"VirtualMachineSize":{"id":"${VirtualMachineSize}","cores":null,"ram":null},"galleryItemId":"${ImagePublisher}.${ImageOffer}${ImageSku}"}'
var WorkspaceName = 'ws${NamingStandard}${Locations[ControlPlaneLocation].acronym}'

// Resource Groups needed for the solution
resource resourceGroups 'Microsoft.Resources/resourceGroups@2020-10-01' = [for i in range(0, length(ResourceGroups)): {
  name: ResourceGroups[i]
  location: contains(ResourceGroups[i], 'controlPlane') ? ControlPlaneLocation : VirtualMachineLocation
  tags: contains(Tags, 'Microsoft.Resources/resourceGroups') ? Tags['Microsoft.Resources/resourceGroups'] : {}
}]

module userAssignedIdentity 'modules/userAssignedManagedIdentity.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'UserAssignedIdentity_${Timestamp}'
  params: {
    DiskEncryption: DiskEncryption
    DrainMode: DrainMode
    Fslogix: Fslogix
    FslogixStorage: FslogixStorage
    Location: VirtualMachineLocation
    UserAssignedIdentityName: UserAssignedIdentityName
    ResourceGroupStorage: ResourceGroupStorage
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? Tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {})
    Timestamp: Timestamp
    VirtualNetworkResourceGroupName: split(SubnetResourceId, '/')[4]
  }
  dependsOn: [
    resourceGroups
  ]
}

// Role Assignment for Validation
// This role assignment is required to collect validation information
resource roleAssignment_validation 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(ResourceGroupManagement, UserAssignedIdentityName, ReaderRoleDefinitionResourceId, subscription().id)
  properties: {
    roleDefinitionId: ReaderRoleDefinitionResourceId
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deployment Validation
// This module validates the selected parameter values and collects required data
module validations 'modules/validations.bicep' = {
  scope: resourceGroup(ResourceGroupManagement)
  name: 'Validations_${Timestamp}'
  params: {
    Availability: Availability
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskSku: DiskSku
    DomainName: DiskName
    Fslogix: Fslogix
    ActiveDirectorySolution: ActiveDirectorySolution
    HostPoolType: HostPoolType
    ImageSku: ImageSku
    KerberosEncryption: KerberosEncryption
    Location: VirtualMachineLocation
    SecurityPrincipalIdsCount: SecurityPrincipalIdsCount
    SecurityPrincipalNamesCount: SecurityPrincipalNamesCount
    SessionHostCount: SessionHostCount
    StorageCount: StorageCount
    StorageSolution: StorageSolution
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {})
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
    VirtualMachineSize: VirtualMachineSize
    VnetName: split(SubnetResourceId, '/')[8]
    VnetResourceGroupName: split(SubnetResourceId, '/')[4]
  }
  dependsOn: [
    resourceGroups
  ]
}

// Role Assignment required for Start VM On Connect
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(AvdObjectId, DesktopVirtualizationPowerOnContributorRoleDefinitionResourceId, subscription().id)
  properties: {
    roleDefinitionId: DesktopVirtualizationPowerOnContributorRoleDefinitionResourceId
    principalId: AvdObjectId
  }
}

// Automation Account required for the AVD Scaling Tool and the Auto Increase Premium File Share Quota solution
module automationAccount 'modules/automationAccount.bicep' = if (PooledHostPool || contains(FslogixSolution, 'AzureStorageAccount Premium')) {
  name: 'AutomationAccount_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    AutomationAccountName: AutomationAccountName
    Location: VirtualMachineLocation
    LogAnalyticsWorkspaceResourceId: Monitoring ? logAnalyticsWorkspace.outputs.ResourceId : ''
    Monitoring: Monitoring
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Automation/automationAccounts') ? Tags['Microsoft.Automation/automationAccounts'] : {})
  }
  dependsOn: [
    resourceGroups
  ]
}

// AVD Control Plane Resources
// This module deploys the host pool, desktop application group, & workspace
module controlPlane 'modules/controlPlane.bicep' = {
  name: 'ControlPlane_${Timestamp}'
  scope: resourceGroup(ResourceGroupControlPlane)
  params: {
    AppGroupName: AppGroupName
    CustomRdpProperty: CustomRdpProperty
    ActiveDirectorySolution: ActiveDirectorySolution
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    Location: ControlPlaneLocation
    LogAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.ResourceId
    MaxSessionLimit: MaxSessionLimit
    SecurityPrincipalIds: SecurityPrincipalObjectIds
    TagsApplicationGroup: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.DesktopVirtualization/applicationGroups') ? Tags['Microsoft.DesktopVirtualization/applicationGroups'] : {})
    TagsHostPool: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.DesktopVirtualization/hostPools') ? Tags['Microsoft.DesktopVirtualization/hostPools'] : {})
    TagsWorkspace: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.DesktopVirtualization/workspaces') ? Tags['Microsoft.DesktopVirtualization/workspaces'] : {})
    ValidationEnvironment: ValidationEnvironment
    VmTemplate: VmTemplate
    WorkspaceName: WorkspaceName
  }
  dependsOn: [
    resourceGroups
  ]
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with Windows Events & Windows Performance Counters plus diagnostic settings on the required resources 
module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = if (Monitoring) {
  name: 'Monitoring_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    LogAnalyticsWorkspaceRetention: LogAnalyticsWorkspaceRetention
    LogAnalyticsWorkspaceSku: LogAnalyticsWorkspaceSku
    Location: VirtualMachineLocation
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.OperationalInsights/workspaces') ? Tags['Microsoft.OperationalInsights/workspaces'] : {})
  }
  dependsOn: [
    resourceGroups
  ]
}

module diskEncryption 'modules/diskEncryption.bicep' = if (DiskEncryption) {
  name: 'DiskEncryption_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryptionSetName: DiskEncryptionSetName
    Environment: Environment
    KeyVaultName: KeyVaultName
    Location: VirtualMachineLocation
    TagsDeploymentScripts: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {})
    TagsDiskEncryptionSet: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Compute/diskEncryptionSets') ? Tags['Microsoft.Compute/diskEncryptionSets'] : {})
    TagsKeyVault: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.KeyVault/vaults') ? Tags['Microsoft.KeyVault/vaults'] : {})
    Timestamp: Timestamp
    UserAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
  }
}

module fslogix 'modules/fslogix/fslogix.bicep' = if (Fslogix) {
  name: 'FSLogix_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    Availability: Availability
    ActiveDirectoryConnection: validations.outputs.anfActiveDirectory
    AzureFilesPrivateDnsZoneResourceId: AzureFilesPrivateDnsZoneResourceId
    ClientId: userAssignedIdentity.outputs.clientId
    DelegatedSubnetId: validations.outputs.anfSubnetId
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: diskEncryption.outputs.diskEncryptionSetResourceId
    DiskSku: DiskSku
    DnsServers: validations.outputs.anfDnsServers
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    ActiveDirectorySolution: ActiveDirectorySolution
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    FslogixSolution: FslogixSolution
    FslogixStorage: FslogixStorage
    KerberosEncryption: KerberosEncryption
    Location: VirtualMachineLocation
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    NetAppAccountName: NetAppAccountName
    NetAppCapacityPoolName: NetAppCapacityPoolName
    Netbios: Netbios
    OuPath: OuPath
    PrivateEndpoint: PrivateEndpoint
    ResourceGroupManagement: ResourceGroupManagement
    ResourceGroupStorage: ResourceGroupStorage
    SecurityPrincipalIds: SecurityPrincipalObjectIds
    SecurityPrincipalNames: SecurityPrincipalNames
    SmbServerLocation: Locations[VirtualMachineLocation].acronym
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSku: StorageSku
    StorageSolution: StorageSolution
    Subnet: split(SubnetResourceId, '/')[10]
    TagsDeploymentScripts: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {})
    TagsNetAppAccount: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.NetApp/netAppAccounts') ? Tags['Microsoft.NetApp/netAppAccounts'] : {})
    TagsNetworkInterfaces: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Network/networkInterfaces') ? Tags['Microsoft.Network/networkInterfaces'] : {})
    TagsPrivateEndpoints: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Network/privateEndpoints') ? Tags['Microsoft.Network/privateEndpoints'] : {})
    TagsStorageAccounts: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Storage/storageAccounts') ? Tags['Microsoft.Storage/storageAccounts'] : {})
    TagsVirtualMachines: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Compute/virtualMachines') ? Tags['Microsoft.Compute/virtualMachines'] : {})
    Timestamp: Timestamp
    TrustedLaunch: validations.outputs.trustedLaunch
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.id
    VirtualNetwork: split(SubnetResourceId, '/')[8]
    VirtualNetworkResourceGroup: split(SubnetResourceId, '/')[4]
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineUsername: VirtualMachineUsername
  }
  dependsOn: [
    diskEncryption
    userAssignedIdentity
  ]
}

module sentinel 'modules/sentinel.bicep' = {
  name: 'Sentinel_${Timestamp}'
  scope: resourceGroup(SentinelSubscriptionId, SentinelResourceGroup)
  params: {
    Sentinel: Sentinel
    SentinelLogAnalyticsWorkspaceName: SentinelLogAnalyticsWorkspaceName
    SentinelLogAnalyticsWorkspaceResourceGroupName: SentinelResourceGroup
  }
  dependsOn: [
    resourceGroups
  ]
}

module sessionHosts 'modules/sessionHosts/sessionHosts.bicep' = {
  name: 'SessionHosts_${Timestamp}'
  scope: resourceGroup(ResourceGroupHosts)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AcceleratedNetworking: validations.outputs.acceleratedNetworking
    Availability: Availability
    AvailabilityZones: validations.outputs.availabilityZones
    AvailabilitySetsCount: AvailabilitySetsCount
    AvailabilitySetsPrefix: AvailabilitySetsPrefix
    AvailabilitySetsIndex: BeginAvSetRange
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    DiskEncryption: DiskEncryption
    DiskEncryptionSetResourceId: diskEncryption.outputs.diskEncryptionSetResourceId
    DiskName: DiskName
    DiskSku: DiskSku
    DivisionRemainderValue: DivisionRemainderValue
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
    ImageVersionResourceId: ImageVersionResourceId
    Location: VirtualMachineLocation
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagedIdentityResourceId: userAssignedIdentity.outputs.id
    MaxResourcesPerTemplateDeployment: MaxResourcesPerTemplateDeployment
    Monitoring: Monitoring
    NamingStandard: NamingStandard
    NetAppFileShares: Fslogix ? fslogix.outputs.netAppShares : [
      'None'
    ]
    OuPath: OuPath
    PooledHostPool: PooledHostPool
    ResourceGroupHosts: ResourceGroupHosts
    ResourceGroupManagement: ResourceGroupManagement
    SecurityPrincipalObjectIds: SecurityPrincipalObjectIds
    Sentinel: Sentinel
    SentinelWorkspaceId: sentinel.outputs.sentinelWorkspaceId
    SentinelWorkspaceResourceId: sentinel.outputs.sentinelWorkspaceResourceId
    SessionHostBatchCount: SessionHostBatchCount
    SessionHostIndex: SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: split(SubnetResourceId, '/')[10]
    TagsAvailabilitySets: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Compute/availabilitySets') ? Tags['Microsoft.Compute/availabilitySets'] : {})
    TagsDeploymentScripts: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Resources/deploymentScripts') ? Tags['Microsoft.Resources/deploymentScripts'] : {})
    TagsNetworkInterfaces: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Network/networkInterfaces') ? Tags['Microsoft.Network/networkInterfaces'] : {})
    TagsVirtualMachines: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Compute/virtualMachines') ? Tags['Microsoft.Compute/virtualMachines'] : {})
    Timestamp: Timestamp
    TrustedLaunch: validations.outputs.trustedLaunch
    VirtualMachinePassword: VirtualMachinePassword
    VirtualMachineSize: VirtualMachineSize
    VirtualMachineUsername: VirtualMachineUsername
    VirtualNetwork: split(SubnetResourceId, '/')[8]
    VirtualNetworkResourceGroup: split(SubnetResourceId, '/')[4]
    VmName: VmName
  }
  dependsOn: [
    diskEncryption
    logAnalyticsWorkspace
    resourceGroups
  ]
}

module backup 'modules/backup/backup.bicep' = if (RecoveryServices) {
  name: 'Backup_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    DivisionRemainderValue: DivisionRemainderValue
    FileShares: FileShares
    Fslogix: Fslogix
    Location: VirtualMachineLocation
    MaxResourcesPerTemplateDeployment: MaxResourcesPerTemplateDeployment
    RecoveryServicesVaultName: RecoveryServicesVaultName
    SessionHostBatchCount: SessionHostBatchCount
    SessionHostIndex: SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageResourceGroupName: ResourceGroupStorage
    StorageSolution: StorageSolution
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.RecoveryServices/vaults') ? Tags['Microsoft.RecoveryServices/vaults'] : {})
    Timestamp: Timestamp
    TimeZone: Locations[VirtualMachineLocation].timeZone
    VmName: VmName
    VmResourceGroupName: ResourceGroupHosts
  }
  dependsOn: [
    fslogix
    sessionHosts
  ]
}

module scalingTool 'modules/scalingTool.bicep' = if (ScalingTool && PooledHostPool) {
  name: 'ScalingTool_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: ScalingBeginPeakTime
    EndPeakTime: ScalingEndPeakTime
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroupManagement
    LimitSecondsToForceLogOffUser: ScalingLimitSecondsToForceLogOffUser
    Location: VirtualMachineLocation
    MinimumNumberOfRdsh: ScalingMinimumNumberOfRdsh
    ResourceGroupHosts: ResourceGroupHosts
    ResourceGroupManagement: ResourceGroupManagement
    SessionThresholdPerCPU: ScalingSessionThresholdPerCPU
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Automation/automationAccounts') ? Tags['Microsoft.Automation/automationAccounts'] : {})
    TimeDifference: Locations[VirtualMachineLocation].timeDifference
    TimeZone: Locations[VirtualMachineLocation].timeZone
  }
  dependsOn: [
    automationAccount
    backup
    sessionHosts
  ]
}

module autoIncreasePremiumFileShareQuota 'modules/autoIncreasePremiumFileShareQuota.bicep' = if (contains(FslogixStorage, 'AzureStorageAccount Premium') && StorageCount > 0) {
  name: 'AutoIncreasePremiumFileShareQuota_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AutomationAccountName: AutomationAccountName
    Location: VirtualMachineLocation
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageResourceGroupName: ResourceGroupStorage
    Tags: union({
      'cm-resource-parent': '${subscription().id}}/resourceGroups/${ResourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${HostPoolName}'
    }, contains(Tags, 'Microsoft.Automation/automationAccounts') ? Tags['Microsoft.Automation/automationAccounts'] : {})
    Timestamp: Timestamp
    TimeZone: Locations[VirtualMachineLocation].timeZone
  }
  dependsOn: [
    automationAccount
    backup
    fslogix
  ]
}
