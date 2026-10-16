// A simulated source system (ADR 0007): its own Cosmos DB account (serverless, Entra ID only),
// one database, its own containers in its own naming. Only that system's System API runtime
// identity may read and write it. Salesforce came first and has its own module (salesforce.bicep).

param system string
param location string
param tags object

@description('Containers, in the system\'s own naming. Partition key /id everywhere: every record is a point read.')
param containers string[]

@description('Principal id of the system\'s System API runtime identity.')
param systemApiPrincipalId string

var dataContributor = '00000000-0000-0000-0000-000000000002' // Cosmos DB Built-in Data Contributor

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: 'cosmos-intplat-${system}'
  location: location
  tags: union(tags, { system: system })
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      { locationName: location, failoverPriority: 0 }
    ]
    capabilities: [
      { name: 'EnableServerless' }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    disableLocalAuth: true
    minimalTlsVersion: 'Tls12'
    publicNetworkAccess: 'Enabled'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-11-15' = {
  parent: account
  name: system
  properties: {
    resource: { id: system }
  }
}

resource stores 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = [
  for name in containers: {
    parent: database
    name: name
    properties: {
      resource: {
        id: name
        partitionKey: { paths: ['/id'], kind: 'Hash' }
      }
    }
  }
]

resource systemApiAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-11-15' = {
  parent: account
  name: guid(account.id, systemApiPrincipalId, dataContributor)
  properties: {
    principalId: systemApiPrincipalId
    roleDefinitionId: '${account.id}/sqlRoleDefinitions/${dataContributor}'
    scope: account.id
  }
}

output endpoint string = account.properties.documentEndpoint
