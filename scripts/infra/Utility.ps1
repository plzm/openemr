#region Configuration

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

#endregion

#region Resource

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

#endregion

#region Environment Variables

function Set-EnvVars()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Environment,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigAll,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMatrix
  )

  Set-EnvVarsMatrix `
  -ConfigAll $ConfigAll `
  -ConfigMatrix $ConfigMatrix

  Set-EnvVarTags `
    -Environment $Environment `
    -ConfigAll $ConfigAll `
    -ConfigMatrix $ConfigMatrix
}

function Set-EnvVarsMatrix()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigAll,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMatrix
  )
  # 
  #Set-EnvVar2 -VarName "" -VarValue ""
}

function Set-EnvVarTags()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Environment,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigAll,
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigMatrix
  )

  $tagEnv = "env=" + $Environment
  #$tagFoo = "foo=bar"

  $tagsForAzureCli = @($tagEnv)

  $tagsObject = @{}
  $tagsObject['env'] = $Environment
  #$tagsObject['foo'] = 'bar'

  # The following manipulations are needed to get through separate un-escaping by Powershell AND by Azure CLI, 
  # and to get CLI to correctly see the tags as a JSON string passed into ARM templates as an object type.
  $tagsForArm = ConvertTo-Json -InputObject $tagsObject -Compress
  $tagsForArm = $tagsForArm.Replace('"', '''')
  $tagsForArm = "`"$tagsForArm`""

  # Set the env vars
  # Tags for straight CLI commands
  Set-EnvVar2 -VarName "OE_TAGS_FOR_CLI" -VarValue "$tagsForAzureCli"
  # Tags for ARM template tags parameter - do not quote the variable for this, breaks ARM template tags
  Set-EnvVar2 -VarName "OE_TAGS_FOR_ARM" -VarValue $tagsForArm
}

function Set-EnvVar2
{
  <#
    .SYNOPSIS
    This command sets an environment variable. It detects if the runtime context is GitHub Actions and if so, sets it correctly for GHA runners.
    .DESCRIPTION
    This command sets an environment variable. It detects if the runtime context is GitHub Actions and if so, sets it correctly for GHA runners.
    .PARAMETER VarName
    The environment variable name.
    .PARAMETER VarValue
    The environment variable value.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> . ./scripts/infra/Utility.ps1
    PS> Set-EnvVar2 -VarName "OE_FOO" -VarValue "BAR"
    .LINK
    None
  #>

  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $VarName,
    [Parameter(Mandatory = $true)]
    [string]
    $VarValue
  )

  if ($env:GITHUB_ENV)
  {
    #Write-Host "GH"
    Write-Output "$VarName=$VarValue" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
  }
  else
  {
    #Write-Host "local"
    $cmd = "$" + "env:" + "$VarName='$VarValue'"
    #$cmd
    Invoke-Expression $cmd
  }
}

function Set-EnvVar1()
{
  <#
    .SYNOPSIS
    This command sets an environment variable. It detects if the runtime context is GitHub Actions and if so, sets it correctly for GHA runners.
    .DESCRIPTION
    This command sets an environment variable. It detects if the runtime context is GitHub Actions and if so, sets it correctly for GHA runners.
    .PARAMETER VarPair
    The environment variable name and value as VAR_NAME=VAR_VALUE
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> . ./scripts/infra/Utility.ps1
    PS> Set-EnvVar1 -VarPair "OE_FOO=BAR"
    .LINK
    None
  #>

  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $VarPair
  )

  if ($VarPair -like "*=*")
  {
    $arr = $VarPair -split "="

    if ($arr.Count -eq 2)
    {
      Set-EnvVar2 -VarName $arr[0] -VarValue $arr[1]
    }
    else
    {
      Write-Host "You must pass a VarValue param like FOO=BAR, with a variable name separated from variable value by an equals sign. No change made."
    }
  }
  else
  {
    Write-Host "You must pass a VarValue param like FOO=BAR, with a variable name separated from variable value by an equals sign. No change made."
  }
}

function Get-EnvVars()
{
  Get-ChildItem env:
}

#endregion