# AI Coding Agent Instructions

## Project Overview
This project deploys a multi-regional Azure infrastructure for an AKS-based Java application using Terraform. The architecture now relies on **stamp-based scale units** where each deployment targets a single region/subscription pair derived from a `stamp_id`, ensuring region independence, private networking, and shared services that are scoped to that stamp.

## Architecture & Structure
The project follows a **layered Terraform architecture** to manage dependencies and state isolation. A reusable `terraform/modules/stamp` module centralizes naming conventions, CIDR blocks, backend coordinates, and default settings for each stamp.
- **Root**: `terraform/`
- **Layers** (`terraform/layers/`):
  - `00-bootstrap`: Remote state infrastructure (Storage Account, Container).
  - `01-networking`: VNETs, Subnets (/22 for AKS), Private Networking (Single region).
  - `02-shared`: Shared resources (Service Bus, Storage) with Private Endpoints and Private DNS Zones.
  - `03-database`: MongoDB Atlas configuration.
  - `04-compute`: AKS clusters (Java-optimized), ACR Premium with PE, Key Vault.

**Key Principles:**
- **Independence**: Regions are independent; sharding is external.
- **Environment Support**: Stamps include an `environment` attribute (dev/staging/prod) for proper sizing and tagging.
- **Shared Services**: Each stamp provisions its own shared resources (Service Bus, Storage) with Private Endpoints.
- **Networking**: All networking is private (Private Link/Endpoints with Private DNS Zones). Control plane access is enabled.
- **Java-Optimized**: Memory-optimized VMs (E-series), larger subnets (/22), workload identity enabled.

## Terraform Conventions
- **Providers**: Use `hashicorp/azurerm` version `~> 3.0`.
- **State Management**: 
  - Each layer maintains its own state.
  - `00-bootstrap` creates the backend storage.
  - Use `lifecycle { prevent_destroy = true }` for critical state resources.
- **Variables**: Use `variables.tf` for all configurable values (names, locations, SKUs). Avoid hardcoding.
- **Security**:
  - Prefer **Managed Identities** over Service Principals.
  - Implement **RBAC** for all access control within the IaC.
  - Ensure AKS is zone-enabled with workload identity.
  - All services use Private Endpoints with corresponding Private DNS Zones.

## Development Workflow
1. **Bootstrap**: Ensure `00-bootstrap` is applied first to establish state storage.
2. **Layered Application**: Apply layers in numerical order (`01` -> `02` -> ...); each layer only accepts `subscription_id` and `stamp_id` (plus MongoDB inputs in layer `03`).
3. **Cross-Layer Dependencies**: Use `terraform_remote_state` or data sources to reference resources from previous layers. Do not couple layers tightly if possible.

## Specific Patterns
- **Stamp-Based Deployment**: Each stamp defines its own region, environment, address spaces, and naming derived from `stamp_id`. Deploy one stamp per run; replicate to other environments by adding catalog entries under `terraform/modules/stamp` and rerunning the layers with the new `stamp_id`.
- **Environment Cloning**: To create dev/staging/prod in the same region, add stamp entries like `swc-dev`, `swc-staging`, `swc-prod` with different CIDR ranges and sizing.
- **Multi-Region**: Support additional regions by adding new stamp catalog entries rather than coupling resources across subscriptions; shared resources exist once per stamp.
- **Global Names**: Storage Accounts and ACR names include a hash of `stamp_id + subscription_id` to avoid collisions across subscriptions; keep stamp IDs short to preserve friendly prefixes.
- **Shared Layer Optionality**: Catalog entries can declare `shared = { enabled = false }` to indicate that the stamp will not provision the `02-shared` layer. Downstream layers must respect this flag and skip shared dependencies.
- **Clean Destroy**: Providers that create resource groups must set `features.resource_group.prevent_deletion_if_contains_resources = false` so destroys succeed even when Azure injects ancillary resources (e.g., PE NSGs).
- **Database**: MongoDB Atlas is managed as a separate layer (`03-database`).
- **Java/AKS**: The target workload is Java on AKS; use memory-optimized VMs (Standard_E4s_v5/E8s_v5), /22 subnets for IP headroom, max_pods=30, and workload identity for Azure SDK auth.

## Stamp Catalog Structure
Each stamp in `terraform/modules/stamp/main.tf` should define:
```hcl
stamp-id = {
  location               = "region"
  environment            = "dev|staging|prod"
  address_space          = "10.x.0.0/16"
  aks_subnet_cidr        = "10.x.0.0/22"    # /22 for Java workloads
  pe_subnet_cidr         = "10.x.4.0/24"
  service_cidr           = "10.x.10.0/24"
  dns_service_ip         = "10.x.10.10"
  service_bus_capacity   = 1-4
  service_bus_partitions = 1-4
  aks_vm_size            = "Standard_E4s_v5"  # Memory-optimized
  aks_node_count         = 2-3
  aks_max_pods           = 30
  shared = { enabled = true|false }
}
```

## Private DNS Zones
All Private Endpoints require corresponding DNS Zones linked to the VNet:
- `privatelink.blob.core.windows.net` (Storage)
- `privatelink.servicebus.windows.net` (Service Bus)
- `privatelink.azurecr.io` (ACR)
- `privatelink.vaultcore.azure.net` (Key Vault)

# Learnings
Update this document when you learn something new about the project structure, architecture, or conventions.
- Use `shared_access_key_enabled = false` for Storage Accounts used as Terraform backends to enhance security by disabling key-based authentication. Provider also needs to have `storage_use_azuread = true` set.
- All Azure Terraform layers now take only `subscription_id` and `stamp_id`; the `terraform/modules/stamp` catalog is the single source of truth for stamp naming, CIDRs, and backend coordinates. Add new stamps there before deploying new regions.
- AKS subnets should be /22 (1022 IPs) for Java workloads with Azure CNI to avoid IP exhaustion.
- Use memory-optimized VMs (E-series) for JVM workloads; Standard_DS2_v2 is insufficient for production Java apps.
- Private Endpoints without Private DNS Zones will not resolve correctly from within the VNet; always create and link DNS Zones.
- ACR must be Premium SKU to support Private Endpoints; Standard SKU only allows public access.
- Enable OIDC and workload identity on AKS for secure Azure SDK authentication without embedding secrets in pods.
- Environment attribute in stamps (dev/staging/prod) enables proper resource sizing and cost management via tags.