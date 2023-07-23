function Deploy-Database()
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
    $ServerName,
    [Parameter(Mandatory = $false)]
    [string]
    $AdministratorLogin = "",
    [Parameter(Mandatory = $false)]
    [securestring]
    $AdministratorPassword = "",
    [Parameter(Mandatory = $true)]
    [string]
    $SkuTier,
    [Parameter(Mandatory = $true)]
    [string]
    $SkuFamily,
    [Parameter(Mandatory = $true)]
    [string]
    $SkuName,
    [Parameter(Mandatory = $true)]
    [int]
    $SkuCapacity,
    [Parameter(Mandatory = $true)]
    [int]
    $SkuSizeMB,
    [Parameter(Mandatory = $true)]
    [string]
    $MariaDbVersion,
    [Parameter(Mandatory = $true)]
    [string]
    $CreateMode,
    [Parameter(Mandatory = $false)]
    [int]
    $BackupRetentionDays = 7,
    [Parameter(Mandatory = $false)]
    [string]
    $GeoRedundantBackup = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $StorageAutogrow = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $MinimumTlsVersion = "TLS1_2",
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Database"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$KeyVaultName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    serverName="$ServerName" `
    administratorLogin="$AdministratorLogin" `
    administratorPassword="$AdministratorPassword" `
    skuTier="$SkuTier" `
    skuFamily="$SkuFamily" `
    skuName="$SkuName" `
    skuCapacity="$SkuCapacity" `
    skuSizeMB="$SkuSizeMB" `
    mariadbVersion="$MariaDbVersion" `
    createMode="$CreateMode" `
    backupRetentionDays="$BackupRetentionDays" `
    geoRedundantBackup="$GeoRedundantBackup" `
    storageAutogrow="$StorageAutogrow" `
    allowedSubnetResourceIds="$AllowedSubnetResourceIdsCsv" `
    publicNetworkAccess="$PublicNetworkAccess" `
    tags=$Tags
}
