Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
Import-Module Az.Accounts -RequiredVersion 5.5.0 -Force
Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
Import-Module az.sql -RequiredVersion 7.0.0 -force
Install-Module -Name SqlServer -RequiredVersion 22.4.5.1 -Force -AllowClobber
Import-Module SqlServer -RequiredVersion 22.4.5.1 


#Install-Module -Name Az.Accounts -Force -AllowClobber
#Install-Module -Name SqlServer -Force -AllowClobber

#Connect-AzAccount -UseDeviceAuthentication

$query = "CREATE LOGIN [DBWatcher-Robertc] FROM EXTERNAL PROVIDER;
ALTER SERVER ROLE ##MS_ServerPerformanceStateReader## ADD MEMBER [DBWatcher-Robertc];
ALTER SERVER ROLE ##MS_DefinitionReader## ADD MEMBER [DBWatcher-Robertc];
ALTER SERVER ROLE ##MS_DatabaseConnector## ADD MEMBER [DBWatcher-Robertc];"

# Get the access token for Azure SQL MI
$accessToken = (Get-AzAccessToken -ResourceUrl "https://database.windows.net").Token


$subsWithSqlServers = foreach ($sub in Get-AzSubscription) {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlInstance -ErrorAction SilentlyContinue
  
  
  
  
   
  
$sqlServers = Get-AzSqlInstance -ErrorAction SilentlyContinue
     foreach ($server in $sqlServers) {

        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
        # List SQL Databases in this server

        $ServerInstancename = "$($server.FullyQualifiedDomainName)"

        Write-Host $ServerInstancename
        #Write-Host "   InstaneName - $($ServerInstancename) - SQL Database: $($db.DatabaseName) - Database Edition: $($db.Edition)"

       #Invoke-Sqlcmd -ServerInstance $ServerInstancename -Database 'master' -Query $query -AccessToken $accessToken 
                  
                                       }
    if ($server.ResourceGroupName -like "*") 
      {
        
        
        $admin = Get-AzSqlServerActiveDirectoryAdministrator `
                    -ResourceGroupName $server.ResourceGroupName `
                    -ServerName $server.ServerName `
                    -ErrorAction SilentlyContinue

      if ($admin -and $admin.ObjectId -eq "5fbc5476-2e5f-45b8-b3a8-2f3092f79d5c") 
      
      {
            [PSCustomObject]@{
                SubscriptionId = [string]$sub.Id
                ServerName     = [string]$server.ServerName
                ResourceGroup  = [string]$server.ResourceGroupName
                AdminObjectId  = [string]$admin.ObjectId
                AdminName      = [string]$admin.DisplayName }
                 
        Invoke-Sqlcmd -ServerInstance $ServerInstancename -Database 'master' -Query $query -AccessToken $accessToken 
       
      }
              
       #The code below is commented out but can be used to see the resource group name and the sql statements executed
       # Write-Host "$($Server.ResourceGroupName)" 
       #Write-Output "Invoke-Sqlcmd -ServerInstance $($ServerInstancename) -Database 'master' -Query $query -AccessToken $($accessToken)" | Out-File -FilePath "C:\Temp\Output.csv" 
       Write-Output "ResourceGroupName: $($Server.ResourceGroupName) ServerName: $($ServerInstancename) Permissions Onboarded" | Out-File -FilePath "C:\Temp\Output.csv" 
               
      }

        

                                                            }

  