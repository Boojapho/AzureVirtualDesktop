param Arguments string
param Location string
param Name string
param ScriptContainerUri string
@secure()
param ScriptContainerSasToken string
param ScriptName string
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
  tags: {}
  properties: {
    azPowerShellVersion: '9.4'
    cleanupPreference: 'Always'
    primaryScriptUri: '${ScriptContainerUri}${ScriptName}?${ScriptContainerSasToken}'
    arguments: Arguments
    forceUpdateTag: Timestamp
    retentionInterval: 'PT2H'
    timeout: 'PT30M'
  }
}
