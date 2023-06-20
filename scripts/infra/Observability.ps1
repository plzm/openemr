


function DeployLogAnalyticsWorkspace() {
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
    $WorkspaceName,
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccessForIngestion = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $PublicNetworkAccessForQuery = "Enabled",
    [Parameter(Mandatory = $false)]
    [string]
    $Tags = ""
  )

  Write-Debug -Debug:$true -Message "Deploy Log Analytics Workspace"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$WorkspaceName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    location="$Location" `
    workspaceName="$WorkspaceName" `
    publicNetworkAccessForIngestion="$PublicNetworkAccessForIngestion" `
    publicNetworkAccessForQuery="$PublicNetworkAccessForQuery" `
    tags=$Tags
}

function DeployDiagnosticsSetting()
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
    $ResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $DiagnosticsSettingName,
    [Parameter(Mandatory = $true)]
    [string]
    $LogAnalyticsWorkspaceResourceId,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendLogs = $true,
    [Parameter(Mandatory = $false)]
    [bool]
    $SendMetrics = $true
  )

  Write-Debug -Debug:$true -Message "Deploy Diagnostics Setting $DiagnosticsSettingName"

  az deployment group create --verbose `
    --subscription "$SubscriptionId" `
    -n "$DiagnosticsSettingName" `
    -g "$ResourceGroupName" `
    --template-uri "$TemplateUri" `
    --parameters `
    resourceId="$ResourceId" `
    diagnosticsSettingName="$DiagnosticsSettingName" `
    logAnalyticsWorkspaceResourceId="$LogAnalyticsWorkspaceResourceId" `
    sendLogs=$true `
    sendMetrics=$true
}