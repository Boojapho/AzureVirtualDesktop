param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param Availability string
param AzureFilesPrivateDnsZoneResourceId string
param ClientId string
param DeploymentScriptNamePrefix string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainServices string
param FileShares array
param FslogixShareSizeInGB int
param FslogixSolution string
param FslogixStorage string
param KerberosEncryption string
param Location string
param ManagementVmName string
param Netbios string
param OuPath string
param PrivateEndpoint bool
param ResourceGroupManagement string
param ResourceGroupStorage string
param SecurityPrincipalIds array
param SecurityPrincipalNames array
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

var Endpoint = split(FslogixStorage, ' ')[2]
var RoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb') // Storage File Data SMB Share Contributor 
var SmbMultiChannel = {
  multichannel: {
    enabled: true
  }
}
var SmbSettings = {
  versions: 'SMB3.0;SMB3.1.1;'
  authenticationMethods: 'NTLMv2;Kerberos;'
  kerberosTicketEncryption: KerberosEncryption == 'RC4' ? 'RC4-HMAC;' : 'AES-256;'
  channelEncryption: 'AES-128-CCM;AES-128-GCM;AES-256-GCM;'
}
var StorageRedundancy = Availability == 'AvailabilityZones' ? '_ZRS' : '_LRS'
var SubnetId = resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
var VirtualNetworkRules = {
  PrivateEndpoint: []
  PublicEndpoint: []
  ServiceEndpoint: [
    {
      id: SubnetId
      action: 'Allow'
    }
  ]
}

resource storageAccounts 'Microsoft.Storage/storageAccounts@2021-02-01' = [for i in range(0, StorageCount): {
  name: '${StorageAccountPrefix}${i + StorageIndex}'
  location: Location
  tags: Tags
  sku: {
    name: '${StorageSku}${StorageRedundancy}'
  }
  kind: StorageSku == 'Standard' ? 'StorageV2' : 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: VirtualNetworkRules[Endpoint]
      ipRules: []
      defaultAction: Endpoint == 'PublicEndpoint' ? 'Allow' : 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: DomainServices == 'AzureActiveDirectory' ? 'AADDS' : 'None'
    }
    largeFileSharesState: StorageSku == 'Standard' ? 'Enabled' : null
  }
}]

// Assigns the SMB Contributor role to the Storage Account so users can save their profiles to the file share using FSLogix
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, StorageCount): {
  scope: storageAccounts[i]
  name: guid(SecurityPrincipalIds[i], RoleDefinitionId, storageAccounts[i].id)
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: SecurityPrincipalIds[i]
  }
}]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = [for i in range(0, StorageCount): {
  parent: storageAccounts[i]
  name: 'default'
  properties: {
    protocolSettings: {
      smb: StorageSku == 'Standard' ? SmbSettings : union(SmbSettings, SmbMultiChannel)
    }
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}]

module shares 'shares.bicep' = [for i in range(0, StorageCount): {
  name: 'FileShares_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupStorage)
  params: {
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    StorageAccountName: storageAccounts[i].name
    StorageSku: StorageSku
  }
  dependsOn: [
    roleAssignment
  ]
}]

module privateEndpoint 'privateEndpoint.bicep' = [for i in range(0, StorageCount): if (PrivateEndpoint) {
  name: 'PrivateEndpoints_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    Location: Location
    AzureFilesPrivateDnsZoneResourceId: AzureFilesPrivateDnsZoneResourceId
    StorageAccountId: storageAccounts[i].id
    StorageAccountName: storageAccounts[i].name
    Subnet: Subnet
    Tags: Tags
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
}]

module ntfsPermissions '../ntfsPermissions.bicep' = if (!contains(DomainServices, 'None')) {
  name: 'FslogixNtfsPermissions_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    CommandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-NtfsPermissions.ps1 -ClientId ${ClientId} -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -DomainServices ${DomainServices} -Environment ${environment().name} -FslogixSolution ${FslogixSolution} -KerberosEncryptionType ${KerberosEncryption} -Netbios ${Netbios} -OuPath "${OuPath}" -SecurityPrincipalNames "${SecurityPrincipalNames}" -StorageAccountPrefix ${StorageAccountPrefix} -StorageAccountResourceGroupName ${ResourceGroupStorage} -StorageCount ${StorageCount} -StorageIndex ${StorageIndex} -StorageSolution ${StorageSolution} -StorageSuffix ${environment().suffixes.storage} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId}'
    DeploymentScriptNamePrefix: DeploymentScriptNamePrefix
    Location: Location
    ManagementVmName: ManagementVmName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
  dependsOn: [
    shares
    privateEndpoint
  ]
}
