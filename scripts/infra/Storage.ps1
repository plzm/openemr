function Deploy-StorageAccount()
{
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
    $StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $SkuName,
    [Parameter(Mandatory = $false)]
    [string]
    $SkuTier = "Standard",
    [Parameter(Mandatory = $false)]
    [bool]
    $HierarchicalEnabled = $false,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedSubnetResourceIdsCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedIpAddressRangesCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Storage Account"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$StorageAccountName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    storageAccountName="$StorageAccountName" `
    skuName=$SkuName `
    skuTier=$SkuTier `
    hierarchicalEnabled="$HierarchicalEnabled" `
    publicNetworkAccess="$PublicNetworkAccess" `
    allowedSubnetResourceIds="$AllowedSubnetResourceIdsCsv" `
    allowedIpAddressRanges="$AllowedIpAddressRangesCsv" `
    defaultAccessAction=$DefaultAction `
    tags=$Tags
}
