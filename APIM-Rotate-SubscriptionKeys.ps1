<#
.SYNOPSIS
    Rotates subscription keys for Azure API Management.

.DESCRIPTION
    This script rotates the primary and secondary subscription keys for a specified API Management service and subscription.

.PARAMETER ResourceGroupName
    The name of the resource group containing the API Management service.

.PARAMETER ServiceName
    The name of the API Management service.

.PARAMETER SubscriptionId
    The ID of the subscription whose keys are to be rotated.

.EXAMPLE
    .\APIM-Rotate-SubscriptionKeys.ps1 -ResourceGroupName "MyResourceGroup" -ServiceName "MyAPIMService" -SubscriptionId "12345678-1234-1234-1234-123456789012"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$ServiceName,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

# Import the necessary module
Import-Module Az.ApiManagement

# Function to log messages
function Log-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp [$Level] $Message"
}

# Error handling
try {
    Log-Message "Starting key rotation for subscription ID: $SubscriptionId"

    # Rotate primary key
    Log-Message "Rotating primary key..."
    $primaryKey = New-AzApiManagementSubscriptionKey -ResourceGroupName $ResourceGroupName -ServiceName $ServiceName -SubscriptionId $SubscriptionId -KeyType Primary
    Log-Message "Primary key rotated successfully."

    # Rotate secondary key
    Log-Message "Rotating secondary key..."
    $secondaryKey = New-AzApiManagementSubscriptionKey -ResourceGroupName $ResourceGroupName -ServiceName $ServiceName -SubscriptionId $SubscriptionId -KeyType Secondary
    Log-Message "Secondary key rotated successfully."

    Log-Message "Key rotation completed successfully for subscription ID: $SubscriptionId"
} catch {
    Log-Message "An error occurred: $_" "ERROR"
    throw
}
