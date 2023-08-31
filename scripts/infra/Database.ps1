function Deploy-MariaDbServer()
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
    [string]
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
    [string]
    $SourceServerId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $RestorePointInTime = "",
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

  Write-Debug -Debug:$true -Message "Deploy MariaDB Server $ServerName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$ServerName" `
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
    mariaDbVersion="$MariaDbVersion" `
    createMode="$CreateMode" `
    sourceServerId="$SourceServerId" `
    restorePointInTime="$RestorePointInTime" `
    backupRetentionDays="$BackupRetentionDays" `
    geoRedundantBackup="$GeoRedundantBackup" `
    storageAutogrow="$StorageAutogrow" `
    minimumTlsVersion="$MinimumTlsVersion" `
    publicNetworkAccess="$PublicNetworkAccess" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}
