<#
.SYNOPSIS
    This script uses the Azure CLI to extract an access token and call the Azure Management API to back up an API Management service.

.DESCRIPTION
    The script logs in using a system-assigned managed identity, retrieves an access token, and uses it to call the Azure Management API for backing up an API Management service.

.PARAMETER subscriptionId
    The subscription ID where the API Management service is located.

.PARAMETER ResourceGroupName
    The name of the resource group containing the API Management service.

.PARAMETER ApiManagementName
    The name of the API Management service to back up.

.PARAMETER StorageAccountName
    The name of the storage account where the backup will be stored.

.PARAMETER ContainerName
    The name of the container within the storage account where the backup will be stored.

.EXAMPLE
    .\Backup-APIM.ps1 -subscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -ApiManagementName "your-apim-name" -StorageAccountName "your-storage-account" -ContainerName "your-container-name"
#>

param(
    [string]$subscriptionId,
    [string]$ResourceGroupName,
    [string]$ApiManagementName,
    [string]$StorageAccountName,
    [string]$ContainerName
)

function Log-Message {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp [$level] $message"
}

try {
    Log-Message "Logging in using system-assigned managed identity..."
    az login --identity

    Log-Message "Retrieving access token..."
    $token = az account get-access-token --subscription $subscriptionId --query accessToken --output tsv

    #construct API call for the azure management API
    $backupName = "backup-" + $ApiManagementName + "-" + $(Get-Date -Format 'yyyyMMddHHmmss')
    $accessType = "SystemAssignedManagedIdentity"
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApiManagementName/backup?api-version=2024-05-01"
    $body = @{
        storageAccount = $StorageAccountName
        containerName = $ContainerName
        backupName = $backupName
        accessType = $accessType
    } | ConvertTo-Json

    Log-Message "Initiating backup..."
    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json" -Body $body

    Log-Message "Backup initiated successfully."
} catch {
    Log-Message "An error occurred: $_" "ERROR"
    throw
}
