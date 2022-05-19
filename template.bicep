@description('Specifies the location for resources.')
param location string = resourceGroup().location

// Settings for Virtual Machine
@description('Username for the Virtual Machine.')
param adminUsername string = 'testuser'
// P@ssw0rd12345678-
@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string
param virtualNetworkName string = 'test-vnet'
param vmName string = 'test-vm'
param vmNetworkInterfaceName string = 'test-interface'
param networkSecurityGroupName string = 'test-sg'

// CosmosDB Settings
@description('Cosmos DB account name')
param cosmosDBAccountName string = 'cosmos-${uniqueString(resourceGroup().id)}'
@description('The name for the Core (SQL) database')
param databaseName string = 'opendata'

// DNS Settings for CosmosDB
param cosmosDBPrivateEndpointName string = 'CosmosDBPrivateEndpoint'
param cosmosDBPrivateDnsZoneName string = 'privatelink.documents.azure.com'
param cosmosDBNetworkInterfaceName string = 'test-interface-cosmosdb'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vmName}_OsDisk_1_34bf20d57acd4a7386a9d772306e7814'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vmSetupScript 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'vm-setup-script'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: 123456789
    }
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/YujiAzama/ARMTest/main/installPowerPlatformPackages.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File installPowerPlatformPackages.ps1'
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: networkSecurityGroupName
  location: location
  tags: {
    org: 'ool'
  }
  properties: {
    securityRules: [
      {
        name: 'AllowBastionInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '10.0.255.0/27'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'VMSubnet'
        properties: {
          addressPrefix: '10.0.1.0/28'
          serviceEndpoints: [
            {
              service: 'Microsoft.AzureCosmosDB'
              locations: [
                '*'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource allowBastionInboundSecurityRule 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  parent: networkSecurityGroup
  name: 'AllowBastionInbound'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    sourceAddressPrefix: '10.0.255.0/27'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 1001
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: [
      '22'
      '3389'
    ]
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: virtualNetwork
  name: 'VMSubnet'
  properties: {
    addressPrefix: '10.0.1.0/28'
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          '*'
        ]
      }
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource vmNetworkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: vmNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.1.5'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: toLower(cosmosDBAccountName)
  location: location
  properties: {
    //enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
    createMode: 'Default'
  }
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-07-01-preview' = {
  parent: cosmosDBAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource benokiContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-07-01-preview' = {
  parent: cosmosDB
  name: 'benoki'
  properties: {
    resource: {
      id: 'benoki'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/riverName'
        ]
        kind: 'Hash'
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}

resource hukutiContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-07-01-preview' = {
  parent: cosmosDB
  name: 'hukuti'
  properties: {
    resource: {
      id: 'hukuti'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/riverName'
        ]
        kind: 'Hash'
      }
      uniqueKeyPolicy: {
        uniqueKeys: []
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}

resource benokiThroughputSettings 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/throughputSettings@2021-07-01-preview' = {
  parent: benokiContainer
  name: 'default'
  properties: {
    resource: {
      throughput: 400
    }
  }
}

resource hukutiThroughputSettings 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/throughputSettings@2021-07-01-preview' = {
  parent: hukutiContainer
  name: 'default'
  properties: {
    resource: {
      throughput: 400
    }
  }
}

resource sqlRoleDefinitions_00000000_0000_0000_0000_000000000001 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-07-01-preview' = {
  parent: cosmosDBAccount
  name: '00000000-0000-0000-0000-000000000001'
  properties: {
    roleName: 'Cosmos DB Built-in Data Reader'
    type: 'BuiltInRole'
    assignableScopes: [
      cosmosDBAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read'
        ]
        notDataActions: []
      }
    ]
  }
}

resource sqlRoleDefinitions_00000000_0000_0000_0000_000000000002 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-07-01-preview' = {
  parent: cosmosDBAccount
  name: '00000000-0000-0000-0000-000000000002'
  properties: {
    roleName: 'Cosmos DB Built-in Data Contributor'
    type: 'BuiltInRole'
    assignableScopes: [
      cosmosDBAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
        notDataActions: []
      }
    ]
  }
}

resource cosmosDBPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: cosmosDBPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: cosmosDBPrivateEndpointName
        properties: {
          privateLinkServiceId: cosmosDBAccount.id
          groupIds: [
            'Sql'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${virtualNetwork.id}/subnets/VMSubnet'
    }
    customDnsConfigs: [
      {
        fqdn: 'ool-dataops.documents.azure.com'
        ipAddresses: [
          '10.0.1.7'
        ]
      }
      {
        fqdn: 'ool-dataops-japaneast.documents.azure.com'
        ipAddresses: [
          '10.0.1.8'
        ]
      }
    ]
  }
}

resource cosmosDBNetworkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: cosmosDBNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'privateEndpointIpConfig.9ab0d39c-f07d-4f95-9c37-05d0c6dccfe8'
        properties: {
          privateIPAddress: '10.0.1.7'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
      {
        name: 'privateEndpointIpConfig.222ff169-5ba0-464b-bff6-2e883ec5f0c9'
        properties: {
          privateIPAddress: '10.0.1.8'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnet.id
          }
          primary: false
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource cosmosDBPrivateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: cosmosDBPrivateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneA01 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: cosmosDBPrivateDnsZone
  name: 'ool-dataops'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: '10.0.1.7'
      }
    ]
  }
}

resource privateDnsZoneA02 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: cosmosDBPrivateDnsZone
  name: 'ool-dataops-japaneast'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: '10.0.1.8'
      }
    ]
  }
}

resource privateDnsZoneSOA 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: cosmosDBPrivateDnsZone
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: cosmosDBPrivateDnsZone
  name: 'vmpruztkk5r5d'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}
