
# Connect-AzAccount

# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


# Set your key vault name and secret names
# $keyVaultName = "KV-Purview-Robertc"
# $usernameSecretName = "SecretUserName"
# $passwordSecretName = "dbPassword"
# Get the username and password secrets


# Parameters List
    $dbwatchername = "DBWatcher-Robertc"
    $region = "eastus"
    $resourcegroupname = "SQL_Managed_Instance"
    $kustoclustername = "sqldb-watcher"
    $kustodatabasename = "dbwatcher"

 
#Set the values for the json files so that all SQL Managed Instances are listed

$sqldbtargets = "
{
  parameters: {
    watcherName: { value:" +  $dbwatchername +  "},
    location: { value: " + $region + " },
    kustoResourceGroupName: { value:" + $resourcegroupname + " },
    kustoClusterName: { value:" +  $kustoclustername + " },
    kustoDatabaseName: { value:" +  $kustodatabasename + " }, "
    
  

    $sqlServers = Get-AzSqlServer
     foreach ($server in $sqlServers) {

         
        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
    
        
        # List SQL Databases in this server
        $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName | ?{$_.Edition -notlike "DataWarehouse" -and $_.DatabaseName -notlike "master" -and $_.Status -notlike "Paused" }
        
        $filtereddatabases = $databases

#Input database values

if ($databases.Count -ne 0) {
 $sqldbtargets = $sqldbtargets + "      { sqlTargets: { value: [ "
}

      
       foreach ($db in $filtereddatabases  ) {
            #Write-Host "    SQL Database: $($db.DatabaseName) - Database Edition: $($db.Edition)"

            
       $sqldbtargets = $sqldbtargets + "                       
                          { resourceGroupName: $($db.ResourceGroupName),
                            sqlServerName: $($db.ServerName),
                            databaseName: $($db.DatabaseName),
                            authenticationType: Aad,
                            enablePrivateLink: true,
                            readIntent: false }"
        }
    
if ($databases.Count -ne 0) {
    $sqldbtargets = $sqldbtargets + "                 ] } } "        
}    
    
    }

 
$sqldbtargets | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"
Write-Host $sqldbtargets


