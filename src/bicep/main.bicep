@description('Name of the Azure Container Registry (must be globally unique, alphanumeric only)')
param acrName string = 'acrcontainerappsdemo'

@description('Name of the Container Apps managed environment')
param environmentName string = 'env-containerapps-prod'

@description('Name of the Container App')
param containerAppName string = 'my-containerapp'

@description('Azure region')
param location string = resourceGroup().location

@description('Starter container image — replace with your own after the first CI/CD run pushes a real one')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false // managed identity auth only — see setup-acr-identity.sh
  }
}

resource environment 'Microsoft.App/managedEnvironments@2026-01-01' = {
  name: environmentName
  location: location
  properties: {}
}

resource containerApp 'Microsoft.App/containerApps@2026-01-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// Grant the Container App's managed identity AcrPull on this registry —
// the whole point of setup-acr-identity.sh's role assignment, expressed
// declaratively here for a from-scratch deployment.
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerApp.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output acrLoginServer string = acr.properties.loginServer
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
