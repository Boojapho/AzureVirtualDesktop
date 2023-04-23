param Location string
param ManagedIdentityName string


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}

output principalId string = userAssignedIdentity.properties.principalId
output resourceIdentifier string = userAssignedIdentity.id
