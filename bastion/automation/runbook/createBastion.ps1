param (
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroup,

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

# Download template.json
Invoke-WebRequest "https://raw.githubusercontent.com/YujiAzama/ARMTest/main/bastion/template.json" -OutFile "C:\Temp\template.json"

# Deploy the bastion
New-AzResourceGroupDeployment `
    -Name testDeploy `
    -ResourceGroupName $resourceGroup `
    -TemplateFile C:\Temp\template.json
