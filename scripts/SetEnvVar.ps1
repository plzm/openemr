param
(
  [Parameter(Mandatory = $true)]
  [string]
  $VarName,
  [Parameter(Mandatory = $true)]
  [string]
  $VarValue
)

if ($env.GITHUB_ENV)
{
  Write-Output "$VarName=$VarValue" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
}
else
{
  Invoke-Expression ("$" + "env:" + "$VarName='$VarValue'")
}
