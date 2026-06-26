# Connect-AzAccount

#  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    
    
 # Parameters List
    $dbwatchername = "DBWatcher-Robertc"
    $region = "eastus"
    $resourcegroupname = "SQL_Managed_Instance"
    $kustoclustername = "sqldb-watcher"
    $kustodatabasename = "dbwatcher"

 
 #Set the values for the json files so that all SQL Managed Instances are listed
 $sqlmanagedinstancetargets =  " 
 { sqlManagedInstanceTargets: { value: [ "
    
    $managedInstances = Get-AzSqlInstance
    foreach ($mi in $managedInstances) {
 
 # Write-Host "  Managed Instance: $($mi.ManagedInstanceName) - Resource Group: $($mi.ResourceGroupName)"
    
 
 $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " 
    { resourceGroupName: $($mi.ResourceGroupName),
      managedInstanceName: $($mi.ManagedInstanceName),
      authenticationType: Aad,
      readIntent: false } "
  
  
  $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " ] } } " 
    }
 
 
 #Write-Host $sqlmanagedinstancetargets 
    
 
  $jsonscript = " {
  parameters: {
    watcherName: { value:" +  $dbwatchername + " },
    location: { value:" +  $region + " },
    kustoResourceGroupName: { value:" +  $resourcegroup + " },
    kustoClusterName: { alue:" +  $kustoclustername + " },
    kustoDatabaseName: { value:" +   $kustodatabasename + " }, } } "

$jsonscript = $jsonscript + $sqlmanagedinstancetargets

Write-Host $jsonscript
    
 