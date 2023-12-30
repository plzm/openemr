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

function Get-ConfigScaleUnitTemplate()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Write-Debug -Debug:$debug -Message ("Get-ConfigScaleUnitTemplate: ConfigFilePath: " + "$ConfigFilePath")

  $config = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $config | Where-Object { $_.Scope -eq "ScaleUnitTemplate" }
}


function Get-ConfigScaleUnits()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFilePath
  )

  Write-Debug -Debug:$debug -Message ("Get-ConfigScaleUnits: ConfigFilePath: " + "$ConfigFilePath")

  $config = Get-Content -Path "$ConfigFilePath" | ConvertFrom-Json

  $config | Where-Object { $_.Scope -eq "ScaleUnit" }
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
    $tagScaleUnit = "ScaleUnit=" + $ConfigScaleUnit.Id

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
    $tagsObject['ScaleUnit'] = $ConfigScaleUnit.Id
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
