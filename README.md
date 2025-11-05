# Configuring Database Watcher SQL Targets using Bicep

This repository contains a parameterized Bicep template for deploying **Azure Database Watcher** with support for monitoring **Azure SQL Database** and **SQL Managed Instance** targets. The template leverages existing resource references to simplify configuration and supports multiple authentication methods including SQL Authentication, Azure AD, and Managed Identity.

## 📋 What's Included

- **Bicep Template** (`dbwatcher-parametrized.bicep`) - Infrastructure as Code for Database Watcher
- **Parameters File** (`dbwatcher-parametrized.parameters.json`) - Configuration values
- **PowerShell Deployment Script** (`deploy-dbwatcher.ps1`) - Automated deployment with validation

## 📦 Prerequisites

Before deploying, ensure you have the following resources already created:

### Required Resources

1. **Azure Data Explorer (ADX) Cluster**
   - An existing ADX cluster for storing monitoring data
   - A database created within the cluster (e.g., `dbwatcher`)

2. **Azure SQL Database** or **SQL Managed Instance**
   - One or more SQL databases or managed instances to monitor
   - Appropriate firewall rules configured
   - Make sure to grant required permissions on target server to DBWatcher login/EntraID principal

3. **Azure Key Vault** (Optional - only for SQL Authentication)
   - Required if using SQL Authentication (`authenticationType: 'Sql'`)
   - Must contain secrets for SQL username and password
   - Not needed for Azure AD or Managed Identity authentication

4. **Azure PowerShell** or **Azure CLI**
   - For deployment and resource validation

## 🚀 Quick Start

### Step 1: Clone or Download

```bash
git clone <repository-url>
cd dbwatcher
```

### Step 2: Configure Parameters

Edit `dbwatcher-parametrized.parameters.json` with your values:

```json
{
  "parameters": {
    "watcherName": { "value": "my-database-watcher" },
    "location": { "value": "East US" },
    "kustoResourceGroupName": { "value": "rg-kusto" },
    "kustoClusterName": { "value": "mykustocluster" },
    "kustoDatabaseName": { "value": "dbwatcher" },
    "sqlTargets": { "value": [ /* see examples below */ ] }
  }
}
```

### Step 3: Deploy

#### Using PowerShell Script (Recommended):
```powershell
.\deploy-dbwatcher.ps1 -ResourceGroupName "rg-database-watcher"
```

#### Using Azure CLI:
```bash
az deployment group create \
  --resource-group rg-database-watcher \
  --template-file dbwatcher-parametrized.bicep \
  --parameters @dbwatcher-parametrized.parameters.json
```

## 📖 Configuration Guide

### Monitoring Azure SQL Database

#### Option 1: Using Azure AD Authentication (Recommended)

**Advantages:**
- ✅ No secrets to manage
- ✅ More secure
- ✅ No Key Vault required

**Configuration:**

```json
{
  "sqlTargets": {
    "value": [
      {
        "resourceGroupName": "rg-sql-prod",
        "sqlServerName": "myserver",
        "databaseName": "webapp-prod",
        "authenticationType": "Aad",
        "enablePrivateLink": true,
        "readIntent": false
      }
    ]
  }
}
```

**Required Setup:**

1. After deployment, get the Database Watcher's Managed Identity Principal ID from outputs:
   ```powershell
   $watcherPrincipalId = (Get-AzResourceGroupDeployment -ResourceGroupName "rg-database-watcher" -Name "latest").Outputs.watcherPrincipalId.Value
   ```

2. Connect to your SQL Database and create a user for the Database Watcher:
   ```sql
   -- Connect as Azure AD admin
   CREATE LOGIN [my-database-watcher] FROM EXTERNAL PROVIDER;
   
   -- Grant necessary permissions
   ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [my-database-watcher];
   ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [my-database-watcher];
   ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [my-database-watcher];
   ```

#### Option 2: Using SQL Authentication

**When to use:**
- Legacy applications requiring SQL auth
- Environments without Azure AD integration

**Configuration:**

```json
{
  "sqlTargets": {
    "value": [
      {
        "resourceGroupName": "rg-sql-legacy",
        "sqlServerName": "legacyserver",
        "databaseName": "legacy-app",
        "authenticationType": "Sql",
        "keyVaultResourceGroupName": "rg-keyvault",
        "keyVaultName": "mykeyvault",
        "usernameSecretName": "sql-username",
        "passwordSecretName": "sql-password",
        "enablePrivateLink": true,
        "readIntent": false
      }
    ]
  }
}
```

**Required Setup:**

1. Create secrets in Key Vault:
   ```powershell
   $username = "dbwatcher-user"
   $password = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force
   
   Set-AzKeyVaultSecret -VaultName "mykeyvault" -Name "sql-username" -SecretValue (ConvertTo-SecureString $username -AsPlainText -Force)
   Set-AzKeyVaultSecret -VaultName "mykeyvault" -Name "sql-password" -SecretValue $password
   ```

2. Grant Database Watcher access to Key Vault (after deployment):
   ```powershell
   $watcherPrincipalId = "<from-deployment-output>"
   
   Set-AzKeyVaultAccessPolicy `
     -VaultName "mykeyvault" `
     -ObjectId $watcherPrincipalId `
     -PermissionsToSecrets Get
   ```

3. Create SQL login and user in your database:
   ```sql
   -- On master database
   CREATE LOGIN [dbwatcher-user] WITH PASSWORD = 'YourSecurePassword123!';
 
   ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [dbwatcher-user];
   ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [dbwatcher-user];
   ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [dbwatcher-user];
   ```

### Monitoring SQL Managed Instance

SQL Managed Instance targets work similarly, with automatic private link creation.

#### Using Azure AD Authentication (Recommended)

```json
{
  "sqlManagedInstanceTargets": {
    "value": [
      {
        "resourceGroupName": "rg-sqlmi-prod",
        "managedInstanceName": "mi-enterprise-prod",
        "authenticationType": "Aad",
        "readIntent": false
      }
    ]
  }
}
```

**Setup:**
1. Create user in MI (same SQL commands as SQL Database above)
2. Grant permissions

#### Using SQL Authentication

```json
{
  "sqlManagedInstanceTargets": {
    "value": [
      {
        "resourceGroupName": "rg-sqlmi-legacy",
        "managedInstanceName": "mi-legacy",
        "authenticationType": "Sql",
        "keyVaultResourceGroupName": "rg-keyvault",
        "keyVaultName": "mykeyvault",
        "usernameSecretName": "mi-sql-username",
        "passwordSecretName": "mi-sql-password",
        "readIntent": false
      }
    ]
  }
}
```

**Setup:** Same as SQL Database SQL Auth above.

## 🔐 Private Link Configuration

### SQL Database
- **Optional**: Set `enablePrivateLink: false` per target
- **Automatic Deduplication**: Only one private link created per unique SQL Server (even with multiple databases)
- **Default**: `true` (private link enabled by default)

### SQL Managed Instance
- **Always Enabled**: Private links are automatically created for all MI targets

### Kusto Cluster
- **Optional**: Set `enableKustoPrivateLink: true` in parameters
- **DNS Zone**: Specify the region (e.g., `"eastus"`)

## 📊 Post-Deployment Steps

After successful deployment:

### 1. Start DB Watcher

### 2. Grant Kusto Permissions

The Database Watcher needs permissions to ingest data into Kusto:

```kusto
// In Kusto database (dbwatcher)
.add database dbwatcher ingestors ('aadapp=<watcher-principal-id>')
.add database dbwatcher viewers ('aadapp=<watcher-principal-id>')
```

### 3. Approve Private Endpoint Connections (if using Private Link)

Go to Azure Portal and approve private endpoint connections in:
- SQL Server resources
- SQL Managed Instance resources  
- Kusto cluster (if enabled)

### 4. Verify Monitoring

Check the Database Watcher status:
```powershell
Get-AzResource -Name "my-database-watcher" -ResourceType "Microsoft.DatabaseWatcher/watchers"
```

Query monitoring data in Kusto:
```kusto
// In your Kusto database
database("dbwatcher").tables
```

## 🔧 Advanced Configuration

### Multiple Databases on Same Server

The template intelligently handles multiple databases on the same SQL Server:

```json
{
  "sqlTargets": {
    "value": [
      {
        "sqlServerName": "shared-server",
        "databaseName": "app1",
        "authenticationType": "Aad",
        "enablePrivateLink": true
      },
      {
        "sqlServerName": "shared-server",
        "databaseName": "app2",
        "authenticationType": "Aad",
        "enablePrivateLink": true
      }
    ]
  }
}
```

✅ Result: Only **one** private link is created for `shared-server`

### Cross-Subscription Monitoring

Monitor resources in different subscriptions:

```json
{
  "subscriptionId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "resourceGroupName": "rg-other-subscription",
  "sqlServerName": "remote-server",
  "databaseName": "remote-db",
  "authenticationType": "Aad"
}
```

### Read-Only Intent

For read-only replicas or read-scale scenarios:

```json
{
  "sqlServerName": "myserver",
  "databaseName": "mydb",
  "authenticationType": "Aad",
  "readIntent": true  // ← Enable read-only intent
}
```

## 📝 Parameters Reference

### SQL Database Target Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `resourceGroupName` | ✅ Yes | - | Resource group of SQL Server |
| `sqlServerName` | ✅ Yes | - | Name of SQL Server |
| `databaseName` | ✅ Yes | - | Name of database to monitor |
| `authenticationType` | ❌ No | `Aad` | `Sql` or `Aad`|
| `subscriptionId` | ❌ No | Current | Subscription ID of SQL Server |
| `enablePrivateLink` | ❌ No | `true` | Enable private link for this server |
| `readIntent` | ❌ No | `false` | Use read-only intent |
| `keyVaultResourceGroupName` | ⚠️ Conditional | - | Required for SQL Auth |
| `keyVaultName` | ⚠️ Conditional | - | Required for SQL Auth |
| `usernameSecretName` | ⚠️ Conditional | - | Required for SQL Auth |
| `passwordSecretName` | ⚠️ Conditional | - | Required for SQL Auth |

### SQL MI Target Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `resourceGroupName` | ✅ Yes | - | Resource group of SQL MI |
| `managedInstanceName` | ✅ Yes | - | Name of SQL Managed Instance |
| `authenticationType` | ❌ No | `Aad` | `Sql` or `Aad` |
| `subscriptionId` | ❌ No | Current | Subscription ID of SQL MI |
| `readIntent` | ❌ No | `false` | Use read-only intent |
| `keyVaultResourceGroupName` | ⚠️ Conditional | - | Required for SQL Auth |
| `keyVaultName` | ⚠️ Conditional | - | Required for SQL Auth |
| `usernameSecretName` | ⚠️ Conditional | - | Required for SQL Auth |
| `passwordSecretName` | ⚠️ Conditional | - | Required for SQL Auth |

## 🛠️ Troubleshooting

### Deployment Fails with "Cannot find Bicep"

**Solution:** Install Bicep CLI or Azure CLI:
```powershell
# Using Azure CLI
az bicep install

# Or using winget
winget install Microsoft.Bicep

# Or using Chocolatey
choco install bicep
```

### "Access Denied" when Database Watcher tries to connect

**For Azure AD Auth:**
- Ensure the managed identity user was created in the database
- Check permissions

**For SQL Auth:**
- Verify Key Vault access policy for Database Watcher managed identity
- Confirm secrets exist and have correct values
- Check SQL user exists and has required permissions

### Private Endpoint not connecting

1. Check private endpoint approval status in Azure Portal
2. Verify DNS resolution (for private DNS zones)
3. Ensure Network Security Group (NSG) rules allow traffic

### No data appearing in Kusto

1. Verify Kusto database permissions (`ingestors` and `viewers` roles)
2. Check Database Watcher status in Portal
3. Review Database Watcher activity logs

## 📚 Additional Resources

- [Azure Database Watcher Documentation](https://learn.microsoft.com/azure/azure-sql/database-watcher-overview)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure SQL Database Security Best Practices](https://learn.microsoft.com/azure/azure-sql/database/security-best-practice)
- [Managed Identity Overview](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Marcelo Fonseca**
- **Sam Mesel**

## 🙏 Acknowledgments

- Azure Database Watcher team for the service
- Microsoft Azure documentation team
- Community contributors

---

**Questions or Issues?** Please open an issue in this repository.
