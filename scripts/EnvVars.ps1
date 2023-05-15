function SetEnvVar2
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
    PS> . ./SetEnvVar.ps1
    PS> SetEnvVar2 -VarName "OE_FOO" -VarValue "BAR"
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

function SetEnvVar1()
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
    PS> . ./SetEnvVar.ps1
    PS> SetEnvVar1 -VarPair "OE_FOO=BAR"
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
      SetEnvVar2 -VarName $arr[0] -VarValue $arr[1]
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

function Get-EnvironmentVariables()
{
  Get-ChildItem env:
}

function SetEnvVarsMatrix()
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

  $infix = $ConfigAll.NamePrefix + "-" + $ConfigAll.NameInfix + "-" + $ConfigMatrix.Location
  $suffix = "-" + $infix + "-01"

  # ARM Template URI Prefix
  SetEnvVar2 -VarName "OE_ARM_TEMPLATE_URI_PREFIX" -VarValue $ConfigAll.TemplateUriPrefix

  # Azure region
  SetEnvVar2 -VarName "OE_LOCATION" -VarValue $ConfigMatrix.Location

  # Resource Group Name
  SetEnvVar2 -VarName "OE_RG_NAME" -VarValue $infix

  # UAI Name
  SetEnvVar2 -VarName "OE_UAI_NAME" -VarValue ("mid" + $suffix)

  # VNet Name
  SetEnvVar2 -VarName "OE_VNET_NAME" -VarValue ("vnt" + $suffix)

}

function SetEnvVarTags()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $Environment
  )

  $tagEnv = "env=" + $Environment
  $tagFoo = "foo=bar"

  $tagsForAzureCli = @($tagEnv, $tagFoo)

  $tagsObject = @{}
  $tagsObject['env'] = $Environment
  $tagsObject['foo'] = 'bar'

  # The following manipulations are needed to get through separate un-escaping by Powershell AND by Azure CLI, 
  # and to get CLI to correctly see the tags as a JSON string passed into ARM templates as an object type.
  $tagsForArm = ConvertTo-Json -InputObject $tagsObject -Compress
  $tagsForArm = $tagsForArm.Replace('"', '''')
  $tagsForArm = "`"$tagsForArm`""

  # Set the env vars
  # Tags for straight CLI commands
  SetEnvVar2 -VarName "OE_TAGS_FOR_CLI" -VarValue "$tagsForAzureCli"
  # Tags for ARM template tags parameter - do not quote the variable for this, breaks ARM template tags
  SetEnvVar2 -VarName "OE_TAGS_FOR_ARM" -VarValue $tagsForArm
}