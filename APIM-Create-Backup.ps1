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
    Connect-AzAccount -ErrorAction Stop
    Log-Message "Successfully logged in to Azure."

    # Create the backup
    Log-Message "Creating backup..."
    $backupName = "$ServiceName-backup-$(Get-Date -Format 'yyyyMMddHHmmss').apimbackup"
    $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -ErrorAction Stop
    $backupBlob = New-AzStorageBlobSASToken -Context $storageContext -Container $BackupContainer -Blob $backupName -Permission rw -ExpiryTime (Get-Date).AddHours(1) -FullUri
    Backup-AzApiManagement -ResourceGroupName $ResourceGroupName -Name $ServiceName -StorageAccountContainerUri $backupBlob.Context.Uri.AbsoluteUri -ErrorAction Stop
    Log-Message "Backup created successfully and stored in container '$BackupContainer'."

} catch {
    Log-Message "An error occurred: $_"
    throw
} finally {
    Log-Message "Backup process completed."
}
