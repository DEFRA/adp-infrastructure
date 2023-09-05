@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetClusterNodes values.')
param vnet object
@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object
@description('Required. The prefix for the private DNS zone.')
param privateDnsZone object
@description('Required. The Name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string
@description('Required. The parameter object for the container registry. The object must contain the name, subscriptionId and resourceGroup values.')
param containerRegistry object
@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')
@description('Required. The parameter object for configuring flux with the aks cluster. The object must contain the fluxCore  and fluxServices values.')
param fluxConfig object
@description('Optional. The parameter object for the monitoringWorkspace. The object must contain name of the name and resourceGroup.')
param monitoringWorkspace object

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)
var tagsMi = {
  Name: cluster.miControlPlane
  Purpose: 'AKS Control Plane Managed Identity'
  Tier: 'Security'
}
var aksTags = {
  Name: cluster.name
  Purpose: 'AKS Cluster'
  Tier: 'Shared'
}
var pdnsTags = {
  Name: privateDnsZoneName
  Purpose: 'AKS Private DNS Zone'
}
var pdnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'AKS Private DNS Zone VNet Link'
}
var privateDnsZoneName = toLower('${privateDnsZone.prefix}.privatelink.${location}.azmk8s.io')

var azureMonitorWorkspaceTags = {
  Name: azureMonitorWorkspaceName
  Purpose: 'Azure Monitor Workspace'
}

resource azureMonitorWorkSpaceResource 'Microsoft.Monitor/accounts@2023-04-03' = {
  location: location
  name: azureMonitorWorkspaceName
  tags: azureMonitorWorkspaceTags
}

module managedIdentityModule 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zones:0.5.7' = {
  name: 'aks-private-dns-zone-${deploymentDate}'
  dependsOn: [
    managedIdentityModule
  ]
  params: {
   name: privateDnsZoneName
   lock: 'CanNotDelete'
   tags: union(tags, pdnsTags)
   roleAssignments: [
    {
      roleDefinitionIdOrName: 'Private DNS Zone Contributor'
      principalIds: [
        managedIdentityModule.outputs.principalId
      ]
      principalType: 'ServicePrincipal'
    }
   ]
   virtualNetworkLinks: [
    {
      name: vnet.name
      virtualNetworkResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
      registrationEnabled: true
      tags: union(tags, pdnsVnetLinksTags)
    }
   ]
  }
}

module networkContributorModule '.bicep/network-contributor.bicep' = {
  name: 'aks-cluster-network-contributor-${deploymentDate}'
  scope: resourceGroup(vnet.resourceGroup)
  dependsOn: [
    privateDnsZoneModule
  ]
  params: {
    managedIdentity: {
      name: cluster.miControlPlane
      principalId: managedIdentityModule.outputs.principalId
    }
    vnetName: vnet.name
  }
}

module deployAKS 'br/SharedDefraRegistry:container-service.managed-clusters:0.5.13-prerelease' = {
  name: 'aks-cluster-${deploymentDate}'
  dependsOn: [
    networkContributorModule
  ]
  params: {
    name: cluster.name
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, aksTags)
    aksClusterKubernetesVersion: cluster.kubernetesVersion
    nodeResourceGroup: cluster.nodeResourceGroup
    enableDefaultTelemetry: false
    omsAgentEnabled: true
    monitoringWorkspaceId: resourceId(monitoringWorkspace.resourceGroup, 'Microsoft.OperationalInsights/workspaces', monitoringWorkspace.name) 
    enableRBAC: true
    aadProfileManaged: true
    disableLocalAccounts: true
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${managedIdentityModule.outputs.resourceId}': {}
    }
    enableSecurityProfileWorkloadIdentity: true
    azurePolicyEnabled: true
    azurePolicyVersion: 'v2'
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: array(cluster.adminAadGroupObjectId)
    enablePrivateCluster: true
    privateDNSZone: privateDnsZoneModule.outputs.resourceId
    disableRunCommand: false
    enablePrivateClusterPublicFQDN: false
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPluginMode: 'overlay'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: cluster.podCidr
    aksClusterServiceCidr: cluster.serviceCidr
    aksClusterDnsServiceIP: cluster.dnsServiceIp
    aksClusterLoadBalancerSku: 'standard'
    managedOutboundIPCount: 0
    aksClusterOutboundType: 'userDefinedRouting'
    aksClusterSkuTier: cluster.skuTier
    aksClusterSshPublicKey: ''
    aksServicePrincipalProfile: {}
    aadProfileClientAppID: ''
    aadProfileServerAppID: ''
    aadProfileServerAppSecret: ''
    aadProfileTenantId: subscription().tenantId
    primaryAgentPoolProfile: [
      {
        name: 'npsystem'
        mode: 'System'
        count: cluster.npSystem.count
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: cluster.npSystem.osDiskSizeGB
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: cluster.npSystem.minCount
        maxCount: cluster.npSystem.maxCount
        vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetClusterNodes)
        enableAutoScaling: true
        enableCustomCATrust: false
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: cluster.kubernetesVersion
        enableNodePublicIP: false
        maxPods: cluster.npSystem.maxPods
        availabilityZones: cluster.npSystem.availabilityZones
        upgradeSettings: {
          maxSurge: '33%'
        }
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
    ]
    agentPools: [
      {
        name: 'npuser01'
        mode: 'User'
        count: cluster.npUser.count
        vmSize: 'Standard_DS3_v2'
        osDiskSizeGB: cluster.npUser.osDiskSizeGB
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: cluster.npUser.minCount
        maxCount: cluster.npUser.maxCount
        vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetClusterNodes)
        enableAutoScaling: true
        enableCustomCATrust: false
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: cluster.kubernetesVersion
        enableNodePublicIP: false
        maxPods: cluster.npUser.maxPods
        availabilityZones: cluster.npUser.availabilityZones
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]
    autoScalerProfileBalanceSimilarNodeGroups: 'false'
    autoScalerProfileExpander: 'random'
    autoScalerProfileMaxEmptyBulkDelete: '10'
    autoScalerProfileMaxGracefulTerminationSec: '600'
    autoScalerProfileMaxNodeProvisionTime: '15m'
    autoScalerProfileMaxTotalUnreadyPercentage: '45'
    autoScalerProfileNewPodScaleUpDelay: '0s'
    autoScalerProfileOkTotalUnreadyCount: '3'
    autoScalerProfileScaleDownDelayAfterAdd: '10m'
    autoScalerProfileScaleDownDelayAfterDelete: '20s'
    autoScalerProfileScaleDownDelayAfterFailure: '3m'
    autoScalerProfileScaleDownUnneededTime: '10m'
    autoScalerProfileScaleDownUnreadyTime: '20m'
    autoScalerProfileUtilizationThreshold: '0.5'
    autoScalerProfileScanInterval: '10s'
    autoScalerProfileSkipNodesWithLocalStorage: 'true'
    autoScalerProfileSkipNodesWithSystemPods: 'true'

    fluxExtension: {
      autoUpgradeMinorVersion: true
      releaseTrain: 'Stable'
      configurationSettings: {
        'helm-controller.enabled': 'true'
        'source-controller.enabled': 'true'
        'kustomize-controller.enabled': 'true'
        'notification-controller.enabled': 'true'
        'image-automation-controller.enabled': 'false'
        'image-reflector-controller.enabled': 'false'
      }
      configurations: [
        {
          name: 'config-cluster-flux'
          namespace: 'config-cluster-flux'
          scope: 'cluster'
          gitRepository: {
            repositoryRef: {
              branch: fluxConfig.clusterCore.gitRepository.branch
            }
            syncIntervalInSeconds: fluxConfig.clusterCore.gitRepository.syncIntervalInSeconds
            timeoutInSeconds: fluxConfig.clusterCore.gitRepository.timeoutInSeconds
            url: fluxConfig.clusterCore.gitRepository.url
          }
          kustomizations: {
            cluster: {
              path: fluxConfig.clusterCore.kustomizations.clusterPath
              dependsOn: []
              timeoutInSeconds: fluxConfig.clusterCore.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.clusterCore.kustomizations.syncIntervalInSeconds
              validation: 'none'
              prune: true
            }
            infra: {
              path: fluxConfig.clusterCore.kustomizations.infraPath
              timeoutInSeconds: fluxConfig.clusterCore.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.clusterCore.kustomizations.syncIntervalInSeconds
              dependsOn: [
                'cluster'
              ]
              validation: 'none'
              prune: true
            }
          } 
        }
        {
          name: 'config-services-flux'
          namespace: 'config-services-flux'
          scope: 'cluster'
          gitRepository: {
            repositoryRef: {
              branch: fluxConfig.services.gitRepository.branch
            }
            syncIntervalInSeconds: fluxConfig.services.gitRepository.syncIntervalInSeconds
            timeoutInSeconds: fluxConfig.services.gitRepository.timeoutInSeconds
            url: fluxConfig.services.gitRepository.url
          }
          kustomizations: {
            apps: {
              path: fluxConfig.services.kustomizations.appsPath
              timeoutInSeconds: fluxConfig.services.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.services.kustomizations.syncIntervalInSeconds
              retryIntervalInSeconds: fluxConfig.services.kustomizations.retryIntervalInSeconds
              prune: true
            }
          }
        }
      ]
    }
  }
}

module acrPullRoleAssignmentModule '.bicep/acr-pull.bicep' = {
  name: 'aks-acr-pull-role-assignment-${deploymentDate}'
  scope: resourceGroup(containerRegistry.subscriptionId, containerRegistry.resourceGroup)
  dependsOn: [
    deployAKS
  ]
  params: {
    principalId: deployAKS.outputs.kubeletidentityObjectId
    containerRegistryName: containerRegistry.name
  }
}
