param (
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]
    $bastionName,

    [Parameter(Mandatory=$true)]
    [string]
    $userAssignedManagedIdentity
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup `
    -Name $userAssignedManagedIdentity `
    -DefaultProfile $AzureContext
$AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription `
    -DefaultProfile $AzureContext

Remove-AzBastion -Name $bastionName -ResourceGroupName $resourceGroup -Force
