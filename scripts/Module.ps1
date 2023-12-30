function Get-PlzmAzureModule()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [object]
    $UrlRoot
  )

  $moduleName = "plzm.Azure"
  $localFolderPath = "./modules/$moduleName/"
  $psm1FileName = "$moduleName.psm1"
  $psd1FileName = "$moduleName.psd1"

  if (!(Test-Path -Path $localFolderPath))
  {
    New-Item -Path $localFolderPath -ItemType "Directory" -Force
  }

  # PSM1 file
  $url = ($UrlRoot + $psm1FileName)
  Invoke-WebRequest -Uri "$url" -OutFile ($localFolderPath + $psm1FileName)

  # PSD1 file
  $url = ($UrlRoot + $psd1FileName)
  Invoke-WebRequest -Uri "$url" -OutFile ($localFolderPath + $psd1FileName)

  Import-Module "$localFolderPath" -Force

  plzm.Azure\Set-EnvVar2 -VarName "AA_MODULE_PATH_PLZM_AZURE" -VarValue "$localFolderPath"

  Write-Debug -Debug:$true -Message "Module $moduleName imported with version $((Get-Module $moduleName).Version)"
  plzm.Azure\Get-Timestamp
}