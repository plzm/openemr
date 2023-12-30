function Deploy-Network()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigConstants,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigScaleUnitTemplate,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigScaleUnit,
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

  # Ingest both template and scale unit NSGs into a single arraylist
  $nsgs = [System.Collections.ArrayList]@()
  if ($ConfigScaleUnitTemplate.Network.NSGs.Count -gt 0) { $nsgs.AddRange($ConfigScaleUnitTemplate.Network.NSGs) }
  if ($ConfigScaleUnit.Network.NSGs.Count -gt 0) { $nsgs.AddRange($ConfigScaleUnit.Network.NSGs) }

  foreach ($nsg in $nsgs)
  {
    $nsgName = plzm.Azure\Get-ResourceName -ConfigConstants $ConfigConstants -ConfigScaleUnit $ConfigScaleUnit -Prefix "nsg" -Sequence ($nsgIndex.ToString().PadLeft(2, "0"))
    $nsgResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/networkSecurityGroups/" + $nsgName
    $nsg.ResourceId = $nsgResourceId

    Write-Debug -Debug:$true -Message ("NSG Resource ID string: " + $nsgResourceId)
    Write-Debug -Debug:$true -Message ("NSG object Resource ID: " + $nsg.ResourceId)

    $output = plzm.Azure\Deploy-NetworkSecurityGroup `
      -SubscriptionID "$SubscriptionId" `
      -Location $ConfigScaleUnit.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($ConfigConstants.TemplateUriPrefix + "net.nsg.json") `
      -NSGName $nsgName `
      -Tags $Tags

    Write-Debug -Debug:$true -Message "$output"

    if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
    {
      $output = plzm.Azure\Deploy-DiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($ConfigConstants.TemplateUriPrefix + "diagnostic-settings.json") `
        -ResourceId $nsgResourceId `
        -DiagnosticsSettingName ("diag-" + "$LogAnalyticsWorkspaceName") `
        -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
        -SendLogs $true `
        -SendMetrics $false
      
      Write-Debug -Debug:$true -Message "$output"
    }

    foreach ($nsgRule in $nsg.Rules)
    {
      $output = plzm.Azure\Deploy-NetworkSecurityGroupRule `
        -SubscriptionID "$SubscriptionId" `
        -Location $ConfigScaleUnit.Location `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($ConfigConstants.TemplateUriPrefix + "net.nsg.rule.json") `
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

      Write-Debug -Debug:$true -Message "$output"
    }

    $nsgIndex++
  }


  $vnetIndex = 1

  foreach ($vnet in $ConfigScaleUnit.Network.VNets)
  {
    $vnetName = plzm.Azure\Get-ResourceName -ConfigConstants $ConfigConstants -ConfigScaleUnit $ConfigScaleUnit -Prefix "vnt" -Sequence ($vnetIndex.ToString().PadLeft(2, "0"))
    $vnetResourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName

    $output = plzm.Azure\Deploy-NetworkVNet `
      -SubscriptionID "$SubscriptionId" `
      -Location $ConfigScaleUnit.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($ConfigConstants.TemplateUriPrefix + "net.vnet.json") `
      -VNetName $vnetName `
      -VNetPrefix $vnet.AddressSpace `
      -EnableDdosProtection $vnet.EnableDdosProtection `
      -Tags $Tags

    Write-Debug -Debug:$true -Message "$output"

    if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
    {
      $output = plzm.Azure\Deploy-DiagnosticsSetting `
        -SubscriptionID "$SubscriptionId" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($ConfigConstants.TemplateUriPrefix + "diagnostic-settings.json") `
        -ResourceId $vnetResourceId `
        -DiagnosticsSettingName ("diag-" + "$LogAnalyticsWorkspaceName") `
        -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
        -SendLogs $true `
        -SendMetrics $true

      Write-Debug -Debug:$true -Message "$output"
    }

    foreach ($subnet in $vnet.Subnets)
    {
      Write-Debug -Debug:$true -Message $subnet.Name

      $nsg = $nsgs | Where-Object {$_.NsgId -eq $subnet.NsgId}
      Write-Debug -Debug:$true -Message ("NSG Resource ID: " + $nsg.ResourceId)

      $output = plzm.Azure\Deploy-NetworkSubnet `
        -SubscriptionID "$SubscriptionId" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateUri ($ConfigConstants.TemplateUriPrefix + "net.vnet.subnet.json") `
        -VNetName $vnetName `
        -SubnetName $subnet.Name `
        -SubnetPrefix $subnet.AddressSpace `
        -NsgResourceId $nsg.ResourceId `
        -RouteTableResourceId "" `
        -DelegationService $subnet.Delegation `
        -ServiceEndpoints $subnet.ServiceEndpoints

      Write-Debug -Debug:$true -Message "$output"
    }

    $vnetIndex++
  }
}
