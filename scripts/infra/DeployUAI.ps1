function DeployUAI()
{
  <#
    .SYNOPSIS
    This command deploys an Azure User Assigned Identity.
    .DESCRIPTION
    This command deploys an Azure User Assigned Identity.
    .PARAMETER SubscriptionId
    The Azure subscription ID
    .PARAMETER Location
    The Azure region
    .PARAMETER ResourceGroupName
    The Resource Group name
    .PARAMETER TenantId
    The Azure tenant ID
    .PARAMETER UAIName
    The User Assigned Identity name
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> . ./DeployUAI.ps1
    PS> DeployUAI -SubscriptionID "MyAzureSubscriptionId" Location "westus" -ResourceGroupName "MyResourceGroupName" -TenantId "MyTenantId" -UAIName "MyUAIName"
    .LINK
    None
  #>

  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,
    [Parameter(Mandatory = $true)]
    [string]
    $UAIName
  )

  az deployment group create `
    --subscription "$SubscriptionId" `
    -n "UAI-$Location" `
    -l "$Location" `
    -g "$ResourceGroupName" `
    --template-uri "" `
    --parameters `
    location="$Location" `
    tenantId="$TenantId" `
    identityName="$UAIName"
}
