$debug = $true

function Get-Timestamp()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false)]
    [bool]
    $MakeStringSafe=$false
  )

  $result = (Get-Date -AsUTC -format s) + "Z"

  if ($MakeStringSafe)
  {
    $result = $result.Replace(":", "-")
  }

  return $result
}

#region Configuration

function Get-Config()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Write-Debug -Debug:$debug -Message ("Get-Config: ConfigFilePath: " + "$ConfigFilePath")

  Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json
}

function Get-ConfigMatrix()
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

  Write-Debug -Debug:$debug -Message ("Get-ConfigMatrix: ConfigFilePath: " + "$ConfigFilePath" + ", DeployUnit: " + "$DeployUnit")

  $configEnv = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $configEnv | Where-Object { $_.DeployUnit -eq "$DeployUnit" }
}

#endregion

#region Resource

function Get-ResourceName()
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
    $Sequence = "",
    [Parameter(Mandatory = $false)]
    [string]
    $Suffix = "",
    [Parameter(Mandatory = $false)]
    [bool]
    $IncludeDelimiter = $true
  )

  Write-Debug -Debug:$debug -Message ("Get-ResourceName: Prefix: " + "$Prefix" + ", Sequence: " + "$Sequence" + ", Suffix: " + "$Suffix" + ", IncludeDelimiter: " + "$IncludeDelimiter")

  if ($IncludeDelimiter)
  {
    $delimiter = "-"
  }
  else
  {
    $delimiter = ""
  }

  $result = ""

  if ($ConfigAll.NamePrefix) { $result = $ConfigAll.NamePrefix }
  if ($ConfigAll.NameInfix) { $result = $result + $delimiter + $ConfigAll.NameInfix }
  if ($ConfigMatrix.DeployUnit) { $result = $result + $delimiter + $ConfigMatrix.DeployUnit }
  if ($ConfigMatrix.Location) { $result = $result + $delimiter + $ConfigMatrix.Location }

  if ($Prefix) { $result = $Prefix + $delimiter + $result }
  if ($Sequence) { $result = $result + $delimiter + $Sequence }
  if ($Suffix) { $result = $result + $delimiter + $Suffix }

  return $result
}

function Get-ResourceId()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceProviderName,
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceTypeName,
    [Parameter(Mandatory = $false)]
    [string]
    $ResourceSubTypeName = "",
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceName,
    [Parameter(Mandatory = $false)]
    [string]
    $ChildResourceTypeName = "",
    [Parameter(Mandatory = $false)]
    [string]
    $ChildResourceName = ""
  )

  Write-Debug -Debug:$debug -Message ("Get-ResourceId: SubscriptionId: " + "$SubscriptionId" + ", ResourceGroupName: " + "$ResourceGroupName" + ", ResourceProviderName: " + "$ResourceProviderName" + ", ResourceTypeName: " + "$ResourceTypeName" + ", ResourceName: " + "$ResourceName" + ", ChildResourceTypeName: " + "$ChildResourceTypeName" + ", ChildResourceName: " + "$ChildResourceName")

  $result = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroupName + "/providers/" + $ResourceProviderName + "/" + $ResourceTypeName + "/"
  
  if ($ResourceSubTypeName)
  {
    $result += $ResourceSubTypeName + "/"
  }

  $result += $ResourceName

  if ($ChildResourceTypeName -and $ChildResourceName)
  {
    $result += "/" + $ChildResourceTypeName + "/" + $ChildResourceName
  }

  return $result
}

function Get-ChildResourceId()
{
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ParentResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $ChildResourceTypeName,
    [Parameter(Mandatory = $true)]
    [string]
    $ChildResourceName
  )

  Write-Debug -Debug:$debug -Message ("Get-ChildResourceId: ParentResourceId: " + "$ParentResourceId" + ", ChildResourceTypeName: " + "$ChildResourceTypeName" + ", ChildResourceName: " + "$ChildResourceName")

  $result = $ParentResourceId + "/" + $ChildResourceTypeName + "/" + $ChildResourceName

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

  Write-Debug -Debug:$debug -Message ("Set-EnvVars: Environment: " + "$Environment")

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
  Write-Debug -Debug:$debug -Message ("Set-EnvVarsMatrix")
 
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

  Write-Debug -Debug:$debug -Message ("Set-EnvVarTags: Environment: " + "$Environment")

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

  Write-Debug -Debug:$debug -Message ("Set-EnvVar2: VarName: " + "$VarName" + ", VarValue: " + "$VarValue")

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

  Write-Debug -Debug:$debug -Message ("Set-EnvVar1: VarPair: " + "$VarPair")

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
  Write-Debug -Debug:$debug -Message ("Get-EnvVars")

  Get-ChildItem env:
}

#endregion