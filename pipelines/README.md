# Azure DevOps Setup Guide

This guide explains how to set up Azure DevOps pipelines for the stamp-based infrastructure.

## Prerequisites

- Azure DevOps organization and project
- Azure subscription with Contributor access
- Terraform 1.3+ (installed by pipelines)

---

## 1. Create Service Connections

Create Azure Resource Manager service connections with workload identity federation (recommended).

### For Bootstrap
| Name | Subscription | Required Roles |
|------|-------------|----------------|
| `azure-infra-bootstrap` | Your subscription | Contributor, Storage Blob Data Contributor |

### For Development
| Name | Subscription | Required Roles |
|------|-------------|----------------|
| `azure-infra-dev` | Your subscription | Contributor, Storage Blob Data Contributor |

### For Production (optional - separate subscription)
| Name | Subscription | Required Roles |
|------|-------------|----------------|
| `azure-infra-prod` | Production subscription | Contributor, Storage Blob Data Contributor |

**To create a service connection:**
1. Go to Project Settings → Service Connections
2. Click "New service connection" → Azure Resource Manager
3. Select "Workload Identity federation (automatic)" 
4. Select your subscription and resource group (or leave blank for subscription-level)
5. Name it as above and save

---

## 2. Create Variable Groups

Go to Pipelines → Library → Variable Groups

### stamp-common
Shared variables for all stamps.

| Variable | Value | Secret | Description |
|----------|-------|--------|-------------|
| `SUBSCRIPTION_ID` | `your-subscription-id` | No | Where stamp resources are deployed |
| `BOOTSTRAP_SUBSCRIPTION_ID` | `your-bootstrap-sub-id` | No | Where Terraform state backend lives (optional, defaults to SUBSCRIPTION_ID) |

**Multi-Subscription Deployments:**
- If all stamps and state are in the same subscription, only set `SUBSCRIPTION_ID`
- If state backend is in a different subscription (e.g., shared infra sub), also set `BOOTSTRAP_SUBSCRIPTION_ID`

### stamp-dev (optional)
Override values for development stamps.

| Variable | Value | Secret |
|----------|-------|--------|
| `MONGODB_ATLAS_PUBLIC_KEY` | `your-key` | Yes |
| `MONGODB_ATLAS_PRIVATE_KEY` | `your-private-key` | Yes |
| `MONGODB_ORG_ID` | `your-org-id` | No |

### stamp-prod (optional)
Override values for production stamps.

| Variable | Value | Secret |
|----------|-------|--------|
| `MONGODB_ATLAS_PUBLIC_KEY` | `your-prod-key` | Yes |
| `MONGODB_ATLAS_PRIVATE_KEY` | `your-prod-private-key` | Yes |
| `MONGODB_ORG_ID` | `your-prod-org-id` | No |

---

## 3. Create Environments

Go to Pipelines → Environments

### Development Environment
- **Name:** `dev`
- **Approvals:** None (auto-deploy)

### Staging Environment
- **Name:** `staging`
- **Approvals:** Add approvers (optional)

### Production Environment
- **Name:** `prod`
- **Approvals:** Required - add leads/managers
- **Checks:** 
  - Business hours only (optional)
  - Minimum wait time (optional)

### Destroy Approval
- **Name:** `destroy-approval`
- **Approvals:** Required - add senior team members
- **Description:** Protects against accidental destruction

---

## 4. Create Pipelines

### Bootstrap Pipeline (run first)

1. Go to Pipelines → New Pipeline
2. Select your repository
3. Choose "Existing Azure Pipelines YAML file"
4. Select `/pipelines/bootstrap.yml`
5. Save (don't run yet)

### Deploy Stamp Pipeline

1. New Pipeline → Select repo → Existing YAML
2. Select `/pipelines/deploy-stamp.yml`
3. Save

### PR Validation Pipeline

1. New Pipeline → Select repo → Existing YAML
2. Select `/pipelines/pr-validation.yml`
3. Save
4. Edit pipeline → Triggers → Enable PR trigger

### Destroy Pipeline

1. New Pipeline → Select repo → Existing YAML
2. Select `/pipelines/destroy-stamp.yml`
3. Save

---

## 5. Initial Setup (Bootstrap)

Run the bootstrap pipeline once to create the shared Terraform state backend:

1. Go to the Bootstrap pipeline
2. Click "Run pipeline"
3. Check ✅ "Confirm Bootstrap Creation"
4. Run

This creates:
- Resource group for state storage
- Storage account with Azure AD auth
- Blob container for state files

---

## 6. Deploy Your First Stamp

1. Go to the Deploy Stamp pipeline
2. Click "Run pipeline"
3. Select stamp: `swc-dev`
4. Check layers to deploy (default: all)
5. Run

The pipeline will:
1. **Validate** - Check Terraform syntax
2. **Plan** - Show changes for each layer
3. **Deploy** - Apply changes (with approval for staging/prod)

---

## Pipeline Parameters

### deploy-stamp.yml

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stampId` | Which stamp to deploy | `swc-dev` |
| `deployLayers` | Which layers to deploy | All enabled |
| `autoApprove` | Skip apply confirmation | `false` |

### destroy-stamp.yml

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stampId` | Which stamp to destroy | `swc-dev` |
| `layers` | Layers to destroy (reverse order) | All |
| `confirmDestroy` | Type stamp ID to confirm | Empty |

---

## Recommended Workflow

### New Feature Development
```
1. Create feature branch
2. Make changes to Terraform
3. Create PR → pr-validation runs automatically
4. Review plan output in PR
5. Merge to main → optionally trigger deploy
```

### Deploy to Production
```
1. Deploy to swc-dev (auto-approve)
2. Validate in dev environment
3. Deploy to swc-staging (requires approval)
4. Run integration tests
5. Deploy to swc-prod (requires approval)
```

### New Region
```
1. Add stamp to terraform/modules/stamp/main.tf
2. Run deploy-stamp with new stamp ID
3. Configure DNS/traffic manager for new region
```

---

## Troubleshooting

### "Backend not initialized"
Run the bootstrap pipeline first.

### "Access denied to storage account"
Ensure service connection has "Storage Blob Data Contributor" role.

### "Stamp not found"
Add the stamp to `terraform/modules/stamp/main.tf` catalog.

### "Environment approval pending"
Check Pipelines → Environments → [env] → Approvals and approve.

---

## Security Best Practices

1. **Use Workload Identity** - Service connections should use workload identity federation, not secrets
2. **Limit Service Connection Scope** - Scope to resource groups when possible
3. **Require Approvals** - Always require approvals for production environments
4. **Separate Subscriptions** - Use separate subscriptions for dev/prod when possible
5. **Audit Logs** - Enable audit logging for all pipeline runs
6. **Branch Policies** - Require PR reviews before merge to main
