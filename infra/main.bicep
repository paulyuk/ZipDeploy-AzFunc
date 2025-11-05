targetScope = 'subscription'
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@maxLength(64)
@description('FunctionApp Name')
param appName string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))


var functionAppName = '${abbrs.webSitesFunctions}${appName}${resourceToken}'
var storageAccountName = '${abbrs.storageStorageAccounts}${toLower(substring(appName, 0, min(length(appName), 9)))}${resourceToken}'
var deploymentStorageContainerName = 'app-package-${take(functionAppName, 32)}-${take(toLower(uniqueString(functionAppName, resourceToken)), 7)}'

@description('Id of the user or app to assign application roles')
param principalId string = ''


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// User assigned managed identity to be used by the function app to reach storage and other dependencies
module apiUserAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: 'apiUserAssignedIdentity'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.managedIdentityUserAssignedIdentities}api-${resourceToken}'
  }
}


// Create an App Service Plan to group applications under the same payment plan and SKU
module servicePlan 'br/public:avm/res/web/serverfarm:0.1.1' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: '${abbrs.webServerFarms}${take(appName, 20)}${resourceToken}'
    sku: {
      name: 'EP1'
      tier: 'ElasticPremium'
    }
    reserved: true // Set to true for Linux OS plan
    location: location
    tags: tags
    maximumElasticWorkerCount: 3
  }
}

// Backing storage for Azure functions backend API
module storageAccount 'br/public:avm/res/storage/storage-account:0.8.3' = {
  name: 'storage'
  scope: rg
  params: {
    name: storageAccountName
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // Disable local authentication methods as per policy
    dnsEndpointType: 'Standard'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    blobServices: {
      containers: [{name: deploymentStorageContainerName}]
    }
    minimumTlsVersion: 'TLS1_2'  // Enforcing TLS 1.2 for better security
    location: location
    tags: tags
  }
}


// Monitor application with Azure Monitor - Log Analytics workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-loganalytics'
  scope: rg
  params: {
    name: '${abbrs.operationalInsightsWorkspaces}${take(appName, 20)}${resourceToken}'
    location: location
    tags: tags
    dataRetention: 30
  }
}


// Application Insights for monitoring
module applicationInsights 'br/public:avm/res/insights/component:0.4.1' = {
  name: '${uniqueString(deployment().name, location)}-appinsights'
  scope: rg
  params: {
    name: '${abbrs.insightsComponents}${take(appName, 20)}${resourceToken}'
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    disableLocalAuth: true
  }
}


// Define the configuration object locally to pass to the modules
var storageEndpointConfig = {
  enableBlob: true  // Required for AzureWebJobsStorage, .zip deployment, Event Hubs trigger and Timer trigger checkpointing
  enableQueue: false  // Required for Durable Functions and MCP trigger
  enableTable: false  // Required for Durable Functions and OpenAI triggers and bindings
  enableFiles: false   // Not required, used in legacy scenarios
  allowUserIdentityPrincipal: true   // Allow interactive user identity to access for testing and debugging
}

module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: functionAppName
    location: location
    tags: tags
    applicationInsightsName: applicationInsights.outputs.name
    appServicePlanId: servicePlan.outputs.resourceId
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    storageAccountName: storageAccount.outputs.name
    enableBlob: storageEndpointConfig.enableBlob
    enableQueue: storageEndpointConfig.enableQueue
    enableTable: storageEndpointConfig.enableTable
    deploymentStorageContainerName: deploymentStorageContainerName
    identityId: apiUserAssignedIdentity.outputs.resourceId
    identityClientId: apiUserAssignedIdentity.outputs.clientId
    appSettings: {
    }
  }
}

// Consolidated Role Assignments
module rbac 'app/rbac.bicep' = {
  name: 'rbacAssignments'
  scope: rg
  params: {
    storageAccountName: storageAccount.outputs.name
    appInsightsName: applicationInsights.outputs.name
    managedIdentityPrincipalId: apiUserAssignedIdentity.outputs.principalId
    userIdentityPrincipalId: principalId
    enableBlob: storageEndpointConfig.enableBlob
    enableQueue: storageEndpointConfig.enableQueue
    enableTable: storageEndpointConfig.enableTable
    allowUserIdentityPrincipal: storageEndpointConfig.allowUserIdentityPrincipal
  }
}





// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_FUNCTIONAPP_URI string = 'https://${api.outputs.SERVICE_API_NAME}.azurewebsites.net'
output SERVICE_API_NAME string = api.outputs.SERVICE_API_NAME
output AZURE_FUNCTION_NAME string = functionAppName
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName
output AZURE_STORAGE_CONTAINER_NAME string = deploymentStorageContainerName 
