# Connect-AzAccount
$sqldbtargets = " "
$databases = " "


# Discover all Azure SQL Databases 
# Set the values for the json files so that all SQL Databases are listed


#Loop Subscriptions with SQL DBs
$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlServer -ErrorAction SilentlyContinue
  #if ($servers) {
   # [pscustomobject]@{
    #  SubscriptionName = $sub.Name
     # SubscriptionId   = $sub.Id
      #SqlServerCount   = $servers.Count } }
      
$sqlServers = Get-AzSqlServer
    foreach ($server in $sqlServers) 
    {

  # List SQL Databases in this server
  $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName | ?{$_.Edition -notlike "DataWarehouse" -and $_.DatabaseName -notlike "master"  }
     
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
           [""Subscription-ID"": ""$($sub.Id)"", 
            ""Resource-Group-Name"": ""$($db.ResourceGroupName)"",
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

}   

 


    # Discover all Azure SQL Managed Instances 
    # Set the values for the json files so that all SQL Managed Instances are listed
 
    $index = 0
 
     $sqlmanagedinstancetargets =  " 
        
        ""sqlManagedInstanceTargets"": 
        ""value"": [ "
    
$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlServer -ErrorAction SilentlyContinue
  #if ($servers) {
   # [pscustomobject]@{
    #  SubscriptionName = $sub.Name
     # SubscriptionId   = $sub.Id
      #SqlServerCount   = $servers.Count } }


    $managedInstances = Get-AzSqlInstance
    $totalCount = $managedInstances.Count
         if ($totalCount -ne 0 ) 
             {
                 $sqldbtargets = $sqldbtargets + ", "  
    
             }

    foreach ($mi in $managedInstances) 
        {
 
            $sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " 
           { ""Subscription-ID"": ""$($sub.id)"",
             ""Resource-Group-Name"": ""$($mi.ResourceGroupName)"",
             ""Managed-Instance-Name"": ""$($mi.ManagedInstanceName)"" "
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

}

$sqlmanagedinstancetargets = $sqlmanagedinstancetargets + " ] " 
$jsonscript = $sqlmitargets + $sqlmanagedinstancetargets #$jsonscript + 


$parmfileout =  $sqldbtargets + $jsonscript

# $parmfileout | Out-File -FilePath "C:\bicep\dbwatcher.parameters.json"

Write-Host $parmfileout




 