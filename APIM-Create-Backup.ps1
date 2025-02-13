<#
.SYNOPSIS
    Creates a backup of an Azure API Management (APIM) instance.

.DESCRIPTION
    This script creates a backup of an Azure API Management (APIM) instance and stores it in an Azure Storage account.

.PARAMETER ResourceGroupName
    The name of the resource group containing the APIM instance.

.PARAMETER ServiceName
    The name of the APIM instance.

.PARAMETER StorageAccountName
    The name of the Azure Storage account where the backup will be stored.

.PARAMETER StorageAccountKey
    The key for the Azure Storage account.

.PARAMETER BackupContainer
    The name of the container in the Azure Storage account where the backup will be stored.

.EXAMPLE
    .\APIM-Create-Backup.ps1 -ResourceGroupName "MyResourceGroup" -ServiceName "MyAPIMService" -StorageAccountName "MyStorageAccount" -StorageAccountKey "MyStorageKey" -BackupContainer "backups"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ServiceName,

    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey,

    [Parameter(Mandatory=$true)]
    [string]$BackupContainer
)

# Enable error handling
$ErrorActionPreference = "Stop"

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp - $Message"
}

try {
    Log-Message "Starting backup process for APIM instance '$ServiceName' in resource group '$ResourceGroupName'."

    # Login to Azure
    Log-Message "Logging in to Azure..."
    az login --identity   
    Log-Message "Successfully logged in to Azure."

    # Create the backup
    Log-Message "Creating backup..."

    #get access token using azure cli
    $token = az account get-access-token --subscription $subscriptionId --query accessToken --output tsv
          
    $backupName = "backup-" + $apiManagementName + "-" + $(Get-Date -Format 'yyyyMMddHHmmss')
    $accessType="SystemAssignedManagedIdentity"
    
    #construct API call for the azure management API
    $uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.ApiManagement/service/"+ $ApiManagementName + "/backup?api-version=2024-05-01"
    $body = @{
        storageAccount = $StorageAccountName          
        containerName = $ContainerName
        backupName = $BackupName
        accessType = $accessType
    } | ConvertTo-Json
    
    #call azure management API with access token
    Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $token"} -ContentType "application/json" -Body $body
    
    Log-Message "Backup created successfully and stored in container '$BackupContainer'."

} catch {
    Log-Message "An error occurred: $_"
    throw
} finally {
    Log-Message "Backup process completed."
}
