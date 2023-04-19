param
(
  [Parameter(Mandatory = $true)]
  [string]
  $SubscriptionName,
  [Parameter(Mandatory = $true)]
  [string]
  $ServicePrincipalName,
  [Parameter(Mandatory = $true)]
  [string]
  $RoleName = "Owner"
)

$subscriptionId = "$(az account show -s $SubscriptionName -o tsv --query 'id')"

az ad sp create-for-rbac --name "$ServicePrincipalName" --role "$RoleName" --scopes "/subscriptions/$subscriptionId" --verbose --sdk-auth
