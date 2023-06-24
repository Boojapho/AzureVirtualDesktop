param DiskEncryption bool
param DiskEncryptionSetResourceId string
param DiskSku string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param Location string
param ManagementVmName string
param NamingStandard string
param Subnet string
param TagsNetworkInterfaces object
param TagsVirtualMachines object
param Timestamp string
param TrustedLaunch string
param UserAssignedIdentityResourceId string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VirtualMachinePassword string
param VirtualMachineUsername string

var NicName = 'nic-${NamingStandard}-mgt'

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: NicName
  location: Location
  tags: TagsNetworkInterfaces
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: ManagementVmName
  location: Location
  tags: TagsVirtualMachines
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        deleteOption: 'Delete'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          diskEncryptionSet: DiskEncryption ? {
            id: DiskEncryptionSetResourceId
          } : null
          storageAccountType: DiskSku
        }
        name: 'disk-${NamingStandard}-mgt'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: ManagementVmName
      adminUsername: VirtualMachineUsername
      adminPassword: VirtualMachinePassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
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
      encryptionAtHost: DiskEncryption
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Server'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: Location
  tags: TagsVirtualMachines
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
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
}
