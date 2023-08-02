param projectName string
param location string = resourceGroup().location
param serviceCode string = 'CDO'
param envCode string
param subSpokeNumber string

param tags object = {
  ServiceCode: serviceCode
  Environment: envCode
}

param addressPrefixes array
param dnsServers string

param subnet1AddressPrefix string
param subnet2AddressPrefix string
param subnet3AddressPrefix string
param subnet5AddressPrefix string
param subnet6AddressPrefix string
param subnet7AddressPrefix string
param subnet8AddressPrefix string

param aks1RouteTableName string
param aks2RouteTableName string
param aks1RouteTableResourceGroupName string
param aks2RouteTableResourceGroupName string

// Variables
var subnetPrefix = '${envCode}${projectName}NETSU${subSpokeNumber}40'
var subnets = [
  {
    name: '${subnetPrefix}1'
    addressPrefix: subnet1AddressPrefix
    routeTable: {
      id: aks1RouteTableName == '' ? '' : aks1RouteTable.id
    }
    networkSecurityGroupId: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegations: []
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
  }
  {
    name: '${subnetPrefix}2'
    addressPrefix: subnet2AddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
  }
  {
    name: '${subnetPrefix}3'
    addressPrefix: subnet3AddressPrefix
    routeTable: {
      id: aks1RouteTableName == '' ? '' : aks1RouteTable.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: '${subnetPrefix}5'
    addressPrefix: subnet5AddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: '${subnetPrefix}6'
    addressPrefix: subnet6AddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegations: [
      {
        name: 'Microsoft.Web.serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Web'
      }
    ]
  }
  {
    name: '${subnetPrefix}7'
    addressPrefix: subnet7AddressPrefix
    routeTable: {
      id: aks2RouteTableName == '' ? '' : aks2RouteTable.id
    }
    networkSecurityGroupId: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.KeyVault'
      }
    ]
  }
  {
    name: '${subnetPrefix}8'
    addressPrefix: subnet8AddressPrefix
    networkSecurityGroupId: nsg.id
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureActiveDirectory'
      }
      {
        service: 'Microsoft.AzureCosmosDB'
      }
      {
        service: 'Microsoft.CognitiveServices'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
      {
        service: 'Microsoft.EventHub'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.ServiceBus'
      }
      {
        service: 'Microsoft.Sql'
      }
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Web'
      }
    ]
  } ]

// Existing Resources
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' existing = {
  name: '${envCode}CDONETNS2401'
  //scope: resourceGroup('${envCode}CDONETRG${spokeNumber}401')
}

resource aks1RouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = if (aks1RouteTableName != '') {
  name: aks1RouteTableName
  scope: resourceGroup(aks1RouteTableResourceGroupName)
}

resource aks2RouteTable 'Microsoft.Network/routeTables@2022-07-01' existing = if (aks2RouteTableName != '') {
  name: aks2RouteTableName
  scope: resourceGroup(aks2RouteTableResourceGroupName)
}

module vnet 'br/SharedDefraRegistry:network.virtual-networks:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-vnet'
  params: {
    name: '${envCode}CDONETVN${subSpokeNumber}401'
    location: location
    tags: tags
    addressPrefixes: addressPrefixes
    dnsServers: split(dnsServers, ';')
    subnets: subnets
  }
}
