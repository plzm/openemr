# OpenEMR on Azure

## Steps

1. Edit and run [./scripts/github/CreateServicePrincipal.sh](./scripts/github/CreateServicePrincipal.sh), and save its output to a repository secret named AZURE_CREDENTIALS. This is required so that GitHub Actions workflows can run Azure CLI and PS commands.
2. 