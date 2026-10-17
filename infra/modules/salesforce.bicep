// Simulated Salesforce: the system of record for orders (ADR 0007, 0013). Cosmos DB serverless,
// Entra ID only. Salesforce keeps its own data model (salesforce/README.md); only the Salesforce
// System API's runtime identity may read and write it.

param location string
param tags object

@description('Principal id of id-intplat-system-api-salesforce-runtime.')
param systemApiPrincipalId string

var dataContributor = '00000000-0000-0000-0000-000000000002' // Cosmos DB Built-in Data Contributor

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: 'cosmos-intplat-salesforce'
  location: location
  tags: union(tags, { system: 'salesforce' })
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
  name: 'salesforce'
  properties: {
    resource: { id: 'salesforce' }
  }
}

// The Order object. Partition key = id (the Salesforce record id), so a record is a point read.
resource orders 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = {
  parent: database
  name: 'Order'
  properties: {
    resource: {
      id: 'Order'
      partitionKey: { paths: ['/id'], kind: 'Hash' }
    }
  }
}

// Salesforce auto-number: the next OrderNumber. Starts at 4710, so the first order is 4711.
resource counters 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = {
  parent: database
  name: 'AutoNumber'
  properties: {
    resource: {
      id: 'AutoNumber'
      partitionKey: { paths: ['/id'], kind: 'Hash' }
    }
  }
}

// Reference data: customers (Account) and what they can buy (Product2 with its standard price).
// The System API writes its sample data on first read (system-api-salesforce/sample_data.py).
resource referenceData 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = [
  for name in ['Account', 'Product2']: {
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
