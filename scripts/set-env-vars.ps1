echo "BUILD_NUMBER=yellow" >> $GITHUB_ENV
echo "${{ env.BUILD_NUMBER}}"


Write-Output "FOO=bar" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf8 -Append