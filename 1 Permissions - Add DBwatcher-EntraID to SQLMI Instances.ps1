Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
Import-Module Az.Accounts -RequiredVersion 5.5.0 -Force
Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
Import-Module az.sql -RequiredVersion 7.0.0 -force

#Install-Module -Name Az.Accounts -Force -AllowClobber
#Install-Module -Name SqlServer -Force -AllowClobber

# Connect-AzAccount -UseDeviceAuthentication


$DBWatcher_Name = "DBWatcher-Robertc"

$query = "USE master;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE [name] = N'$DBWatcher_Name')
BEGIN
CREATE LOGIN [$DBWatcher_Name] FROM EXTERNAL PROVIDER;
End
GRANT CONNECT SQL, CONNECT ANY DATABASE, VIEW ANY DATABASE, VIEW ANY DEFINITION, VIEW SERVER PERFORMANCE STATE TO [$DBWatcher_Name];
USE msdb;
CREATE USER [DBWatcher-Robertc_user] FOR LOGIN [$DBWatcher_Name];
GRANT SELECT ON dbo.sysjobactivity TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.sysjobs TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.syssessions TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.sysjobhistory TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.sysjobsteps TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.syscategories TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.sysoperators TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.suspect_pages TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.backupset TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.backupmediaset TO [DBWatcher-Robertc_user];
GRANT SELECT ON dbo.backupmediafamily TO [DBWatcher-Robertc_user];"


# Get the access token for Azure SQL Database
#$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
$accessToken = "Must be Added"


#Loop Subscriptions for SQL MI Instances
$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlInstance | Where-Object { $_.AdministratorLogin -eq "robertc" } -ErrorAction SilentlyContinue
  #if ($servers) {
   # [pscustomobject]@{
    #  SubscriptionName = $sub.Name
     # SubscriptionId   = $sub.Id
      #SqlServerCount   = $servers.Count } }

        
 
 $sqlServers = Get-AzSqlInstance -ErrorAction SilentlyContinue
     foreach ($server in $sqlServers) { 

        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
        # List SQL Databases in this server

        $ServerInstancename = "$($server.FullyQualifiedDomainName)"
        $ResourceGroupName = "$($server.ResourceGroupName)"


        Write-Host "  "

        Write-Host "Managed Instance: $($ServerInstancename) - Resource Group: $($ResourceGroupName)"
        
        
  

if ($server.ResourceGroupName -like "**") 
        {

       
       #We need to know if there are special permissions needed to access the token. Bob K is getting an error
       
       #Invoke-Sqlcmd -ServerInstance $ServerInstancename -Database 'master' -Query $query -AccessToken $accessToken 
       



       #The code below is commented out but can be used to see the resource group name and the sql statements executed
       Write-Host "  "
       Write-Host "Invoke-Sqlcmd -ServerInstance $($ServerInstancename) -Database 'master' -Query $query -AccessToken $($accessToken)"
        
        }

                                        }

                                        }