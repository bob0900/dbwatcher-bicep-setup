#Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
#Update-Module -Name Az.Accounts -Force -RequiredVersion 5.5.1
#update-Module az.accounts -requiredversion 5.5.1 -Force 
#Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
#Import-Module az.sql -RequiredVersion 7.0.0 -force
#Install-Module -Name SqlServer -RequiredVersion 22.4.5.1 -Force -AllowClobber
#Import-Module SqlServer -RequiredVersion 22.4.5.1 


#Connect-AzAccount -UseDeviceAuthentication

$DBWatcherName = "DBWatcher-Name-Goes-Here"

$query = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$($DBWatcherName)')
BEGIN CREATE LOGIN [$($DBWatcherName)] FROM EXTERNAL PROVIDER; END
ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [$($DBWatcherName)];
ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [$($DBWatcherName)];
ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [$($DBWatcherName)];"


# Get the access token for Azure SQL MI
$accessToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net").Token

# Define inventory database details 
$DBMaintServer   = "sqldb-maintenance-robertc.database.windows.net"
$MaintDatabase = "dbMaintenance"
$SqlQuery = "SELECT  distinct top 75 a.servername FROM (select * from [dbo].[Targets] where ServiceTier not in ('DataWareHouse') ) a  WHERE a.AdminName Like '%' AND a.ResourceGroupName Like '%' "


# Execute the inventory resluts query and store the results in an array
$Rows = Invoke-Sqlcmd -ServerInstance $DBMaintServer -Database $Database -Query $SqlQuery -AccessToken $accessToken




$subsWithSqlServers = foreach ($sub in Get-AzSubscription) 
{

Set-AzContext -SubscriptionId $sub.Id | Out-Null


foreach ($Row in $Rows) 
{
        # Access individual columns using dot-property notation
        $SQLDBName = $Row.ServerName
    
    
        Write-Host ""

                
        #Write-Host "Invoke-Sqlcmd -ServerInstance $($SQLDBName) -Database 'master' -Query $query -AccessToken $($accessToken)"
        Invoke-Sqlcmd -ServerInstance $($SQLDBName) -Database 'master' -Query $query -AccessToken $($accessToken)

#Update SQL Inventory table with DB-WatcherName
$SQLUpdate = "UPDATE dbo.Targets
                   SET dbwatchername = '$DBWatcherName'
              WHERE servername = '$($Row.servername)'  AND ServiceTier != 'DataWarehouse' "

Write-Host  $SQLUpdate

Invoke-Sqlcmd -ServerInstance $($DBMaintServer) -Database $($MaintDatabase) -Query $SQLUpdate -AccessToken $($accessToken)

        

}
              
        
}

    