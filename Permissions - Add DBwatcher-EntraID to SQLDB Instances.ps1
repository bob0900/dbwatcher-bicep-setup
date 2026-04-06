#install-Module -Name Az.* -Force -AllowClobber
#install-Module -Name SqlServer -Force -AllowClobber
#install-module az.sql
#uninstall-module az.sql

#update-Module -Name Az.accounts
#Install-Module -Name Az -Repository PSGallery -Force

#Install-Module -Name Az.Accounts -RequiredVersion 5.3.3 -Scope CurrentUser -Force


#Connect-AzAccount

$DBWatcher_Name = "DBWatcher-NameGoesHere"

$query = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE [name] = '$DBWatcher_Name')
CREATE LOGIN [$DBWatcher_Name] FROM EXTERNAL PROVIDER;
ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [$DBWatcher_Name];
ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [$DBWatcher_Name];
ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [$DBWatcher_Name];"


# Get the access token for Azure SQL Database
$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token


$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlServer -ErrorAction SilentlyContinue
  #if ($servers) 
   # [pscustomobject]
    #  SubscriptionName = $sub.Name
     # SubscriptionId   = $sub.Id
      #SqlServerCount   = $servers.Count 
  
  
$sqlServers = Get-AzSqlServer -ErrorAction SilentlyContinue
     foreach ($server in $sqlServers) {

        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
        # List SQL Databases in this server

        $ServerInstancename = "$($server.ServerName).database.windows.net"

        #Write-Host $ServerInstancename
        #Write-Host "   InstaneName - $($ServerInstancename) - SQL Database: $($db.DatabaseName) - Database Edition: $($db.Edition)"

if ($server.ResourceGroupName -like "*rg*") 
        {

       
       
       Invoke-Sqlcmd -ServerInstance $ServerInstancename -Database 'master' -Query $query -AccessToken $accessToken 
       
       #The code below is commented out but can be used to see the resource group name and the sql statements executed
       #Write-Host "$($Server.ResourceGroupName)" 
       #Write-Host "Invoke-Sqlcmd -ServerInstance $($ServerInstancename) -Database 'master' -Query $query -AccessToken $($accessToken)"
        
        }
       
           
           }
            
                   }

  