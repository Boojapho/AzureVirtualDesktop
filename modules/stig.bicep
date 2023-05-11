param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AutomationAccountName string
param ConfigurationName string
param Location string
param Timestamp string


var Modules = [
  {
    name: 'AccessControlDSC'
    version: '1.4.1'
  }
  {
    name: 'AuditPolicyDsc'
    version: '1.4.0.0'
  }
  {
    name: 'AuditSystemDsc'
    version: '1.1.0'
  }
  {
    name: 'CertificateDsc'
    version: '5.0.0'
  }
  {
    name: 'ComputerManagementDsc'
    version: '8.4.0'
  }
  {
    name: 'FileContentDsc'
    version: '1.3.0.151'
  }
  {
    name: 'GPRegistryPolicyDsc'
    version: '1.2.0'
  }
  {
    name: 'nx'
    version: '1.0'
  }
  {
    name: 'PSDscResources'
    version: '2.12.0.0'
  }
  {
    name: 'SecurityPolicyDsc'
    version: '2.10.0.0'
  }
  {
    name: 'SqlServerDsc'
    version: '13.3.0'
  }
  {
    name: 'WindowsDefenderDsc'
    version: '2.1.0'
  }
  {
    name: 'xDnsServer'
    version: '1.16.0.0'
  }
  {
    name: 'xWebAdministration'
    version: '3.2.0'
  }
  {
    name: 'PowerSTIG'
    version: '4.10.1'
  }
]


resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: AutomationAccountName
}

@batchSize(1)
resource modules 'Microsoft.Automation/automationAccounts/modules@2019-06-01' = [for Module in Modules: {
  parent: automationAccount
  name: Module.name
  location: Location
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/${Module.name}/${Module.version}'
      version: Module.version
    }
  }
}]

resource configuration 'Microsoft.Automation/automationAccounts/configurations@2019-06-01' = {
  parent: automationAccount
  name: ConfigurationName
  location: Location
  properties: {
    source: {
      type: 'uri'
      value: '${_artifactsLocation}Windows10.ps1${_artifactsLocationSasToken}'
      version: Timestamp
    }
    parameters: {}
    description: 'Hardens the VM using the Azure STIG Template'
  }
  dependsOn: [
    modules
  ]
}

resource compilationJob 'Microsoft.Automation/automationAccounts/compilationjobs@2019-06-01' = {
  parent: automationAccount
  name: guid(Timestamp)
  location: Location
  properties: {
    configuration: {
      name: configuration.name
    }
  }
  dependsOn: [
    modules
  ]
}
