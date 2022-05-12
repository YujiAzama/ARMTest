@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Username for the Virtual Machine.')
param adminUsername string = 'testuser'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string
param virtualNetworksName string = 'test-vnet'
param virtualMachinesName string = 'test-vm'
param networkInterfacesName string = 'test-interface'
param networkSecurityGroupsName string = 'test-sg'

resource virtualMachinesName_resource 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: virtualMachinesName
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
        name: '${virtualMachinesName}_OsDisk_1_34bf20d57acd4a7386a9d772306e7814'
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
      computerName: virtualMachinesName
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
          id: networkInterfacesName_resource.id
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

resource virtualMachinesName_config_app 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachinesName_resource
  name: 'config-app'
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

resource networkSecurityGroupsName_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: networkSecurityGroupsName
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

resource virtualNetworksName_resource 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworksName
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

resource networkSecurityGroupsName_AllowBastionInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = {
  parent: networkSecurityGroupsName_resource
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

resource virtualNetworksName_VMSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: virtualNetworksName_resource
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

resource networkInterfacesName_resource 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: networkInterfacesName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.1.5'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworksName_VMSubnet.id
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
      id: networkSecurityGroupsName_resource.id
    }
  }
}
