param AutomationAccountName string
param Location string
param Name string
param Script string
@secure()
param ScriptContainerSasToken string
param ScriptContainerUri string
param Tags object

resource automationAccount 'Microsoft.Automation/automationAccounts@2019-06-01' existing = {
  name: AutomationAccountName
}

resource runbooks 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: Name
  location: Location
  tags: Tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${ScriptContainerUri}${Script}?${ScriptContainerSasToken}'
      version: '1.0.0.0'
    }
  }
}
