param AutomationAccountName string
param Environment string
param ResourceGroupName string
param RunbookName string
param StorageAccountName string
param SubscriptionId string
param Timestamp string

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: AutomationAccountName
}

resource jobSchedules_ProfileContainers 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  name: guid(Timestamp, RunbookName, StorageAccountName, 'ProfileContainers', string(i))
  properties: {
    parameters: {
      Environment: Environment
      FileShareName: 'profilecontainers'
      ResourceGroupName: ResourceGroupName
      StorageAccountName: StorageAccountName
      SubscriptionId: SubscriptionId
    }
    runbook: {
      name: RunbookName
    }
    runOn: null
    schedule: {
      name: '${StorageAccountName}_ProfileContainers_${(i + 1) * 15}min'
    }
  }
}]

resource jobSchedules_OfficeContainers 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  name: guid(Timestamp, RunbookName, StorageAccountName, 'OfficeContainers', string(i))
  properties: {
    parameters: {
      Environment: Environment
      FileShareName: 'officecontainers'
      ResourceGroupName: ResourceGroupName
      StorageAccountName: StorageAccountName
      SubscriptionId: SubscriptionId
    }
    runbook: {
      name: RunbookName
    }
    runOn: null
    schedule: {
      name: '${StorageAccountName}_OfficeContainers_${(i + 1) * 15}min'
    }
  }
}]
