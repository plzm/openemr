function Deploy-MySqlFlexServer()
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
    $UserAssignedIdentityId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AdministratorLogin = "",
    [Parameter(Mandatory = $false)]
    [SecureString]
    $AdministratorPassword = "",
    [Parameter(Mandatory = $true)]
    [string]
    $SkuName,
    [Parameter(Mandatory = $true)]
    [string]
    $SkuTier,
    [Parameter(Mandatory = $false)]
    [string]
    $Version = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AvailabilityZone = "",
    [Parameter(Mandatory = $false)]
    [string]
    $CreateMode = "",
    [Parameter(Mandatory = $false)]
    [string]
    $HaEnabled = "",
    [Parameter(Mandatory = $false)]
    [string]
    $StandbyAvailabilityZone = "",
    [Parameter(Mandatory = $false)]
    [string]
    $StorageSizeGB = "",
    [Parameter(Mandatory = $false)]
    [int]
    $StorageIops = 0,
    [Parameter(Mandatory = $false)]
    [string]
    $storageAutogrow = "",
    [Parameter(Mandatory = $false)]
    [string]
    $AutoIoScaling = "",
    [Parameter(Mandatory = $false)]
    [string]
    $LogOnDisk = "",
    [Parameter(Mandatory = $false)]
    [string]
    $ReplicationRole = "",
    [Parameter(Mandatory = $false)]
    [string]
    $BackupRetentionDays = "",
    [Parameter(Mandatory = $false)]
    [string]
    $RestorePointInTime = "",
    [Parameter(Mandatory = $false)]
    [string]
    $SourceServerResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $GeoRedundantBackup = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DataEncryptionGeoBackupKeyUri = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DataEncryptionGeoBackupUserAssignedIdentityId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DataEncryptionPrimaryKeyUri = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DataEncryptionPrimaryUserAssignedIdentityId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $DataEncryptionType = "",
    [Parameter(Mandatory = $false)]
    [string]
    $MaintenanceCustomWindow = "",
    [Parameter(Mandatory = $false)]
    [int]
    $MaintenanceDayOfWeek = 6,
    [Parameter(Mandatory = $false)]
    [int]
    $MaintenanceStartHour = 23,
    [Parameter(Mandatory = $false)]
    [int]
    $MaintenanceStartMinute = 0,
    [Parameter(Mandatory = $false)]
    [string]
    $DelegatedSubnetResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $PrivateDnsZoneResourceId = "",
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccess = "Disabled",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy MySql FlexServer $ServerName"

  $output = az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$ServerName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    serverName="$ServerName" `
    userAssignedIdentityId="$UserAssignedIdentityId" `
    administratorLogin="$AdministratorLogin" `
    administratorPassword="$AdministratorPassword" `
    skuName="$SkuName" `
    skuTier="$SkuTier" `
    version="$Version" `
    availabilityZone="$AvailabilityZone" `
    createMode="$CreateMode" `
    haEnabled="$HaEnabled" `
    standbyAvailabilityZone="$StandbyAvailabilityZone" `
    storageSizeGB="$StorageSizeGB" `
    storageIops="$StorageIops" `
    storageAutogrow="$StorageAutogrow" `
    autoIoScaling="$AutoIoScaling" `
    logOnDisk="$LogOnDisk" `
    replicationRole="$ReplicationRole" `
    backupRetentionDays="$BackupRetentionDays" `
    restorePointInTime="$RestorePointInTime" `
    sourceServerResourceId="$SourceServerResourceId" `
    geoRedundantBackup="$GeoRedundantBackup" `
    dataEncryptionGeoBackupKeyUri="$DataEncryptionGeoBackupKeyUri" `
    dataEncryptionGeoBackupUserAssignedIdentityId="$DataEncryptionGeoBackupUserAssignedIdentityId" `
    dataEncryptionPrimaryKeyUri="$DataEncryptionPrimaryKeyUri" `
    dataEncryptionPrimaryUserAssignedIdentityId="$DataEncryptionPrimaryUserAssignedIdentityId" `
    dataEncryptionType="$DataEncryptionType" `
    maintenanceCustomWindow="$MaintenanceCustomWindow" `
    maintenanceDayOfWeek="$MaintenanceDayOfWeek" `
    maintenanceStartHour="$MaintenanceStartHour" `
    maintenanceStartMinute="$MaintenanceStartMinute" `
    delegatedSubnetResourceId="$DelegatedSubnetResourceId" `
    privateDnsZoneResourceId="$PrivateDnsZoneResourceId" `
    publicNetworkAccess="$PublicNetworkAccess" `
    tags=$Tags `
    | ConvertFrom-Json

  return $output
}
