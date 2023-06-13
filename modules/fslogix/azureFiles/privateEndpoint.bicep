param AzureFilesPrivateDnsZoneResourceId string
param Location string
param StorageAccountId string
param StorageAccountName string
param Subnet string
param Tags object
param VirtualNetwork string
param VirtualNetworkResourceGroup string

var SubnetId = resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: 'pe-${StorageAccountName}'
  location: Location
  tags: Tags
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${StorageAccountName}_${guid(StorageAccountName)}'
        properties: {
          privateLinkServiceId: StorageAccountId
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: StorageAccountName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: AzureFilesPrivateDnsZoneResourceId
        }
      }
    ]
  }
}
