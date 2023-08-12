function Deploy-UAI()
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
    PS> . ./Deploy-UAI.ps1
    PS> Deploy-UAI -SubscriptionID "MyAzureSubscriptionId" -Location "westus" -ResourceGroupName "MyResourceGroupName" -TemplateUri "MyARMTemplateURI" -TenantId "MyTenantId" -UAIName "MyUAIName" -Tags "MyTags"
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

  Write-Debug -Debug:$true -Message "Deploy UAI $UAIName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$UAIName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    tenantId="$TenantId" `
    identityName="$UAIName" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Deploy-RoleAssignmentSub()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $RoleDefinitionId,
    [Parameter(Mandatory = $true)]
    [string]
    $PrincipalId,
    [Parameter(Mandatory = $false)]
    [string]
    $PrincipalType = "ServicePrincipal"
  )

  $deploymentName = "rbac-" + $Location + "-" + (Get-Timestamp -MakeStringSafe $true)

  Write-Debug -Debug:$true -Message "Deploy Sub Role Assignment: RoleDefinitionId=$RoleDefinitionId, PrincipalId=$PrincipalId, PrincipalType=$PrincipalType"

  $output = az deployment sub create --verbose `
    -n "$deploymentName" `
    --location="$Location" `
    --template-uri "$TemplateUri" `
    --parameters `
    roleDefinitionId="$RoleDefinitionId" `
    principalId="$PrincipalId" `
    principalType="$PrincipalType" `
    | ConvertFrom-Json

  return $output
}
