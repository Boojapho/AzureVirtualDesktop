param Arguments string
param Location string
param Name string
param Script string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: Name
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: Tags
  properties: {
    arguments: Arguments
    azPowerShellVersion: '9.4'
    cleanupPreference: 'Always'
    forceUpdateTag: Timestamp
    retentionInterval: 'PT2H'
    scriptContent: Script
    timeout: 'PT30M'
  }
}

output properties object = deploymentScript.properties.outputs
