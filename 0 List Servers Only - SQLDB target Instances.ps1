$SQL_Command = ''
#install-Module -Name Az.* -Force -AllowClobber
#install-Module -Name SqlServer -Force -AllowClobber
#Update-Module -Name Az.Accounts -Force -RequiredVersion 5.5.1
# update-Module az.accounts -requiredversion 5.5.1 -Force 
# Import-Module Az.Accounts -RequiredVersion 5.5.1 -Force 
# Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
# import-Module az.sql -RequiredVersion 7.0.0 -force 
#uninstall-module az.accounts -Force 
#Install-Module -Name Az.Accounts -RequiredVersion 5.3.3 -Force -AllowClobber
#update-Module -Name Az.accounts -Force
#Install-Module -Name Az -Repository PSGallery -Force


#Connect-AzAccount -devicecode

$DBWatcherName = "Must BE UPDATED"
$MainServerName = "sqldb-maintenance-robertc.database.windows.net"
$MaintDBName = "dbMaintenance"
$DBName = ""
$ServiceTier = ""
$ComputeTier = ""
$DeploymentModel = ""
$AdminName = ""
$ResourceGroupName = ""
$LogicalSQLDB = ""


#Get the access token for Azure SQL DB
$accessToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net").Token


$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {

Set-AzContext -SubscriptionId $sub.Id | Out-Null
  
$sqlServers = Get-AzSqlServer -ErrorAction SilentlyContinue

foreach ($server in $sqlServers) {

        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
        # List SQL Databases in this server
        $ServerInstancename = $server.FullyQualifiedDomainName

#$LogicalSQLDB = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName |
#        Where-Object { $_.DatabaseName -ne "master" } |
#            Select-Object *, 
#                  @{Name="DeploymentModel"; Expression={if($_.ElasticPoolName){"Elastic Pool ($($_.ElasticPoolName))"}else{"Single Database"}} 


Write-Host "--- Processing Server: $($server.ServerName) ---" -ForegroundColor Cyan

$SQLDBs =  Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -ErrorAction SilentlyContinue |
        Where-Object { $_.DatabaseName -ne "master" } |
           Select-Object *, 
                @{Name="DeploymentModel"; Expression={if($_.ElasticPoolName){"Elastic Pool ($($_.ElasticPoolName))"}else{"Single Database"}}} -ErrorAction SilentlyContinue
    

foreach ($LogicalSQLDB in $SQLDBs)   {

        $ResourceGroupName = $server.ResourceGroupName 
        $DBName = $LogicalSQLDB.DatabaseName
        $ServiceTier = $LogicalSQLDB.Edition
        $ComputeTier = $LogicalSQLDB.CurrentServiceObjectiveName
        $DeploymentModel = $LogicalSQLDB.Deploymentmodel
        $AdminName = $server.SqlAdministratorLogin


Write-Host "    Found Database: $($LogicalSQLDB.DatabaseName)" -ForegroundColor Green 
   
#Provides the ability to filter by Resource Groups such as test and prod  
if ($server.ResourceGroupName -like "**") 
                            {
        $admin = Get-AzSqlServerActiveDirectoryAdministrator `
                    -ResourceGroupName $server.ResourceGroupName `
                   -ServerName $server.ServerName `
                    -ErrorAction SilentlyContinue

#Query used to insert target sqldb's to DBWatcher 

$query = ""
$query = " IF NOT EXISTS (SELECT 1 FROM dbo.Targets WHERE servername = '$ServerInstancename' and DBNAME = '$DBNAME' )
            BEGIN
                    INSERT INTO dbo.Targets (AdminName, ResourceGroupName, servername, servertype, DeploymentModel, ServiceTier, DBNAME, contactperson, dbwatchername, enrolled, RegistrationDate )
                    VALUES ('$AdminName', '$ResourceGroupName', '$ServerInstancename', 'Azure SQL Database', '$DeploymentModel', '$ServiceTier', '$DBNAME', 'DBA@BigCorp.com', '$DBWatcherName', 'N' , GETDATE() ); 
            END
                    ELSE
            BEGIN
                    UPDATE dbo.Targets
                           SET AdminName = '$AdminName', ResourceGroupName = '$ResourceGroupName', DeploymentModel = '$DeploymentModel', ServiceTier = '$ServiceTier'
                    WHERE servername = '$ServerInstancename' AND DBNAME = '$DBNAME';

            END "



       Invoke-Sqlcmd -ServerInstance $MainServerName -Database $MaintDBName -AccessToken $accessToken -Query $query
       Invoke-Sqlcmd -ServerInstance $MainServerName -Database $MaintDBName -AccessToken $accessToken -Query 'GO' 
       Write-host ""
       Write-host $query
       
       }
     }
   }  
  
  }
 