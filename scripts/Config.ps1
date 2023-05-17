function GetConfig()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json
}

function GetConfigMatrix()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath,
    [Parameter(Mandatory = $true)]
    [string]
    $DeployUnit
  )

  $configEnv = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $configEnv | Where-Object { $_.DeployUnit -eq "$DeployUnit" }
}

function GetResourceName()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigAll,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMatrix,
    [Parameter(Mandatory = $false)]
    [string]
    $Prefix = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Sequence = ""
  )

  $result = $ConfigAll.NamePrefix + "-" + $ConfigAll.NameInfix + "-" + $ConfigMatrix.DeployUnit + "-" + $ConfigMatrix.Location

  if ($Prefix)
  {
    $result = $Prefix + "-" + $result
  }

  if ($Sequence)
  {
    $result = $result + "-" + $Sequence
  }

  return $result
}