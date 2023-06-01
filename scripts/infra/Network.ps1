function DeployNetwork()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Environment,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigAll,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMatrix,
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Network"

  $vnetIndex = 1

  foreach ($vnet in $configMatrix.Network.VNets)
  {
    $vnetName = GetResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))

    DeployVNet `
    -SubscriptionID "$SubscriptionId" `
    -Location $configMatrix.Location `
    -ResourceGroupName $rgName `
    -TemplateUri ($configAll.TemplateUriPrefix + "net.vnet.json") `
    -VNetName $vnetName `
    -VNetPrefix $configMatrix.Network.AddressSpace `
    -EnableDdosProtection $false `
    -Tags $Tags

    foreach ($subnet in $vnet.Subnets)
    {
      DeploySubnet `
      -SubscriptionID "$SubscriptionId" `
      -ResourceGroupName $rgName `
      -TemplateUri ($configAll.TemplateUriPrefix + "net.vnet.subnet.json") `
      -VNetName $vnetName `
      -SubnetName $subnet.Name `
      -SubnetPrefix $subnet.AddressSpace `
      -NsgResourceId "" `
      -RouteTableResourceId "" `
      -DelegationService $subnet.Delegation
    }

    $vnetIndex++
  }

}

function DeployVNet()
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
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetPrefix,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableDdosProtection = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableVmProtection = $false,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy VNet"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$VNetName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    vnetName="$VNetName" `
    vnetPrefix="$VNetPrefix" `
    enableDdosProtection="$EnableDdosProtection" `
    enableVmProtection="$EnableVmProtection" `
    tags=$Tags
}

function DeploySubnet()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateUri,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetPrefix,
    [Parameter(Mandatory = $false)]
    [string]
    $NsgResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $RouteTableResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DelegationService = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Subnet"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$SubnetName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    vnetName="$VNetName" `
    subnetName="$SubnetName" `
    subnetPrefix="$SubnetPrefix" `
    nsgResourceId="$NsgResourceId" `
    routeTableResourceId="$RouteTableResourceId" `
    delegationService="$DelegationService"
}
