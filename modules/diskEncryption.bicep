param DeploymentScriptNamePrefix string
param DiskEncryptionKeyExpirationInDays int = 30
param DiskEncryptionSetName string
param Environment string
param KeyVaultName string
param Location string
param Tags object
param Timestamp string
param UserAssignedIdentityPrincipalId string
param UserAssignedIdentityResourceId string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: KeyVaultName
  location: Location
  tags: {}
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: Environment == 'd' || Environment == 't' ? 7 : 90
    tenantId: subscription().tenantId
  }
}

module keyValidation 'deploymentScript.bicep' = {
  name: 'DeploymentScript_DiskEncryptionKeyValidation_${Timestamp}'
  params: {
    Arguments: '-VaultName ${vault.name}'
    Location: Location
    Name: '${DeploymentScriptNamePrefix}diskEncryptionKeyValidation'
    Script: 'param([string]$VaultName); $ErrorActionPreference = "Stop"; $Key = Get-AzKeyVaultKey -VaultName $VaultName | Where-Object {$_.Name -eq "DiskEncryptionKey"}; $DeploymentScriptOutputs = @{}; if($Key){$Exists = "True"}else{$Exists = "False"}; $DeploymentScriptOutputs["exists"] = $Exists'
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
  }
}

module key 'key.bicep' = {
  name: 'DiskEncryptionKey'
  params: {
    DiskEncryptionKeyExpirationInDays: DiskEncryptionKeyExpirationInDays
    KeyDoesNotExist: keyValidation.outputs.properties.exists == 'False'
    KeyVaultName: KeyVaultName
    Tags: Tags
  }
}

module roleAssignment 'roleAssignment.bicep' = {
  name: 'RoleAssignment_${Timestamp}'
  params: {
    PrincipalId: UserAssignedIdentityPrincipalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
  }
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  name: DiskEncryptionSetName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: vault.id
      }
      keyUrl: key.outputs.keyUriWithVersion
    }
    encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
    federatedClientId: 'None'
    rotationToLatestKeyVersionEnabled: true
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.id
