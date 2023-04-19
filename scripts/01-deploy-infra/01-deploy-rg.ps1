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
  $ResourceGroupName
)

az group create --subscription "$SubscriptionId" -l "$Location" -n "$ResourceGroupName" --verbose
