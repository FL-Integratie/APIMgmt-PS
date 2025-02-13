<#
.SYNOPSIS
    This script regenerates the primary and secondary keys for API Management subscriptions.

.DESCRIPTION
    The script connects to Azure using a system-assigned managed identity, retrieves API Management services, and regenerates the primary and secondary keys for subscriptions with a specific ProductID.

.PARAMETER apimName
    The name of the API Management service.

.PARAMETER apimResourceGroup
    The name of the resource group containing the API Management service.

.PARAMETER masterSubscriptionId
    The subscription ID for the API Management subscriptions.

.EXAMPLE
    .\Regenerate-APIMKeys.ps1 -apimName "your-apim-name" -apimResourceGroup "your-resource-group" -masterSubscriptionId "your-master-subscription-id"
#>
param(
    [string]$apimName,
    [string]$apimResourceGroup,
    [string]$masterSubscriptionId
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
    Log-Message "Disabling AzContext autosave..."
    Disable-AzContextAutosave -Scope Process

    Log-Message "Connecting to Azure using system-assigned managed identity..."
    $AzureContext = (Connect-AzAccount -Identity).context

    Log-Message "Setting and storing Azure context..."
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext  

    Log-Message "Retrieving API Management services information..."
    $ApiManagements = Get-AzApiManagement -ResourceGroupName $apimResourceGroup -Name $apimName

    foreach ($ApiManagement in $ApiManagements) {
        Log-Message "Setting up Azure API Management context for $($ApiManagement.Name)..."
        $ApiManagementContext = New-AzApiManagementContext -ResourceId $ApiManagement.Id

        Log-Message "Retrieving API Management subscriptions for ProductID $masterSubscriptionId..."
        $ApiManagementSubscriptions = Get-AzApiManagementSubscription -Context $ApiManagementContext -SubscriptionId $masterSubscriptionId

        foreach ($ApiManagementSubscription in $ApiManagementSubscriptions) {
            Log-Message "Regenerating keys for subscription $($ApiManagementSubscription.SubscriptionId)..."
            $PrimaryKey = (New-Guid) -replace '-',''
            $SecondaryKey = (New-Guid) -replace '-',''

            Log-Message "Setting new keys for subscription $($ApiManagementSubscription.SubscriptionId)..."
            $newvalue = Set-AzApiManagementSubscription -Context $ApiManagementContext -SubscriptionId $ApiManagementSubscription.SubscriptionId -PrimaryKey $PrimaryKey -SecondaryKey $SecondaryKey -State Active
        }
    }

    Log-Message "Key regeneration process completed successfully."
} catch {
    Log-Message "An error occurred: $_" "ERROR"
    throw
}
