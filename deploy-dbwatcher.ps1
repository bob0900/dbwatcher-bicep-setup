#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys the Database Watcher infrastructure using Bicep templates.

.DESCRIPTION
    This script deploys a Database Watcher resource with SQL targets and Kusto cluster
    configuration using Azure Bicep templates.

.PARAMETER ResourceGroupName
    The name of the resource group where resources will be deployed.

.PARAMETER TemplateFile
    Path to the Bicep template file. Defaults to 'dbwatcher.bicep'.

.PARAMETER ParameterFile
    Path to the parameters JSON file. Defaults to 'dbwatcher.parameters.json'.

.PARAMETER Location
    Azure region for the resource group if it needs to be created. Defaults to 'UK South'.

.PARAMETER WhatIf
    Shows what would happen if the script runs without actually deploying.

.EXAMPLE
    .\deploy-dbwatcher.ps1 -ResourceGroupName "rg-db-benchmark"

.EXAMPLE
    .\deploy-dbwatcher.ps1 -ResourceGroupName "rg-db-benchmark" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "dbwatcher.bicep",

    [Parameter(Mandatory = $false)]
    [string]$ParameterFile = "dbwatcher.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]$Location = "UK South"
)

# ============================================================================
# Functions
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            return $false
        }
        Write-Log "Connected to Azure subscription: $($context.Subscription.Name)" -Level Success
        return $true
    }
    catch {
        return $false
    }
}

function Test-BicepFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Log "Bicep template file not found: $Path" -Level Error
        return $false
    }
    Write-Log "Found Bicep template: $Path" -Level Success
    return $true
}

function Test-ParameterFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Log "Parameter file not found: $Path" -Level Error
        return $false
    }
    
    try {
        $params = Get-Content $Path -Raw | ConvertFrom-Json
        Write-Log "Found parameter file: $Path" -Level Success
        return $true
    }
    catch {
        Write-Log "Invalid parameter file format: $_" -Level Error
        return $false
    }
}

function Ensure-ResourceGroup {
    param(
        [string]$Name,
        [string]$Location
    )
    
    $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
    
    if ($null -eq $rg) {
        Write-Log "Resource group '$Name' does not exist. Creating..." -Level Info
        
        if ($PSCmdlet.ShouldProcess($Name, "Create resource group")) {
            $rg = New-AzResourceGroup -Name $Name -Location $Location
            Write-Log "Resource group '$Name' created successfully" -Level Success
        }
    }
    else {
        Write-Log "Resource group '$Name' already exists" -Level Info
    }
    
    return $rg
}

# ============================================================================
# Main Script
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$WhatIf = $false

# Change to script directory
Set-Location $scriptPath

Write-Log "========================================" -Level Info
Write-Log "Database Watcher Deployment Script" -Level Info
Write-Log "========================================" -Level Info
Write-Log ""

# Step 1: Check Azure connection
Write-Log "Checking Azure connection..." -Level Info
if (-not (Test-AzureConnection)) {
    Write-Log "Not connected to Azure. Please login..." -Level Warning
    try {
        Connect-AzAccount
        if (-not (Test-AzureConnection)) {
            throw "Failed to connect to Azure"
        }
    }
    catch {
        Write-Log "Failed to connect to Azure: $_" -Level Error
        exit 1
    }
}
Write-Log ""

# Step 2: Validate files
Write-Log "Validating deployment files..." -Level Info
$templatePath = Join-Path $scriptPath $TemplateFile
$parameterPath = Join-Path $scriptPath $ParameterFile

if (-not (Test-BicepFile $templatePath)) {
    exit 1
}

if (-not (Test-ParameterFile $parameterPath)) {
    exit 1
}
Write-Log ""

# Step 3: Ensure resource group exists
Write-Log "Checking resource group..." -Level Info
try {
    $rg = Ensure-ResourceGroup -Name $ResourceGroupName -Location $Location
    if ($null -eq $rg -and -not $WhatIf) {
        throw "Failed to create or find resource group"
    }
}
catch {
    Write-Log "Error with resource group: $_" -Level Error
    exit 1
}
Write-Log ""

# Step 4: Validate deployment (What-If analysis)
Write-Log "Running deployment validation (What-If)..." -Level Info
try {
    $whatIfParams = @{
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $templatePath
        TemplateParameterFile = $parameterPath
        Mode                  = 'Incremental'
    }

    $whatIfResult = Get-AzResourceGroupDeploymentWhatIfResult @whatIfParams
    
    Write-Log "What-If Analysis Results:" -Level Info
    Write-Host $whatIfResult
    Write-Log ""
}
catch {
    Write-Log "Validation failed: $_" -Level Error
    Write-Log "Please check your template and parameters" -Level Warning
    exit 1
}

# Step 5: Deploy if not in WhatIf mode
if ($WhatIf) {
    Write-Log "WhatIf mode - Skipping actual deployment" -Level Warning
    Write-Log "Review the What-If results above to see what would be deployed" -Level Info
    exit 0
}

# Confirm deployment
Write-Log "Ready to deploy Database Watcher" -Level Warning
$confirmation = Read-Host "Do you want to proceed with the deployment? (yes/no)"

if ($confirmation -ne 'yes') {
    Write-Log "Deployment cancelled by user" -Level Warning
    exit 0
}

Write-Log "Starting deployment..." -Level Info
$deploymentName = "dbwatcher-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    $deploymentParams = @{
        Name                  = $deploymentName
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $templatePath
        TemplateParameterFile = $parameterPath
        Mode                  = 'Incremental'
        Verbose               = $true
    }
    
    $deployment = New-AzResourceGroupDeployment @deploymentParams
    
    Write-Log ""
    Write-Log "========================================" -Level Success
    Write-Log "Deployment completed successfully!" -Level Success
    Write-Log "========================================" -Level Success
    Write-Log ""
    
    # Display outputs
    if ($deployment.Outputs) {
        Write-Log "Deployment Outputs:" -Level Info
        foreach ($output in $deployment.Outputs.GetEnumerator()) {
            Write-Host "  $($output.Key): " -NoNewline -ForegroundColor Cyan
            Write-Host $output.Value.Value -ForegroundColor White
        }
        Write-Log ""
    }
    
    Write-Log "Deployment Name: $deploymentName" -Level Info
    Write-Log "Resource Group: $ResourceGroupName" -Level Info
    Write-Log "Provisioning State: $($deployment.ProvisioningState)" -Level Success
    
}
catch {
    Write-Log ""
    Write-Log "========================================" -Level Error
    Write-Log "Deployment failed!" -Level Error
    Write-Log "========================================" -Level Error
    Write-Log "Error: $_" -Level Error
    Write-Log ""
    Write-Log "Deployment Name: $deploymentName" -Level Info
    Write-Log "Check Azure Portal for detailed error information" -Level Warning
    exit 1
}

# Step 6: Post-deployment instructions
Write-Log ""
Write-Log "========================================" -Level Info
Write-Log "Post-Deployment Steps" -Level Info
Write-Log "========================================" -Level Info
Write-Log "1. Grant the Database Watcher managed identity permissions:" -Level Info
Write-Log "   - Key Vault: 'Key Vault Secrets User' or 'Get' permission on secrets" -Level Info
Write-Log "   - Kusto: 'Database Ingestor' and 'Database Viewer' roles" -Level Info
Write-Log "   - SQL Databases: 'db_datareader' or required permissions" -Level Info
Write-Log ""
Write-Log "2. If using private links, approve the private endpoint connections in:" -Level Info
Write-Log "   - SQL Server resource" -Level Info
Write-Log "   - Kusto cluster resource" -Level Info
Write-Log ""
Write-Log "3. Monitor the Database Watcher in Azure Portal or Kusto Explorer" -Level Info
Write-Log ""
