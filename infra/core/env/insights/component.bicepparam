using 'component.bicep'

param appInsights = {
  name: '#{{ applicationInsightsName }}'
  workspaceName: '#{{ logAnalyticsWorkspace }}'
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param monitoringPublisherGroup = '#{{ monitoringPublisherGroup }}'

param globalReadGroupName = '#{{ globalReadGroupName }}'

param disableLocalAuth = #{{ applicationInsightsDisableLocalAuth }}
