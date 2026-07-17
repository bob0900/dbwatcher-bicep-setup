#Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
#Update-Module -Name Az.Accounts -Force -RequiredVersion 5.5.1
#update-Module az.accounts -requiredversion 5.5.1 -Force 
#Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
#Import-Module az.sql -RequiredVersion 7.0.0 -force
#Install-Module -Name SqlServer -RequiredVersion 22.4.5.1 -Force -AllowClobber
#Import-Module SqlServer -RequiredVersion 22.4.5.1 


#Connect-AzAccount -UseDeviceAuthentication

# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


# Set your key vault name and secret names
# $keyVaultName = "KV-Purview-Robertc"
# $usernameSecretName = "SecretUserName"
# $passwordSecretName = "dbPassword"
# Get the username and password secrets

#Allow remote PowerShell scripts to run
Enable-PSRemoting -Force


# Parameters List
    $dbwatchername = "DBWatcher-Robertc"
    $region = "eastus"
    $resourcegroupname = "SQL_Managed_Instance"
    $kustoclustername = "sqldb-watcher"
    $kustodatabasename = "dbwatcher"

# Get the access token for Azure SQL MI
$accessToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net").Token


$sqldbtargets = "{" + "`$schema" + ":" + """https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"",
  ""contentVersion"": ""1.0.0.0"","


#Set the values for the json files so that all SQL-DB Instances are listed
$sqldbtargets  = $sqldbtargets + "
  ""parameters"": {
    ""watcherName"": { ""value"":""$($dbwatchername)"" },
    ""location"": { ""value"":""$($region)""},
    ""kustoResourceGroupName"": { ""value"":""$($resourcegroupname)"" },
    ""kustoClusterName"": { ""value"": ""$($kustoclustername)"" },
    ""kustoDatabaseName"": { ""value"": ""$($kustodatabasename)"" }, "



$sqldbtargets = $sqldbtargets + "       ""sqlTargets"": { ""value"": [  "

# Define inventory database details 
$DBMaintServer   = "sqldb-maintenance-robertc.database.windows.net"
$MaintDatabase = "dbMaintenance"
$SqlQuery = "SELECT  distinct top 75 a.subscriptionId, a.servername, a.ResourceGroupName, a.DBNAME FROM (select * from [dbo].[Targets] where ServiceTier not in ('DataWareHouse') ) a  WHERE a.AdminName Like '%' AND a.ResourceGroupName Like '%' and DBWatcherName = '$dbwatchername' "

# Execute the inventory resluts query and store the results in an array
$Rows = Invoke-Sqlcmd -ServerInstance $DBMaintServer -Database $MaintDatabase -Query $SqlQuery -AccessToken $accessToken


$counter = 0

foreach ($Row in $Rows) {

$totalrows = $Rows.Count 


#Input database values
if ($Rows.Count -ne 0)       {
#$sqldbtargets = $sqldbtargets + "      { sqlTargets: { value: [ "
                            
      
    $sqldbtargets = $sqldbtargets + " 
                            {""subscriptionId"": ""$($row.SubscriptionID)"",                                 
                            ""resourceGroupName"": ""$($row.ResourceGroupName)"",
                            ""sqlServerName"": ""$((($row.ServerName) -split "\.")[0])"",
                            ""databaseName"": ""$($row.DBNAME)"",
                            ""authenticationType"": ""Aad"",
                            ""enablePrivateLink"": true,
                            ""readIntent"": false }"


     


$counter++
Write-Host $counter
if ($counter -ne $totalrows) {
        $sqldbtargets = $sqldbtargets + ","

                             }

        
#Update SQL Inventory table with DB-WatcherName
$SQLUpdate = "UPDATE dbo.Targets
                   SET enrolled = 'Y'
              WHERE servername = '$($Row.servername)' AND [DBNAME] = '$($Row.DBNAME)'  AND ServiceTier != 'DataWarehouse' "

Write-Host  $SQLUpdate

Invoke-Sqlcmd -ServerInstance $($DBMaintServer) -Database $($MaintDatabase) -Query $SQLUpdate -AccessToken $($accessToken)

  
  
                            }

                        }
   
if ($row.Count -ne 0) {
    $sqldbtargets = $sqldbtargets + "                 ] } } } "        
                      }


$sqldbtargets | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"

Write-Host $sqldbtargets


# Onboard the servers to Database Watcher using deployment script
#pwsh -File "C:\bicep\deploy-dbwatcher.ps1"  -ResourceGroupName "rg-database-watcher"
