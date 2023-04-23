param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param MinimumNumberOfRdsh string
param ResourceGroupHosts string
param ResourceGroupManagement string
param RoleDefinitionIds object
param SessionThresholdPerCPU string
param TimeDifference string
param Time string = utcNow('u')
param TimeZone string


var RoleAssignments = [
  ResourceGroupHosts
  ResourceGroupManagement
]


resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: AutomationAccountName
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: 'AVD-Scaling-Tool'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${_artifactsLocation}Set-HostPoolScaling.ps1${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource schedules 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  name: '${HostPoolName}_${(i+1)*15}min'
  properties: {
    advancedSchedule: {}
    description: null
    expiryTime: null
    frequency: 'Hour'
    interval: 1
    startTime: dateTimeAdd(Time, 'PT${(i+1)*15}M')
    timeZone: TimeZone
  }
}]

resource jobSchedules 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: guid(Time, runbook.name, HostPoolName, string(i))
  properties: {
    parameters: {
      TenantId: subscription().tenantId
      SubscriptionId: subscription().subscriptionId
      EnvironmentName: environment().name
      ResourceGroupName: HostPoolResourceGroupName
      HostPoolName: HostPoolName
      MaintenanceTagName: 'Maintenance'
      TimeDifference: TimeDifference
      BeginPeakTime: BeginPeakTime
      EndPeakTime: EndPeakTime
      SessionThresholdPerCPU: SessionThresholdPerCPU
      MinimumNumberOfRDSH: MinimumNumberOfRdsh
      LimitSecondsToForceLogOffUser: LimitSecondsToForceLogOffUser
      LogOffMessageTitle: 'Machine is about to shutdown.'
      LogOffMessageBody: 'Your session will be logged off. Please save and close everything.'
    }
    runbook: {
      name: runbook.name
    }
    runOn: null
    schedule: {
      name: schedules[i].name
    }
  }
}]

// Gives the Automation Account the "Desktop Virtualization Power On Off Contributor" role on the resource groups containing the hosts and host pool
module roleAssignments 'roleAssignment.bicep' = [for i in range(0, length(RoleAssignments)): {
  name: 'RoleAssignment_${i}_${RoleAssignments[i]}'
  scope: resourceGroup(RoleAssignments[i])
  params: {
    PrincipalId: automationAccount.identity.principalId
    RoleDefinitionId: RoleDefinitionIds.desktopVirtualizationPowerOnOffContributor
  }
}]
