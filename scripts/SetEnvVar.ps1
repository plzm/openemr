function SetEnvVar
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
    PS> SetEnvVar -VarName "OE_FOO" -VarValue "BAR"
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

  if ($env.GITHUB_ENV)
  {
    Write-Host "GH"
    Write-Output "$VarName=$VarValue" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
  }
  else
  {
    Write-Host "local"
    $cmd = "$" + "env:" + "$VarName='$VarValue'"
    #$cmd
    Invoke-Expression $cmd
  }
}