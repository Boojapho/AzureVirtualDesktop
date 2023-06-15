param DiskEncryptionKeyExpirationInDays int
param KeyDoesNotExist bool
param KeyVaultName string
param Tags object
param Time string = utcNow()

var DiskEncryptionKeyExpirationInEpoch = dateTimeToEpoch(dateTimeAdd(Time, 'P${string(DiskEncryptionKeyExpirationInDays)}D'))

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: KeyVaultName
}

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = if(KeyDoesNotExist) {
  parent: vault
  name: 'DiskEncryptionKey'
  tags: Tags
  properties: {
    attributes: {
      enabled: true
      exp: DiskEncryptionKeyExpirationInEpoch
      nbf: null
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(DiskEncryptionKeyExpirationInDays)}D'
      }
      lifetimeActions: [
        {
          action: {
            type: 'notify'
          }
          trigger: {
            timeBeforeExpiry: 'P10D'
          }
        }
        {
          action: {
            type: 'rotate'
          }
          trigger: {
            timeAfterCreate: 'P${string(DiskEncryptionKeyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

output keyUriWithVersion string = key.properties.keyUriWithVersion
