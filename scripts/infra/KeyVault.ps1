function DeployKeyVault()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,
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
    $KeyVaultName,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForDeployment = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForDiskEncryption = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnabledForTemplateDeployment = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableSoftDelete = $false,
    [Parameter(Mandatory = $false)]
    [int]
    $SoftDeleteRetentionInDays = 7,
    [Parameter(Mandatory = $false)]
    [bool]
    $EnableRbacAuthorization = $true,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedIpAddressRangesCsv = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AllowedSubnetResourceIdsCsv = "",
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

  Write-Debug -Debug:$true -Message "Deploy Key Vault"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$KeyVaultName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    tenantId="$TenantId" `
    keyVaultName="$KeyVaultName" `
    enabledForDeployment="$EnabledForDeployment" `
    enabledForDiskEncryption="$EnabledForDiskEncryption" `
    enabledForTemplateDeployment="$EnabledForTemplateDeployment" `
    enableSoftDelete="$EnableSoftDelete" `
    softDeleteRetentionInDays="$SoftDeleteRetentionInDays" `
    enableRbacAuthorization="$EnableRbacAuthorization" `
    publicNetworkAccess="$PublicNetworkAccess" `
    defaultAction="$DefaultAction" `
    allowedIpAddressRanges="$AllowedIpAddressRangesCsv" `
    allowedSubnetResourceIds="$AllowedSubnetResourceIdsCsv" `
    tags=$Tags

  if ($LogAnalyticsWorkspaceName -and $LogAnalyticsWorkspaceResourceId)
  {
    $keyVaultResourceId = "/subscriptions/" + "$SubscriptionId" + "/resourcegroups/" + "$ResourceGroupName" + "/providers/Microsoft.KeyVault/vaults/" + "$KeyVaultName"

    DeployDiagnosticsSetting `
      -SubscriptionID "$SubscriptionId" `
      -Location $configMatrix.Location `
      -ResourceGroupName $ResourceGroupName `
      -TemplateUri ($configAll.TemplateUriPrefix + "diagnostic-settings.json") `
      -ResourceId $keyVaultResourceId `
      -DiagnosticsSettingName ("diag-" + "$LogAnalyticsWorkspaceName") `
      -LogAnalyticsWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
      -SendLogs $true `
      -SendMetrics $true
  }
}
