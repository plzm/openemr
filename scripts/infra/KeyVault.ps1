function Deploy-KeyVault()
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
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Key Vault $KeyVaultName"

  $output = az deployment group create --verbose `
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
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}

function Get-KeyVaultSecretName()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]
    $VarName
  )
  # Fix KV secret name; only - and alphanumeric allowed
  $secretName = $VarName.Replace(":", "-").Replace("_", "-")

  return $secretName
}

function Set-KeyVaultSecret()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]
    $KeyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretName,
    [Parameter(Mandatory=$true)]
    [string]
    $SecretValue
  )
  $secretNameSafe = Get-KeyVaultSecretName -VarName "$SecretName"
  #$secretValue = ConvertTo-SecureString "$RawSecretValue" -AsPlainText -Force

  az keyvault secret set `
    --vault-name "$KeyVaultName" `
    --name "$secretNameSafe" `
    --value "$SecretValue" `
    --output none
}

function Set-KeyVaultNetworkSettings()
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
    $KeyVaultName,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $DefaultAction = "Deny"
  )

  Write-Debug -Debug:$true -Message "Set Key Vault $KeyVaultName Network Settings"

  $output = az keyvault update `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --public-network-access "$PublicNetworkAccess" `
    --default-action "$DefaultAction" `
    --bypass AzureServices `
    | ConvertFrom-Json

  return $output
}

function New-KeyVaultNetworkRuleForIpAddressOrRange()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $IpAddressOrRange
  )

  Write-Debug -Debug:$true -Message "Add Key Vault $KeyVaultName Network Rule for $IpAddressOrRange"

  $output = az keyvault network-rule add `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --ip-address "$IpAddressOrRange" `
    | ConvertFrom-Json

  return $output
}

function Remove-KeyVaultNetworkRuleForIpAddressOrRange()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $Cidr
  )

  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Network Rule for $Cidr"

  $output = az keyvault network-rule remove `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --ip-address "$Cidr" `
    | ConvertFrom-Json

  return $output
}

function New-KeyVaultNetworkRuleForVnetSubnet()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetName
  )

  Write-Debug -Debug:$true -Message "Add Key Vault $KeyVaultName Network Rule for $VNetName and $SubnetName"

  $output = az keyvault network-rule add `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --vnet-name "$VNetName" `
    --subnet "$SubnetName" `
    | ConvertFrom-Json

  return $output
}

function Remove-KeyVaultNetworkRuleForVnetSubnet()
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
    $KeyVaultName,
    [Parameter(Mandatory = $true)]
    [string]
    $VNetName,
    [Parameter(Mandatory = $true)]
    [string]
    $SubnetName
  )

  Write-Debug -Debug:$true -Message "Remove Key Vault $KeyVaultName Network Rule for $VNetName and $SubnetName"

  $output = az keyvault network-rule remove `
    --subscription "$SubscriptionId" `
    -g "$ResourceGroupName" `
    -n "$KeyVaultName" `
    --vnet-name "$VNetName" `
    --subnet "$SubnetName" `
    | ConvertFrom-Json

  return $output
}