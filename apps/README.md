# Application Deployments

This directory contains Helm-based application deployments for testing the stamp infrastructure.

## Available Applications

### Spring PetClinic

A well-known Java demo application for testing AKS deployments.

- **Chart Source**: Bitnami Spring PetClinic or custom chart
- **Purpose**: Validate AKS cluster connectivity, ingress, and workload identity

## Deployment

Applications can be deployed using the Azure DevOps pipeline or locally:

### Via Azure DevOps Pipeline

1. Go to **Pipelines** → **deploy-app.yml**
2. Select the target stamp (e.g., `swc-dev`, `neu-prod`)
3. Choose the application to deploy
4. Run the pipeline

### Local Deployment

```bash
# Get AKS credentials for the stamp
az aks get-credentials -g rg-swc-dev-compute -n aks-swc-dev

# Deploy using Helm
helm upgrade --install petclinic ./apps/petclinic \
  --namespace petclinic \
  --create-namespace \
  -f ./apps/petclinic/values.yaml
```

## Directory Structure

```
apps/
├── README.md                 # This file
├── petclinic/               # Spring PetClinic Helm chart
│   ├── Chart.yaml
│   ├── values.yaml          # Default values
│   ├── values-dev.yaml      # Dev environment overrides
│   ├── values-staging.yaml  # Staging environment overrides
│   ├── values-prod.yaml     # Production environment overrides
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── ...
```

## Environment-Specific Configuration

Each stamp maps to an environment (dev/staging/prod). The pipeline automatically selects the appropriate values file based on the stamp's environment attribute defined in the stamp catalog.

| Stamp       | Environment | Values File         |
|-------------|-------------|---------------------|
| swc-dev     | dev         | values-dev.yaml     |
| swc-staging | staging     | values-staging.yaml |
| swc-prod    | prod        | values-prod.yaml    |
| neu-dev     | dev         | values-dev.yaml     |
| neu-prod    | prod        | values-prod.yaml    |
