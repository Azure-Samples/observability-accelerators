@description('Default value obtained from resource group, it can be overwritten')
@minLength(1)
param location string = resourceGroup().location

@description('Name for the ACR')
@minLength(1)
param acrName string

@description('The principal ID of the AKS cluster')
@minLength(1)
param aksPrincipalId string

@description('Built-in role for role assignment')
@minLength(1)
param roleDefinitionId string

@description('Expected ACR sku')
@allowed([
  'Basic'
  'Classic'
  'Premium'
  'Standard'
])
param acrSku string = 'Standard'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
}

resource assignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, aksPrincipalId, 'AssignAcrPullToAks')
  scope: containerRegistry
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId
  }
}

output acrName string = containerRegistry.name
