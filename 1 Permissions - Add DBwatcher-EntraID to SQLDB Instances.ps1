#Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
#Update-Module -Name Az.Accounts -Force -RequiredVersion 5.5.1
#update-Module az.accounts -requiredversion 5.5.1 -Force 
#Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
#Import-Module az.sql -RequiredVersion 7.0.0 -force
#Install-Module -Name SqlServer -RequiredVersion 22.4.5.1 -Force -AllowClobber
#Import-Module SqlServer -RequiredVersion 22.4.5.1 

#Connect-AzAccount -UseDeviceAuthentication
#Define inventory database details 
$DBWatcherName = "DBWatcher-Name-Goes-Here"
$DBMaintServer   = "sqldb-Name-Goes-Here.database.windows.net"
$MaintDatabase = "dbMaintenance"

$query = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$($DBWatcherName)')
BEGIN CREATE LOGIN [$($DBWatcherName)] FROM EXTERNAL PROVIDER; END
ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [$($DBWatcherName)];
ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [$($DBWatcherName)];
ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [$($DBWatcherName)];"

# Get the access token for Azure SQL MI
$accessToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net").Token

# Select Server and Databases to monitor 
$SqlQuery = "SELECT  distinct top 75 a.SubscriptionID, a.servername, a.DBName FROM (select * from [dbo].[Targets] where ServiceTier not in ('DataWareHouse') ) a  WHERE a.AdminName Like '%' AND a.ResourceGroupName Like '%' "


# Execute the inventory resluts query and store the results in an array
$Rows = Invoke-Sqlcmd -ServerInstance $DBMaintServer -Database $MaintDatabase -Query $SqlQuery -AccessToken $accessToken



foreach ($Row in $Rows) 
{

Set-AzContext -SubscriptionId $Row.SubscriptionID | Out-Null

# Access individual columns using dot-property notation such as $Row.xxxxx
$SQLSrvName = $Row.ServerName
$SQLDBName = $Row.DBName
    
Write-Host ""
Write-Host "Server Name = $($SQLSrvName) and Database Name = $($SQLDBName) "



#Update SQL Inventory table with DB-WatcherName
$SQLUpdate = "UPDATE dbo.Targets SET dbwatchername = '$DBWatcherName'
              WHERE servername = '$($SQLSrvName)' AND DBName = '$($SQLDBName)'  AND ServiceTier != 'DataWarehouse' "


Write-Host "$query"
#Add Permissions to SQL DB Server"      
Invoke-Sqlcmd -ServerInstance $($SQLSrvName) -Database 'master' -Query $query -AccessToken $($accessToken)
Write-Host ""
Write-Host  $SQLUpdate


Invoke-Sqlcmd -ServerInstance $($DBMaintServer) -Database $($MaintDatabase) -Query $SQLUpdate -AccessToken $($accessToken)

        
}
              
        


    