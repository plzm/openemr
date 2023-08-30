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

function Get-ConfigConstants()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Write-Debug -Debug:$debug -Message ("Get-ConfigConstants: ConfigFilePath: " + "$ConfigFilePath")

  Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json
}

function Get-ConfigGlobal()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Write-Debug -Debug:$debug -Message ("Get-ConfigGlobal: ConfigFilePath: " + "$ConfigFilePath")

  $config = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $config | Where-Object { $_.Scope -eq "Global" }
}

function Get-ConfigScaleUnit()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath,
    [Parameter(Mandatory = $true)]
    [string]
    $Id
  )

  Write-Debug -Debug:$debug -Message ("Get-ConfigScaleUnit: ConfigFilePath: " + "$ConfigFilePath" + ", Id: " + "$Id")

  $config = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $config | Where-Object { $_.Scope -eq "ScaleUnit" -and $_.Id -eq "$Id" }
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
    $ConfigConstants,
    [Parameter(Mandatory = $false)]
    [object]
    $ConfigGlobal = $null,
    [Parameter(Mandatory = $false)]
    [object]
    $ConfigScaleUnit = $null,
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

  if ($ConfigConstants.NamePrefix) { $result = $ConfigConstants.NamePrefix }
  if ($ConfigConstants.NameInfix) { $result += $delimiter + $ConfigConstants.NameInfix }

  if ($ConfigGlobal -and $ConfigGlobal.Id) { $result += $delimiter + $ConfigGlobal.Id }
  if ($ConfigScaleUnit -and $ConfigScaleUnit.Id) { $result += $delimiter + $ConfigScaleUnit.Id }

  if ($Prefix) { $result = $Prefix + $delimiter + $result }
  if ($Sequence) { $result += $delimiter + $Sequence }
  if ($Suffix) { $result += $delimiter + $Suffix }

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
    [Parameter(Mandatory = $false)]
    [object]
    $ConfigScaleUnit = $null
  )

  Write-Debug -Debug:$debug -Message ("Set-EnvVars: Environment: " + "$Environment")

  if ($ConfigScaleUnit)
  {
    Set-EnvVarsScaleUnit `
    -ConfigScaleUnit $ConfigScaleUnit
  }

  Set-EnvVarTags `
    -Environment $Environment `
    -ConfigScaleUnit $ConfigScaleUnit
}

function Set-EnvVarsScaleUnit()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $ConfigScaleUnit
  )
  Write-Debug -Debug:$debug -Message ("Set-EnvVarsScaleUnit")
 
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
    [Parameter(Mandatory = $false)]
    [object]
    $ConfigScaleUnit = $null
  )

  Write-Debug -Debug:$debug -Message ("Set-EnvVarTags: Environment: " + "$Environment")

  $tagEnv = "env=" + $Environment

  if ($ConfigScaleUnit)
  {
    $tagScaleUnit = "ScaleUnit=" + $ConfigScaleUnit.ScaleUnit

    $tagsForAzureCli = @($tagEnv, $tagScaleUnit)
  }
  else
  {
    $tagsForAzureCli = @($tagEnv)
  }

  $tagsObject = @{}
  $tagsObject['env'] = $Environment

  if ($ConfigScaleUnit)
  {
    $tagsObject['ScaleUnit'] = $ConfigScaleUnit.ScaleUnit
  }

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