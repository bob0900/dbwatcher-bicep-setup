# Parameters List
    $dbwatchername = "DBWatcher-Robertc"
    $region = "eastus"
    $resourcegroupname = "SQL_Managed_Instance"
    $kustoclustername = "sqldb-watcher"
    $kustodatabasename = "dbwatcher"
    
 
#Set the values for the json files so that all SQL Managed Instances are listed

$sqlmitargets = "{" + "`$schema" + ":" + """https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"",
  ""contentVersion"": ""1.0.0.0"","


$sqlmitargets  = $sqlmitargets + "
  ""parameters"": {
    ""watcherName"": { ""value"":" +  "'" + $dbwatchername + "'" +  "},
    ""location"": { ""value"": " + "'" + $region + "'" + " },
    ""kustoResourceGroupName"": { ""value"":" + "'" + $resourcegroupname + "'" + " },
    ""kustoClusterName"": { ""value"":" + "'" + $kustoclustername + "'" +  " },
    ""kustoDatabaseName"": { ""value"":" + "'" +  $kustodatabasename + "'" + " }, "

 
 #Set the values for the json files so that all SQL Managed Instances are listed
 $index = 0
 
 $sqlmanagedinstancetargets =  " 
  ""sqlManagedInstanceTargets"": { ""value"": [ "
    
    $managedInstances = Get-AzSqlInstance
    $totalCount = $managedInstances.Count

    foreach ($mi in $managedInstances) 
    {
 
 # Write-Host "  Managed Instance: $($mi.ManagedInstanceName) - Resource Group: $($mi.ResourceGroupName)"
    
 
 $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " 
    { ""resourceGroupName"": ""$($mi.ResourceGroupName)"",
      ""managedInstanceName"": ""$($mi.ManagedInstanceName)"",
      ""authenticationType"": ""Aad"",
      ""readIntent"": false } "
      
      $index++

        if ($index -lt $managedInstances.Count)
            {
                $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + ","
                
            }
    
    }
 

 #Write-Host $sqlmanagedinstancetargets 
  
 
  # $jsonscript = " {
  # parameters: {
  #   watcherName: { value:" +  $dbwatchername + " },
  #  location: { value:" +  $region + " },
  #  kustoResourceGroupName: { value:" +  $resourcegroup + " },
  #  kustoClusterName: { alue:" +  $kustoclustername + " },
  #  kustoDatabaseName: { value:" +   $kustodatabasename + " }, } } "

$sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " ] } } } " 

$jsonscript = $sqlmitargets + $sqlmanagedinstancetargets #$jsonscript + 

Write-Host $jsonscript

$jsonscript | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"
