param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param DeploymentScriptNamePrefix string
param Environment string
param KeyVaultName string
param Location string
param ManagedIdentityResourceId string
param ResourceGroupManagement string
param Timestamp string


resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: KeyVaultName
  location: Location
  tags: {}
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
    enablePurgeProtection: Environment == 'd' || Environment == 't' ? null : true
    enableRbacAuthorization: true
    enableSoftDelete: Environment == 'd' || Environment == 't' ? false : true
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: Environment == 'd' || Environment == 't' ? null : 90
    tenantId: subscription().tenantId
  }
}

module deploymentScript 'deploymentScript.bicep' = {
  name: 'DeploymentScript_KeyVault-KEK_${Timestamp}'
  scope: resourceGroup(ResourceGroupManagement)
  params: {
    Arguments: '-KeyVault ${KeyVaultName}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}kek'
    ScriptContainerSasToken: _artifactsLocationSasToken
    ScriptContainerUri: _artifactsLocation
    ScriptName: 'New-AzureKeyEncryptionKey.ps1'
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: ManagedIdentityResourceId
  }
}
