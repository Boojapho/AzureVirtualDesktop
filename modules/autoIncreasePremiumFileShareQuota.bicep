param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AutomationAccountName string
param Location string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageResourceGroupName string
param Tags object
param Timestamp string
param TimeZone string

var RunbookName = 'Auto-Increase-Premium-File-Share-Quota'
var SubscriptionId = subscription().subscriptionId

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: AutomationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: RunbookName
  location: Location
  tags: Tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${_artifactsLocation}Set-FileShareScaling.ps1${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

module schedules 'schedules.bicep' = [for i in range(StorageIndex, StorageCount): {
  name: 'Schedules_${i}_${Timestamp}'
  params: {
    AutomationAccountName: automationAccount.name
    StorageAccountName: '${StorageAccountPrefix}${padLeft(i, 2, '0')}'
    TimeZone: TimeZone
  }
}]

module jobSchedules 'jobSchedules.bicep' = [for i in range(StorageIndex, StorageCount): {
  name: 'JobSchedules_${i}_${Timestamp}'
  params: {
    AutomationAccountName: automationAccount.name
    Environment: environment().name
    RunbookName: RunbookName
    ResourceGroupName: StorageResourceGroupName
    StorageAccountName: '${StorageAccountPrefix}${padLeft(i, 2, '0')}'
    SubscriptionId: SubscriptionId
    Timestamp: Timestamp
  }
  dependsOn: [
    runbook
    schedules
  ]
}]

module roleAssignment 'roleAssignment.bicep' = {
  name: 'RoleAssignment_${StorageResourceGroupName}_${Timestamp}'
  scope: resourceGroup(StorageResourceGroupName)
  params: {
    PrincipalId: automationAccount.identity.principalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab') // Storage Account Contributor
  }
}
