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
    .PARAMETER TemplateUri
    The ARM template URI
    .PARAMETER TenantId
    The Azure tenant ID
    .PARAMETER UAIName
    The User Assigned Identity name
    .PARAMETER Tags
    Tags
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> . ./DeployUAI.ps1
    PS> DeployUAI -SubscriptionID "MyAzureSubscriptionId" -Location "westus" -ResourceGroupName "MyResourceGroupName" -TemplateUri "MyARMTemplateURI" -TenantId "MyTenantId" -UAIName "MyUAIName" -Tags "MyTags"
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
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,
    [Parameter(Mandatory = $true)]
    [string]
    $UAIName,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$UAIName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    tenantId="$TenantId" `
    identityName="$UAIName" `
    tags=$Tags
}