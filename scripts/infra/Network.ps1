function DeployNetwork()
{
  [CmdletBinding()]
  param
  (
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
    $LogAnalyticsWorkspaceName = "",
    [Parameter(Mandatory = $false)]
    [string]
    $LogAnalyticsWorkspaceResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Network"

  $nsgIndex = 1

  foreach ($nsg in $configMatrix.Network.NSGs) {
    $nsgName = GetResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "nsg" -Sequence ($nsgIndex.ToString().PadLeft(2, "0"))
    $nsgResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/networkSecurityGroups/" + $nsgName

    Write-Debug -Debug:$true -Message ("NSG Resource ID: " + $nsg.ResourceId)

    $nsg.ResourceId = $nsgResourceId

    Write-Debug -Debug:$true -Message ("NSG Resource ID string: " + $nsgResourceId)
    Write-Debug -Debug:$true -Message ("NSG object Resource ID: " + $nsg.ResourceId)

    DeployNSG `
      -SubscriptionID "$SubscriptionId" `
      -Location $configMatrix.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($configAll.TemplateUriPrefix + "net.nsg.json") `
      -NSGName $nsgName `
      -Tags $Tags

    if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
    {
      DeployDiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
        -Location $configMatrix.Location `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($configAll.TemplateUriPrefix + "diagnostic-settings.json") `
        -ResourceId $nsgResourceId `
        -DiagnosticsSettingName ("diag-" + "$LogAnalyticsWorkspaceName") `
        -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
        -SendLogs $true `
        -SendMetrics $false
    }

    foreach ($nsgRule in $nsg.Rules)
    {
      DeployNSGRule `
      -SubscriptionID "$SubscriptionId" `
      -Location $configMatrix.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($configAll.TemplateUriPrefix + "net.nsg.rule.json") `
      -NSGName $nsgName `
      -NSGRuleName $nsgRule.Name `
      -Description $nsgRule.Description `
      -Priority $nsgRule.Priority `
      -Direction $nsgRule.Direction `
      -Access $nsgRule.Access `
      -Protocol $nsgRule.Protocol `
      -SourceAddressPrefix $nsgRule.SourceAddressPrefix `
      -SourcePortRange $nsgRule.SourcePortRange `
      -DestinationAddressPrefix $nsgRule.DestinationAddressPrefix `
      -DestinationPortRange $nsgRule.DestinationPortRange
    }

    $nsgIndex++
  }


  $vnetIndex = 1

  foreach ($vnet in $configMatrix.Network.VNets)
  {
    $vnetName = GetResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
    $vnetResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName

    DeployVNet `
      -SubscriptionID "$SubscriptionId" `
      -Location $configMatrix.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($configAll.TemplateUriPrefix + "net.vnet.json") `
      -VNetName $vnetName `
      -VNetPrefix $vnet.AddressSpace `
      -EnableDdosProtection $vnet.EnableDdosProtection `
      -Tags $Tags

    if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
    {
      DeployDiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
        -Location $configMatrix.Location `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($configAll.TemplateUriPrefix + "diagnostic-settings.json") `
        -ResourceId $vnetResourceId `
        -DiagnosticsSettingName ("diag-" + "$LogAnalyticsWorkspaceName") `
        -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
        -SendLogs $true `
        -SendMetrics $true
    }
  
    foreach ($subnet in $vnet.Subnets)
    {
      Write-Debug -Debug:$true -Message $subnet.Name

      $nsg = $configMatrix.Network.NSGs | Where-Object {$_.NsgId -eq $subnet.NsgId}
      Write-Debug -Debug:$true -Message ("NSG Resource ID: " + $nsg.ResourceId)

      DeploySubnet `
        -SubscriptionID "$SubscriptionId" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($configAll.TemplateUriPrefix + "net.vnet.subnet.json") `
        -VNetName $vnetName `
        -SubnetName $subnet.Name `
        -SubnetPrefix $subnet.AddressSpace `
        -NsgResourceId $nsg.ResourceId `
        -RouteTableResourceId "" `
        -DelegationService $subnet.Delegation `
        -ServiceEndpoints $subnet.ServiceEndpoints
    }

    $vnetIndex++
  }
}

function Get-SubnetResourceIds()
{
  [CmdletBinding()]
  param
  (
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
    $ResourceGroupName
  )

  Write-Debug -Debug:$true -Message "Get Subnet Resource IDs"

  $result = [System.Collections.ArrayList]@()

  $vnetIndex = 1

  foreach ($vnet in $configMatrix.Network.VNets)
  {
    $vnetName = GetResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
    $vnetResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName

    foreach ($subnet in $vnet.Subnets)
    {
      $subnetResourceId = $vnetResourceId + "/subnets/" + $subnet.Name

      $result.Add($subnetResourceId) | Out-Null
    }
  }

  return $result
}

function DeployNSG() {
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
    $NSGName,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy NSG"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$NSGName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    nsgName="$NSGName" `
    tags=$Tags
}

function DeployNSGRule() {
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
    $NSGName,
    [Parameter(Mandatory = $true)]
    [string]
    $NSGRuleName,
    [Parameter(Mandatory = $false)]
    [string]
    $Description = "",
    [Parameter(Mandatory = $false)]
    [int]
    $Priority = 200,
    [Parameter(Mandatory = $false)]
    [string]
    $Direction = "Inbound",
    [Parameter(Mandatory = $false)]
    [string]
    $Access = "Deny",
    [Parameter(Mandatory = $false)]
    [string]
    $Protocol = "Tcp",
    [Parameter(Mandatory = $true)]
    [string]
    $SourceAddressPrefix,
    [Parameter(Mandatory = $false)]
    [string]
    $SourcePortRange = "*",
    [Parameter(Mandatory = $true)]
    [string]
    $DestinationAddressPrefix,
    [Parameter(Mandatory = $true)]
    [string]
    $DestinationPortRange
  )

  Write-Debug -Debug:$true -Message "Deploy NSG Rule"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$NSGRuleName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    nsgName="$NSGName" `
    nsgRuleName="$NSGRuleName" `
    description="$Description" `
    priority="$Priority" `
    direction="$Direction" `
    access="$Access" `
    protocol="$Protocol" `
    sourceAddressPrefix="$SourceAddressPrefix" `
    sourcePortRange="$SourcePortRange" `
    destinationAddressPrefix="$DestinationAddressPrefix" `
    destinationPortRange="$DestinationPortRange"
}

function DeployVNet() {
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

function DeploySubnet() {
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
    $DelegationService = "",
    [Parameter(Mandatory = $false)]
    [string]
    $ServiceEndpoints = ""
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
    delegationService="$DelegationService" `
    serviceEndpoints="$ServiceEndpoints"
}
