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

output salesforceEndpoint string = salesforce.outputs.endpoint
