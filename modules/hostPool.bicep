param AppGroupName string
param CustomRdpProperty string
param DomainServices string
param HostPoolName string
param HostPoolType string
param Location string
param LogAnalyticsWorkspaceResourceId string
param MaxSessionLimit int
param SecurityPrincipalIds array
param StartVmOnConnect bool
param Tags object
param Timestamp string = utcNow('u')
param ValidationEnvironment bool
param VmTemplate string
param WorkspaceName string


var CustomRdpProperty_Complete = contains(DomainServices, 'None') ? '${CustomRdpProperty}targetisaadjoined:i:1' : CustomRdpProperty
var DesktopVirtualizationUserRoleDefinitionResourceId = resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
var HostPoolLogs = [
  {
    category: 'Checkpoint'
    enabled: true
  }
  {
    category: 'Error'
    enabled: true
  }
  {
    category: 'Management'
    enabled: true
  }
  {
    category: 'Connection'
    enabled: true
  }
  {
    category: 'HostRegistration'
    enabled: true
  }
  {
    category: 'AgentHealthStatus'
    enabled: true
  }
]


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  name: HostPoolName
  location: Location
  tags: Tags
  properties: {
    hostPoolType: split(HostPoolType, ' ')[0]
    maxSessionLimit: MaxSessionLimit
    loadBalancerType: contains(HostPoolType, 'Pooled') ? split(HostPoolType, ' ')[1] : 'Persistent'
    validationEnvironment: ValidationEnvironment
    registrationInfo: {
      expirationTime: dateTimeAdd(Timestamp, 'PT2H')
      registrationTokenOperation: 'Update'
    }
    preferredAppGroupType: 'Desktop'
    customRdpProperty: CustomRdpProperty_Complete
    personalDesktopAssignmentType: contains(HostPoolType, 'Personal') ? split(HostPoolType, ' ')[1] : null
    startVMOnConnect: StartVmOnConnect // https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect
    vmTemplate: VmTemplate

  }
}

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${HostPoolName}'
  scope: hostPool
  properties: {
    logs: HostPoolLogs
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  name: AppGroupName
  location: Location
  tags: Tags
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
  }
}

resource appGroupAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(SecurityPrincipalIds)): {
  scope: appGroup
  name: guid(SecurityPrincipalIds[i], DesktopVirtualizationUserRoleDefinitionResourceId, AppGroupName)
  properties: {
    roleDefinitionId: DesktopVirtualizationUserRoleDefinitionResourceId
    principalId: SecurityPrincipalIds[i]
  }
}]

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' = {
  name: WorkspaceName
  location: Location
  tags: Tags
  properties: {
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${WorkspaceName}'
  scope: workspace
  properties: {
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}
