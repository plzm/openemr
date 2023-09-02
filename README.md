[![GitHub Super-Linter](https://github.com/plzm/openemr/actions/workflows/LintCode.yml/badge.svg)](https://github.com/marketplace/actions/super-linter)

# OpenEMR on Azure

## Steps

1. Edit and run [./scripts/github/CreateServicePrincipal.sh](./scripts/github/CreateServicePrincipal.sh), and save its output to a repository secret named AZURE_CREDENTIALS. This is required so that GitHub Actions workflows can run Azure CLI and PS commands.



NOTE: Service principals used for GitHub Actions workflows must have the following Azure RBAC roles assigned to them: Azure AD Directory Reader, Key Vault * Officer
