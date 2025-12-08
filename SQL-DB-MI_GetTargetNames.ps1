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

#Set the values for the json files so that all SQL Managed Instances are listed

$sqlServers = Get-AzSqlServer
    foreach ($server in $sqlServers) 
    {

  # List SQL Databases in this server
  $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName | ?{$_.Edition -notlike "DataWarehouse" -and $_.DatabaseName -notlike "master" -and $_.Status -notlike "Paused" }
     
  $filtereddatabases = $databases

#Input database values
    if ($databases.Count -ne 0) 
        {
        $sqldbtargets = $sqldbtargets + "      
        
        ""sqlTargets"": 
        ""value"": [ "
        }
    
    $index = 0
      
    foreach ($db in $filtereddatabases) 
                {
                    $sqldbtargets = $sqldbtargets + "                       
           [ ""resourceGroupName"": ""$($db.ResourceGroupName)"",
             ""sqlServerName"": ""$($db.ServerName)"",
             ""databaseName"": ""$($db.DatabaseName)"" "
                    $index++

           if ($index -lt $filtereddatabases.Count)
               {
                 $sqldbtargets = $sqldbtargets + ","
                
               }
                
           if ($databases.Count -eq $index ) 
               {
                 $sqldbtargets = $sqldbtargets + " ]"  
    
                   } 
                }
    } 

   
 
    # Discover all Azure SQL Managed Instances 
    # Set the values for the json files so that all SQL Managed Instances are listed
 
    $index = 0
 
     $sqlmanagedinstancetargets =  " 
        
        ""sqlManagedInstanceTargets"": 
        ""value"": [ "
    
    $managedInstances = Get-AzSqlInstance
    $totalCount = $managedInstances.Count
         if ($totalCount -ne 0 ) 
             {
                 $sqldbtargets = $sqldbtargets + ", "  
    
             }

    foreach ($mi in $managedInstances) 
        {
 
            $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " 
           { ""resourceGroupName"": ""$($mi.ResourceGroupName)"",
             ""managedInstanceName"": ""$($mi.ManagedInstanceName)"" "
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


$sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " ] " 
$jsonscript = $sqlmitargets + $sqlmanagedinstancetargets #$jsonscript + 


$parmfileout =  $sqldbtargets + $jsonscript

# $parmfileout | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"

Write-Host $parmfileout




 