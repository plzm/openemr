function DeployRG()
{
  <#
    .SYNOPSIS
    This command deploys an Azure Resource Group.
    .DESCRIPTION
    This command deploys an Azure Resource Group.
    .PARAMETER SubscriptionId
    The Azure subscription ID
    .PARAMETER Location
    The Azure region
    .PARAMETER ResourceGroupName
    The Resource Group name
    .PARAMETER Tags
    Tags
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> . ./DeployRG.ps1
    PS> DeployRG -SubscriptionID "MyAzureSubscriptionId" Location "westus" -ResourceGroupName "MyResourceGroupName" -Tags "MyTags"
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
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  az group create --subscription "$SubscriptionId" -l "$Location" -n "$ResourceGroupName" --tags "$Tags" --verbose
}
