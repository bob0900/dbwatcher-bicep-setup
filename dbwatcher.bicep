// ============================================================================
// Parameters - Database Watcher Configuration
// ============================================================================

@description('Name of the Database Watcher resource')
param watcherName string

@description('Location for the Database Watcher')
param location string = resourceGroup().location

// ============================================================================
// Parameters - Kusto/ADX Configuration
// ============================================================================

@description('Subscription ID where the Kusto cluster is located')
param kustoSubscriptionId string = subscription().subscriptionId

@description('Resource group name of the existing Kusto cluster')
param kustoResourceGroupName string

@description('Name of the existing Kusto cluster')
param kustoClusterName string

@description('Name of the Kusto database for Database Watcher data')
param kustoDatabaseName string = 'dbwatcher'

// ============================================================================
// Parameters - SQL Targets Configuration
// ============================================================================

@description('Array of SQL Database targets to monitor')
param sqlTargets array = []
/* Simplified structure:
[
  {
    subscriptionId: '00000000-0000-0000-0000-000000000000' // Optional, defaults to current subscription
    resourceGroupName: 'rg-sql'
    sqlServerName: 'myserver'
    databaseName: 'mydatabase'
    authenticationType: 'Aad' // 'Sql' or 'Aad' - defaults to 'Aad'
    // For SQL Auth (authenticationType: 'Sql'):
    keyVaultSubscriptionId: '00000000-0000-0000-0000-000000000000' // Optional
    keyVaultResourceGroupName: 'rg-keyvault'
    keyVaultName: 'mykeyvault'
    usernameSecretName: 'sqlUsername'
    passwordSecretName: 'sqlPassword'
    // For AAD Auth (authenticationType: 'Aad'):
    // Uses Database Watcher managed identity, no secrets needed
    enablePrivateLink: true // Optional, enable private link for this target (defaults to true)
    readIntent: false // Optional, defaults to false
  }
]
*/

@description('Array of SQL Managed Instance targets to monitor')
param sqlManagedInstanceTargets array = []
/* Simplified structure:
[
  {
    subscriptionId: '00000000-0000-0000-0000-000000000000' // Optional, defaults to current subscription
    resourceGroupName: 'rg-sqlmi'
    managedInstanceName: 'myinstance'
    authenticationType: 'Aad' // 'Sql', 'Aad' - defaults to 'Aad'
    // For SQL Auth (authenticationType: 'Sql'):
    keyVaultSubscriptionId: '00000000-0000-0000-0000-000000000000' // Optional
    keyVaultResourceGroupName: 'rg-keyvault'
    keyVaultName: 'mykeyvault'
    usernameSecretName: 'sqlUsername'
    passwordSecretName: 'sqlPassword'
    // For AAD Auth: no secrets needed
    readIntent: false // Optional, defaults to false
  }
]
*/

// ============================================================================
// Parameters - Private Link Configuration (Optional)
// ============================================================================

@description('Request message for SQL Server private link')
param sqlPrivateLinkRequestMessage string = 'Database Watcher SQL private link request'

@description('Request message for Kusto private link')
param kustoPrivateLinkRequestMessage string = 'Database Watcher Kusto private link request'

@description('Enable private link for Kusto cluster')
param enableKustoPrivateLink bool = false

@description('DNS zone for Kusto private link (e.g., region name)')
param kustoDnsZone string = ''

// ============================================================================
// Existing Resources - Kusto Cluster Reference
// ============================================================================

resource kustoCluster 'Microsoft.Kusto/clusters@2023-08-15' existing = {
  name: kustoClusterName
  scope: resourceGroup(kustoSubscriptionId, kustoResourceGroupName)
}

// ============================================================================
// Existing Resources - SQL Servers and Databases References
// ============================================================================

resource sqlServers 'Microsoft.Sql/servers@2023-08-01-preview' existing = [for target in sqlTargets: {
  name: target.sqlServerName
  scope: resourceGroup(target.?subscriptionId ?? subscription().subscriptionId, target.resourceGroupName)
}]

resource sqlDatabases 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = [for (target, i) in sqlTargets: {
  name: target.databaseName
  parent: sqlServers[i]
}]

// ============================================================================
// Existing Resources - SQL Managed Instances and Databases References
// ============================================================================

resource sqlManagedInstances 'Microsoft.Sql/managedInstances@2023-08-01-preview' existing = [for target in sqlManagedInstanceTargets: {
  name: target.managedInstanceName
  scope: resourceGroup(target.?subscriptionId ?? subscription().subscriptionId, target.resourceGroupName)
}]

// ============================================================================
// Existing Resources - Key Vaults References (for SQL Auth only)
// ============================================================================

// Key Vaults for SQL Database targets with SQL Auth
resource sqlDbKeyVaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = [for target in sqlTargets: if ((target.?authenticationType ?? 'Aad') == 'Sql') {
  name: target.keyVaultName
  scope: resourceGroup(target.?keyVaultSubscriptionId ?? subscription().subscriptionId, target.keyVaultResourceGroupName)
}]

// Key Vaults for SQL MI targets with SQL Auth
resource sqlMiKeyVaults 'Microsoft.KeyVault/vaults@2023-07-01' existing = [for target in sqlManagedInstanceTargets: if ((target.?authenticationType ?? 'Aad') == 'Sql') {
  name: target.keyVaultName
  scope: resourceGroup(target.?keyVaultSubscriptionId ?? subscription().subscriptionId, target.keyVaultResourceGroupName)
}]

// ============================================================================
// Derived Variables
// ============================================================================

var kustoManagementUrl = 'https://portal.azure.com/resource${kustoCluster.id}/overview'

// Get unique SQL Server names for private link creation (deduplication at server level)
var sqlServersForPrivateLink = [for (target, i) in sqlTargets: {
  serverName: target.sqlServerName
  serverId: sqlServers[i].id
  enabled: target.?enablePrivateLink ?? true
}]

// Filter only enabled servers
var enabledSqlServers = filter(sqlServersForPrivateLink, item => item.enabled)

// Create a deduplicated list by server name using reduce
var uniqueSqlServerMap = reduce(enabledSqlServers, {}, (acc, curr) => contains(acc, curr.serverName) ? acc : union(acc, {
  '${curr.serverName}': {
    serverName: curr.serverName
    serverId: curr.serverId
  }
}))

// Convert the map back to an array
var uniqueSqlServersArray = map(items(uniqueSqlServerMap), item => item.value)

// ============================================================================
// Resources - Database Watcher
// ============================================================================

resource databaseWatcher 'Microsoft.DatabaseWatcher/watchers@2024-10-01-preview' = {
  name: watcherName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    datastore: {
      adxClusterResourceId: kustoCluster.id
      kustoClusterDisplayName: kustoCluster.name
      kustoClusterUri: kustoCluster.properties.uri
      kustoDataIngestionUri: kustoCluster.properties.dataIngestionUri
      kustoDatabaseName: kustoDatabaseName
      kustoManagementUrl: kustoManagementUrl
      kustoOfferingType: 'adx'
    }
  }
}

// ============================================================================
// Resources - Private Link Resources
// ============================================================================

// SQL Database Private Links (one per unique SQL Server, not per database)
resource sqlDbPrivateLinks 'Microsoft.DatabaseWatcher/watchers/sharedPrivateLinkResources@2024-10-01-preview' = [for server in uniqueSqlServersArray: {
  parent: databaseWatcher
  name: 'sqldb-${server.serverName}'
  properties: {
    privateLinkResourceId: server.serverId
    groupId: 'sqlServer'
    requestMessage: sqlPrivateLinkRequestMessage
  }
}]

// SQL Managed Instance Private Links (always required - MI doesn't support public access)
resource sqlMiPrivateLinks 'Microsoft.DatabaseWatcher/watchers/sharedPrivateLinkResources@2024-10-01-preview' = [for (target, i) in sqlManagedInstanceTargets: {
  parent: databaseWatcher
  name: 'sqlmi-${target.managedInstanceName}'
  properties: {
    privateLinkResourceId: sqlManagedInstances[i].id
    groupId: 'managedInstance'
    requestMessage: sqlPrivateLinkRequestMessage
    dnsZone: sqlManagedInstances[i].properties.dnsZone
  }
}]

// Kusto Cluster Private Link (if enabled)
resource kustoPrivateLink 'Microsoft.DatabaseWatcher/watchers/sharedPrivateLinkResources@2024-10-01-preview' = if (enableKustoPrivateLink) {
  parent: databaseWatcher
  name: 'kusto-cluster'
  properties: {
    privateLinkResourceId: kustoCluster.id
    groupId: 'cluster'
    dnsZone: kustoDnsZone
    requestMessage: kustoPrivateLinkRequestMessage
  }
}

// ============================================================================
// Resources - SQL Database Targets
// ============================================================================

resource sqlDatabaseTargets 'Microsoft.DatabaseWatcher/watchers/targets@2024-10-01-preview' = [for (target, i) in sqlTargets: {
  parent: databaseWatcher
  name: guid(watcherName, target.sqlServerName, target.databaseName)
  properties: {
    targetAuthenticationType: target.?authenticationType ?? 'Aad'
    connectionServerName: sqlServers[i].properties.fullyQualifiedDomainName
    targetType: 'SqlDb'
    targetVault: (target.?authenticationType ?? 'Aad') == 'Sql' ? {
      akvResourceId: sqlDbKeyVaults[i].id
      akvTargetUser: target.usernameSecretName
      akvTargetPassword: target.passwordSecretName
    } : null
    sqlDbResourceId: sqlDatabases[i].id
    readIntent: target.?readIntent ?? false
  }
}]

// ============================================================================
// Resources - SQL Managed Instance Targets
// ============================================================================

resource sqlMiTargets 'Microsoft.DatabaseWatcher/watchers/targets@2024-10-01-preview' = [for (target, i) in sqlManagedInstanceTargets: {
  parent: databaseWatcher
  name: guid(watcherName, target.managedInstanceName)
  properties: {
    targetAuthenticationType: target.?authenticationType ?? 'Aad'
    connectionServerName: sqlManagedInstances[i].properties.fullyQualifiedDomainName
    targetType: 'SqlMi'
    targetVault: (target.?authenticationType ?? 'Aad') == 'Sql' ? {
      akvResourceId: sqlMiKeyVaults[i].id
      akvTargetUser: target.usernameSecretName
      akvTargetPassword: target.passwordSecretName
    } : null
    sqlMiResourceId: sqlManagedInstances[i].id
    readIntent: target.?readIntent ?? false
  }
}]

// ============================================================================
// Outputs
// ============================================================================

@description('Resource ID of the created Database Watcher')
output watcherResourceId string = databaseWatcher.id

@description('Name of the created Database Watcher')
output watcherName string = databaseWatcher.name

@description('Principal ID of the Database Watcher managed identity')
output watcherPrincipalId string = databaseWatcher.identity.principalId

@description('Number of SQL Database targets configured')
output sqlDbTargetCount int = length(sqlTargets)

@description('Number of SQL Managed Instance targets configured')
output sqlMiTargetCount int = length(sqlManagedInstanceTargets)
