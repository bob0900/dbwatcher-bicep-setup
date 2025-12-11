# Connect-AzAccount
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
    $sqlmanagedinstancetargets = " "
    $sqldbtargets = " "
    $sqlmitargets = " "
    $parmfileout = " "
    $MIsubscriptionId = " "
    $subscriptionId = " "
    $serverindex = 0 # server count index
    $index = 0 # database count index

#Set the values for the json files so that all SQL Managed Instances are listed


$sqldbtargets = "{" + "`$schema" + ":" + """https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"",
  ""contentVersion"": ""1.0.0.0"","


$sqldbtargets  = $sqldbtargets + "
  ""parameters"": {
    ""watcherName"": { ""value"":" +  "'" + $dbwatchername + "'" +  "},
    ""location"": { ""value"": " + "'" + $region + "'" + " },
    ""kustoResourceGroupName"": { ""value"":" + "'" + $resourcegroupname + "'" + " },
    ""kustoClusterName"": { ""value"":" + "'" + $kustoclustername + "'" +  " },
    ""kustoDatabaseName"": { ""value"":" + "'" +  $kustodatabasename + "'" + " }, "
    
  
$sqlServers = Get-AzSqlServer
    foreach ($server in $sqlServers) 
    {
        $serverindex++ 


  # List SQL Databases in this server
  $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName | ?{$_.Edition -notlike "DataWarehouse" -and $_.DatabaseName -notlike "master" -and $_.Status -notlike "Paused" }
   
  $subscriptionId = ($server.ResourceId -split '/subscriptions/')[1].Split('/')[0]
    #Write-Host "Subscription ID: $subscriptionId" 
   
     
  $filtereddatabases = $databases
  Write-Host $serverindex

#Input database values
    if (($databases -ne 0) -and ($serverindex -eq  1)) 
        {
        
          $sqldbtargets = $sqldbtargets + "      
       ""sqlTargets"": { ""value"": [ "
                
        }
    
    $index = 0
      
    foreach ($db in $filtereddatabases) 
                {
                    $sqldbtargets = $sqldbtargets + "                       
                              { ""subscriptionId"": ""$($subscriptionId)"",
                                ""resourceGroupName"": ""$($db.ResourceGroupName)"",
                                ""sqlServerName"": ""$($db.ServerName)"",
                                ""databaseName"": ""$($db.DatabaseName)"",
                                ""authenticationType"": ""Aad"",
                                ""enablePrivateLink"": true,
                                ""readIntent"": false }"
                    $index++

                if ($index -lt $filtereddatabases.Count)
                    {
                        $sqldbtargets = $sqldbtargets + ","
                
                    }
                
                if ($databases.Count -eq $index ) 
                    {
                        $sqldbtargets = $sqldbtargets + " ] }"  
    
                    } 
                }
    } 

   
 
    # Discover all Azure SQL Managed Instances 
    # Set the values for the json files so that all SQL Managed Instances are listed
 
    $index = 0
 
     $sqlmanagedinstancetargets =  " 
        ""sqlManagedInstanceTargets"": { ""value"": [ "
    
    $managedInstances = Get-AzSqlInstance
    $totalCount = $managedInstances.Count
         if ($totalCount -ne 0 ) 
             {
                 $sqldbtargets = $sqldbtargets + ", "  
    
             }

    foreach ($mi in $managedInstances) 
        {

    $MIsubscriptionId = ($mi.Id -split '/subscriptions/')[1].Split('/')[0]
    #Write-Host "Subscription ID: $MIsubscriptionId" 
 
            $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " 
                {   ""subscriptionId"": ""$($MIsubscriptionId)"",
                    ""resourceGroupName"": ""$($mi.ResourceGroupName)"",
                    ""managedInstanceName"": ""$($mi.ManagedInstanceName)"",
                    ""authenticationType"": ""Aad"",
                    ""readIntent"": false } "
            $index++

      if ($index -lt $managedInstances.Count)
            {
                $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + ","
                
            }
    
        }
      
       if ($totalCount -eq 0 ) 
          {
            $sqlmanagedinstancetargets = " "  
          }


$sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " ] } }  } " 
$jsonscript = $sqlmitargets + $sqlmanagedinstancetargets #$jsonscript + 


$parmfileout =  $sqldbtargets + $jsonscript

#$parmfileout | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"

Write-Host $parmfileout




 