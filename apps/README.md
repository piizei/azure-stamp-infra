# Application Deployments

This directory contains Helm-based application deployments for testing the stamp infrastructure.

## Available Applications

### Hello World

A lightweight test application for quick infrastructure validation.

- **Image**: `mcr.microsoft.com/azuredocs/aks-helloworld:v1`
- **Purpose**: Quick smoke test for AKS connectivity and basic ingress

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

# Deploy Hello World
helm upgrade --install helloworld ./apps/helloworld \
  --namespace helloworld \
  --create-namespace \
  -f ./apps/helloworld/values.yaml

# Deploy PetClinic
# Note the deployment of pet-clinic is broken. It's intented for scenarios when troubleshooting/debugging with an agent.
helm upgrade --install petclinic ./apps/petclinic \
  --namespace petclinic \
  --create-namespace \
  -f ./apps/petclinic/values.yaml
```

### Finding the Public IP

After deploying an application with ingress enabled, get the public IP:

```bash
# Get the ingress IP for helloworld
kubectl get ingress -n helloworld

# Or get just the IP address
kubectl get ingress helloworld -n helloworld -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# For petclinic
kubectl get ingress petclinic -n petclinic -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

> **Note**: It may take 1-2 minutes for the ingress controller to assign an external IP after deployment.

## Directory Structure

```
apps/
├── README.md                 # This file
├── helloworld/              # Simple Hello World Helm chart
│   ├── Chart.yaml
│   ├── values.yaml          # Default values
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── ...
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
