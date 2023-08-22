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
    [Parameter(Mandatory=$true)]
    [string]
    $keyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $rawSecretName,
    [Parameter(Mandatory=$true)]
    [string]
    $rawSecretValue
  )
  $secretName = Get-KeyVaultSecretName -VarName "$rawSecretName"
  $secretValue = ConvertTo-SecureString "$rawSecretValue" -AsPlainText -Force

  az keyvault secret set `
    --vault-name "$keyVaultName" `
    --name "$secretName" `
    --value "$secretValue" `
    --output none
}
