using './fluxnotificationapp-managed-identity.bicep'

param managedIdentity = {
  name: '#{{ fluxNotificationApiManagedIdentity }}'
}

param environment = '#{{ environment }}'
param subEnvironment = '#{{ subEnvironment }}'
param location = '#{{ location }}'

param containerRegistry = {
  name: '#{{ ssvSharedAcrName }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvSharedResourceGroup }}'
}

param keyVault = {
  name: '#{{ ssvInfraKeyVault }}'
  subscriptionId: '#{{ subscriptionId }}'
  resourceGroup: '#{{ ssvInfraResourceGroup }}'
}

param secrets = [
  'POSTGRES-HOST'
  'FLUXNOTIFY-MI-CLIENT-ID'
]
