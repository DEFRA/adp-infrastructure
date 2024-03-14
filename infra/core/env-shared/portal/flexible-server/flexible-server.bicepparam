using './flexible-server.bicep'

param server = {
  name: '#{{ portalpostgreSqlServerName }}'
  storageSizeGB: #{{ postgreSqlStorageSizeGB }}
  tier: '#{{ postgreSqlTier }}'
  skuName: '#{{ postgreSqlSkuName }}'
  highAvailability: '#{{ postgreSqlHighAvailability }}'
  availabilityZone: '#{{ postgreSqlAvailabilityZone }}'
}

param vnet = {
  name: '#{{ ssvVirtualNetworkName }}'
  resourceGroup: '#{{ ssvVirtualNetworkResourceGroup }}'
  subnetPostgreSql: '#{{ postgreSqlSubnet }}'
}

param keyvaultName = '#{{ portalAppKeyVaultName }}'

param privateDnsZone = {
  name: '#{{ postgreSqlPvtDnsZone }}'
  resourceGroup: '#{{ dnsResourceGroup }}'
}

param diagnostics = {
  diagnosticLogCategoriesToEnable: [
    'allLogs'
  ]
  diagnosticMetricsToEnable: [
    'AllMetrics'
  ]
}

param location = '#{{ location }}'

param environment = '#{{ environment }}'
