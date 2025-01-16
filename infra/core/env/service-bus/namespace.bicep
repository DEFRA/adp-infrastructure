@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for servicebus. The object must contain the namespaceName,namespacePrivateEndpointName and skuName values.')
param serviceBus object

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Required. Boolean value to enable or disable resource lock.')
param resourceLockEnabled bool

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var serviceBusTags = {
  Name: serviceBus.namespaceName
  Purpose: 'Service Bus Namespace'
  Tier: 'Shared'
}

var serviceBusPrivateEndpointTags = {
  Name: serviceBus.namespacePrivateEndpointName
  Purpose: 'Service Bus Namespace private endpoint'
  Tier: 'Shared'
}

module serviceBusResource 'br/SharedDefraRegistry:service-bus.namespace:0.5.16' = {
  name: 'service-bus-${deploymentDate}'
  params: {
    name: serviceBus.namespaceName
    skuName: serviceBus.skuName
    location: location
    minimumTlsVersion:'1.2'
    lock: resourceLockEnabled ? {
      kind: 'CanNotDelete'
    } : null
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        name: serviceBus.namespacePrivateEndpointName
        service: 'namespace'
        subnetResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetPrivateEndpoints)
        tags: union(tags, serviceBusPrivateEndpointTags)
      }
    ]
    tags: union(tags, serviceBusTags)
  }
}
