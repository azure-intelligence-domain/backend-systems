// The simulated source systems (ADR 0007), each reachable only through its System API.

param location string = 'belgiumcentral'

var tags = {
  project: 'ai-intelligence-domain'
  component: 'backend-systems'
  owner: 'platform-team'
}

resource salesforceApi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'id-intplat-system-api-salesforce-runtime'
  scope: resourceGroup('rg-intplat-identities')
}

module salesforce 'modules/salesforce.bicep' = {
  name: 'salesforce'
  params: {
    location: location
    tags: tags
    systemApiPrincipalId: salesforceApi.properties.principalId
  }
}

// SAP (finance), WMS (supply), 3PL partner (logistics): each with its own naming (README.md per system).
var systems = [
  { name: 'sap', api: 'system-api-sap', containers: ['VBAK', 'VBRK', 'Payment', 'NumberRange'] }
  { name: 'wms', api: 'system-api-wms', containers: ['StockItem', 'Reservation'] }
  { name: '3pl', api: 'system-api-3pl', containers: ['Consignment'] }
]

resource systemApis 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = [
  for s in systems: {
    name: 'id-intplat-${s.api}-runtime'
    scope: resourceGroup('rg-intplat-identities')
  }
]

module sources 'modules/source-system.bicep' = [
  for (s, i) in systems: {
    name: s.name
    params: {
      system: s.name
      location: location
      tags: tags
      containers: s.containers
      systemApiPrincipalId: systemApis[i].properties.principalId
    }
  }
]

output salesforceEndpoint string = salesforce.outputs.endpoint
