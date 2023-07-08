function Deploy-Network()
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

  foreach ($nsg in $configMatrix.Network.NSGs)
  {
    $nsgName = Get-ResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "nsg" -Sequence ($nsgIndex.ToString().PadLeft(2, "0"))
    $nsgResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/networkSecurityGroups/" + $nsgName

    Write-Debug -Debug:$true -Message ("NSG Resource ID: " + $nsg.ResourceId)

    $nsg.ResourceId = $nsgResourceId

    Write-Debug -Debug:$true -Message ("NSG Resource ID string: " + $nsgResourceId)
    Write-Debug -Debug:$true -Message ("NSG object Resource ID: " + $nsg.ResourceId)

    Deploy-NSG `
      -SubscriptionID "$SubscriptionId" `
      -Location $configMatrix.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($configAll.TemplateUriPrefix + "net.nsg.json") `
      -NSGName $nsgName `
      -Tags $Tags

    if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
    {
      Deploy-DiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
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
      Deploy-NSGRule `
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
    $vnetName = Get-ResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
    $vnetResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName

    Deploy-VNet `
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
      Deploy-DiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
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

      Deploy-Subnet `
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

function Deploy-NSG() {
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

function Deploy-NSGRule() {
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

function Deploy-VNet() {
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

function Deploy-Subnet() {
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

# -------------------------------

function Deploy-PrivateEndpointAndNic() {
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
    $ProtectedWorkloadResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $ProtectedWorkloadSubResource,
    [Parameter(Mandatory = $true)]
    [string]
    $PrivateEndpointName,
    [Parameter(Mandatory = $true)]
    [string]
    $NetworkInterfaceName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetResourceId,
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Private Endpoint and NIC"

  az deployment group create -n "$PrivateEndpointName" --verbose `
    --subscription "$SubscriptionId" `
    -n "$PrivateEndpointName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    protectedWorkloadResourceId="$ProtectedWorkloadResourceId" `
    protectedWorkloadSubResource="$ProtectedWorkloadSubResource" `
    privateEndpointName="$PrivateEndpointName" `
    networkInterfaceName="$NetworkInterfaceName" `
    subnetResourceId="$SubnetResourceId" `
    tags=$Tags
}

function Watch-NicUntilProvisionSuccess()
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
    $NetworkInterfaceName
  )

  Write-Debug -Debug:$true -Message "Watch NIC until ProvisioningStage=Succeeded"

  $limit = (Get-Date).AddMinutes(55)

  $currentState = ""
  $targetState = "Succeeded"

  while ( ($currentState -ne $targetState) -and ((Get-Date) -le $limit) )
  {
    $currentState = "$(az network nic show --subscription $SubscriptionId -g $ResourceGroupName -n $NetworkInterfaceName -o tsv --query 'provisioningState')"

    Write-Debug -Debug:$true -Message "currentState = $currentState"

    if ($currentState -ne $targetState)
    {
      Start-Sleep -s 15
    }
  }

  return $currentState
}

function Deploy-PrivateDnsZones()
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
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Private DNS Zones and VNet links"

  foreach ($privateDnsZone in $ConfigMatrix.Network.PrivateDnsZones)
  {
    $zoneName = $privateDnsZone.Name

    az deployment group create --verbose `
      --subscription "$SubscriptionId" `
      -n "$zoneName" `
      -g "$ResourceGroupName" `
      --template-uri ($ConfigAll.TemplateUriPrefix + "net.private-dns-zone.json") `
      --parameters `
      privateDnsZoneName="$zoneName" `
      tags=$Tags

      $vnetIndex = 1

      foreach ($vnet in $ConfigMatrix.Network.VNets)
      {
        $vnetName = Get-ResourceName -ConfigAll $ConfigAll -ConfigMatrix $ConfigMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
        $vnetResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName

        az deployment group create --verbose `
          --subscription "$SubscriptionId" `
          -n "$zoneName" `
          -g "$ResourceGroupName" `
          --template-uri ($ConfigAll.TemplateUriPrefix + "net.private-dns-zone.vnet-link.json") `
          --parameters `
          privateDnsZoneName="$zoneName" `
          vnetResourceId="$vnetResourceId" `
          enableAutoRegistration=$false `
          tags=$Tags
  
        $vnetIndex++
      }
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
    $vnetName = Get-ResourceName -ConfigAll $configAll -ConfigMatrix $configMatrix -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
    $vnetResourceId = Get-ResourceId -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -ResourceProviderName "Microsoft.Network" -ResourceTypeName "virtualNetworks" -ResourceName $vnetName

    foreach ($subnet in $vnet.Subnets)
    {
      $subnetResourceId = Get-ChildResourceId -ParentResourceId $vnetResourceId -ChildResourceTypeName "subnets" -ChildResourceName $subnet.Name

      $result.Add($subnetResourceId) | Out-Null
    }
  }

  return $result
}
