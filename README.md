# OpenEMR on Azure

## Steps

1. Edit and run [./scripts/create-service-principal-for-github-actions.sh](./scripts/create-service-principal-for-github-actions.sh), and save its output to a repository secret named AZURE_CREDENTIALS. This is required so that GitHub Actions workflows can run.
2. 