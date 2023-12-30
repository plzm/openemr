[![GitHub Super-Linter](https://github.com/plzm/openemr/actions/workflows/LintCode.yml/badge.svg)](https://github.com/marketplace/actions/super-linter)

# OpenEMR on Azure

## Steps

1. Create a Service Principal with the following Azure CLI command. Replace the tokens (e.g. `[YOUR_SERVICE_PRINCIPAL_NAME]`) with appropriate real values.
2. Save the CLI command's JSON output to a repository secret named AZURE_CREDENTIALS. This is required so that GitHub Actions workflows can run Azure CLI and PS commands.

**Azure CLI command to create Service Principal** (remember to replace the tokens...)
```bash
az ad sp create-for-rbac --name "[YOUR_SERVICE_PRINCIPAL_NAME]" --role "Owner" --scopes "/subscriptions/[YOUR_AZURE_SUBSCRIPTION_ID]" --verbose --sdk-auth
```
