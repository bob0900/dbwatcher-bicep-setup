$SQL_Command = ''
#install-Module -Name Az.* -Force -AllowClobber
#install-Module -Name SqlServer -Force -AllowClobber
#install-module az.sql
#Update-Module -Name Az.Accounts -Force -RequiredVersion 5.5.0
# Install-Module az.accounts -MinimumVersion 5.5.0 -Force -AllowClobber
# Import-Module Az.Accounts -RequiredVersion 5.5.0 -Force 
# Install-module az.sql -RequiredVersion 7.0.0 -Force -AllowClobber
# Import-Module az.sql -RequiredVersion 7.0.0 -force 
#uninstall-module az.accounts -Force 

#update-Module -Name Az.accounts
#Install-Module -Name Az -Repository PSGallery -Force

#Install-Module -Name Az.Accounts -scope CurrentUser -RequiredVersion 5.3.3 -Force

# Connect-AzAccount -devicecode

# Get the access token for Azure SQL Database
#$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token


$subsWithSqlServers = foreach ($sub in Get-AzSubscription) 
            {
  Set-AzContext -SubscriptionId $sub.Id | Out-Null
  $servers = Get-AzSqlInstance -ErrorAction SilentlyContinue
  
 
$sqlServers = Get-AzSqlInstance -ErrorAction SilentlyContinue
     foreach ($server in $sqlServers) 
  {

        #Write-Host "  SQL Server: $($server.ServerName) - Resource Group: $($server.ResourceGroupName)"
        # List SQL Databases in this server

        $ServerInstancename = "$($server.FullyQualifiedDomainName)"
        $ResourceGroupName = "$($server.ResourceGroupName)"

        #List all instances non-filtered
        #Write-Host $ServerInstancename
        #Write-Host " SubscriptionName: $($sub.Name)   Resource Group: $($server.ResourceGroupName)      DB-InstaneName - $($ServerInstancename)" 
   
   
#Provides the ability to filter by Resource Groups such as test and prod  
if ($server.ResourceGroupName -like "**") 
                            {
        $admin = Get-AzSqlInstanceActiveDirectoryAdministrator `
                    -ResourceGroupName $server.ResourceGroupName `
                   -InstanceName $server.FullyQualifiedDomainName `
                    -ErrorAction SilentlyContinue


#Provides the ability to filter by Admin group for the SQL DB instances
     if ($admin -and $admin.ObjectId -ne "5fbc5476-2e5f-45b8-b3a8-2f3092f79d5c") 
                                                                {
            [PSCustomObject]@{
                SubscriptionId = [string]$sub.Id
                ServerName     = [string]$server.FullyQualifiedDomainName
                ResourceGroup  = [string]$server.ResourceGroupName
                AdminObjectId  = [string]$admin.ObjectId
                AdminName      = [string]$admin.DisplayName }
       
       
      #The code below is commented out but can be used to see the resource group name and the sql statements executed
       # Write-Host "$($Server.ResourceGroupName)" 
       #Write-Output "Invoke-Sqlcmd -ServerInstance $($ServerInstancename) -Database 'master' -Query $query -AccessToken $($accessToken)" | Out-File -FilePath "C:\Temp\Output.csv" 
        Write-host "ResourceGroupName: $($ResourceGroupName) SQL-MI ServerName: $($ServerInstancename) "    # | Out-File -FilePath "C:\Temp\Output.csv" 
               
                                                                }
            }
       }
  }  

  