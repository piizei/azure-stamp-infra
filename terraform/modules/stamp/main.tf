locals {
  default_catalog = {
    # ==========================================================================
    # Bootstrap Configuration (shared state backend for all stamps)
    # ==========================================================================
    # This is a special entry used by `./scripts/stamp bootstrap` to create
    # the shared Terraform state backend. All stamps share this single backend.
    _bootstrap = {
      location            = "swedencentral"  # Choose a central location for state
      environment         = "shared"
      address_space       = null  # Not used for bootstrap
      aks_subnet_cidr     = null
      pe_subnet_cidr      = null
      service_cidr        = null
      dns_service_ip      = null
      service_bus_capacity   = null
      service_bus_partitions = null
      aks_vm_size         = null
      aks_node_count      = null
      aks_max_pods        = null
      shared = {
        enabled = false
      }
    }

    # ==========================================================================
    # Sweden Central Stamps
    # ==========================================================================

    # Sweden Central - Development
    swc-dev = {
      location            = "swedencentral"
      environment         = "dev"
      address_space       = "10.10.0.0/16"
      aks_subnet_cidr     = "10.10.0.0/22"   # /22 = 1022 IPs for Java workloads
      pe_subnet_cidr      = "10.10.4.0/24"
      service_cidr        = "10.10.10.0/24"
      dns_service_ip      = "10.10.10.10"
      service_bus_capacity   = 1
      service_bus_partitions = 1
      # System nodepool (smaller, for system components)
      aks_vm_size         = "Standard_D2s_v5"
      aks_node_count      = 2
      aks_max_pods        = 30
      # User nodepool (memory-optimized for Java applications)
      user_nodepool = {
        enabled    = true
        vm_size    = "Standard_E4s_v5"  # Memory-optimized for JVM
        node_count = 2
        max_pods   = 30
      }
      shared = {
        enabled = true
      }
    }

    # Sweden Central - Staging
    swc-staging = {
      location            = "swedencentral"
      environment         = "staging"
      address_space       = "10.11.0.0/16"
      aks_subnet_cidr     = "10.11.0.0/22"
      pe_subnet_cidr      = "10.11.4.0/24"
      service_cidr        = "10.11.10.0/24"
      dns_service_ip      = "10.11.10.10"
      service_bus_capacity   = 1
      service_bus_partitions = 1
      # System nodepool
      aks_vm_size         = "Standard_D2s_v5"
      aks_node_count      = 2
      aks_max_pods        = 30
      # User nodepool (memory-optimized for Java applications)
      user_nodepool = {
        enabled    = true
        vm_size    = "Standard_E4s_v5"
        node_count = 3
        max_pods   = 30
      }
      shared = {
        enabled = true
      }
    }

    # Sweden Central - Production
    swc-prod = {
      location            = "swedencentral"
      environment         = "prod"
      address_space       = "10.12.0.0/16"
      aks_subnet_cidr     = "10.12.0.0/22"
      pe_subnet_cidr      = "10.12.4.0/24"
      service_cidr        = "10.12.10.0/24"
      dns_service_ip      = "10.12.10.10"
      service_bus_capacity   = 4
      service_bus_partitions = 4
      # System nodepool
      aks_vm_size         = "Standard_D4s_v5"
      aks_node_count      = 3
      aks_max_pods        = 30
      # User nodepool (memory-optimized for Java applications)
      user_nodepool = {
        enabled    = true
        vm_size    = "Standard_E8s_v5"
        node_count = 3
        max_pods   = 30
      }
      shared = {
        enabled = true
      }
    }

    # ==========================================================================
    # North Europe Stamps
    # ==========================================================================

    # North Europe - Development
    neu-dev = {
      location            = "northeurope"
      environment         = "dev"
      address_space       = "10.20.0.0/16"
      aks_subnet_cidr     = "10.20.0.0/22"
      pe_subnet_cidr      = "10.20.4.0/24"
      service_cidr        = "10.20.10.0/24"
      dns_service_ip      = "10.20.10.10"
      service_bus_capacity   = 1
      service_bus_partitions = 1
      # System nodepool
      aks_vm_size         = "Standard_D2s_v5"
      aks_node_count      = 2
      aks_max_pods        = 30
      # User nodepool (memory-optimized for Java applications)
      user_nodepool = {
        enabled    = true
        vm_size    = "Standard_E4s_v5"
        node_count = 2
        max_pods   = 30
      }
      shared = {
        enabled = true
      }
    }

    # North Europe - Production
    neu-prod = {
      location            = "northeurope"
      environment         = "prod"
      address_space       = "10.21.0.0/16"
      aks_subnet_cidr     = "10.21.0.0/22"
      pe_subnet_cidr      = "10.21.4.0/24"
      service_cidr        = "10.21.10.0/24"
      dns_service_ip      = "10.21.10.10"
      service_bus_capacity   = 4
      service_bus_partitions = 4
      # System nodepool
      aks_vm_size         = "Standard_D4s_v5"
      aks_node_count      = 3
      aks_max_pods        = 30
      # User nodepool (memory-optimized for Java applications)
      user_nodepool = {
        enabled    = true
        vm_size    = "Standard_E8s_v5"
        node_count = 3
        max_pods   = 30
      }
      shared = {
        enabled = true
      }
    }
  }

  normalized_stamp_id = lower(var.stamp_id)
  stamp_catalog       = { for key, value in local.default_catalog : lower(key) => value }
  stamp_config        = try(local.stamp_catalog[local.normalized_stamp_id], null)
  resolved_config     = local.stamp_config != null ? local.stamp_config : error("Stamp '${var.stamp_id}' is not defined. Update terraform/modules/stamp to add it before deploying.")

  # Subscription for stamp resources (AKS, networking, etc.)
  subscription_salt = trimspace(lower(var.subscription_id))
  entropy_source    = local.subscription_salt != "" ? "${local.normalized_stamp_id}-${local.subscription_salt}" : local.normalized_stamp_id
  hash_suffix       = substr(sha1(local.entropy_source), 0, 12)

  # Subscription for bootstrap/state backend (may differ in multi-subscription scenarios)
  bootstrap_subscription    = coalesce(var.bootstrap_subscription_id, var.subscription_id)
  bootstrap_subscription_salt = trimspace(lower(local.bootstrap_subscription))

  sanitized_alnum      = replace(replace(replace(local.normalized_stamp_id, "-", ""), "_", ""), " ", "")
  sanitized_alnum_safe = local.sanitized_alnum != "" ? local.sanitized_alnum : substr(md5(local.normalized_stamp_id), 0, 12)
  sanitized_dns        = trim(replace(local.normalized_stamp_id, "_", "-"), "-")
  sanitized_dns_safe   = local.sanitized_dns != "" ? local.sanitized_dns : local.sanitized_alnum_safe
  storage_suffix       = substr(local.hash_suffix, 0, 11)
  shared_config        = try(local.resolved_config.shared, { enabled = true })

  # Bootstrap naming - consistent across all stamps
  # When any stamp needs to reference the shared backend, use these values
  # Uses bootstrap_subscription_id for the hash (supports multi-subscription deployments)
  is_bootstrap           = local.normalized_stamp_id == "_bootstrap"
  bootstrap_entropy      = local.bootstrap_subscription_salt != "" ? "_bootstrap-${local.bootstrap_subscription_salt}" : "_bootstrap"
  bootstrap_hash         = substr(sha1(local.bootstrap_entropy), 0, 11)
  bootstrap_rg_name      = "rg-bootstrap-tfstate"
  bootstrap_storage_name = "st${local.bootstrap_hash}tfstate"

  naming = {
    networking_rg            = "rg-${local.sanitized_dns_safe}-network"
    shared_rg                = "rg-${local.sanitized_dns_safe}-shared"
    compute_rg               = "rg-${local.sanitized_dns_safe}-compute"
    # For _bootstrap stamp, use the bootstrap-specific naming
    tfstate_rg               = local.is_bootstrap ? local.bootstrap_rg_name : "rg-${local.sanitized_dns_safe}-tfstate"
    dns_rg                   = "rg-${local.sanitized_dns_safe}-dns"
    vnet_name                = "vnet-${local.sanitized_dns_safe}"
    aks_subnet_name          = "snet-aks-${local.sanitized_dns_safe}"
    pe_subnet_name           = "snet-pe-${local.sanitized_dns_safe}"
    nsg_name                 = "nsg-aks-${local.sanitized_dns_safe}"
    shared_storage_account   = "st${local.storage_suffix}shared"
    # For _bootstrap stamp, use the bootstrap-specific naming
    tfstate_storage_account  = local.is_bootstrap ? local.bootstrap_storage_name : "st${local.storage_suffix}tfstate"
    service_bus_namespace    = "sb-${local.sanitized_dns_safe}"
    private_endpoint_storage = "pe-${local.sanitized_dns_safe}-st"
    private_endpoint_sb      = "pe-${local.sanitized_dns_safe}-sb"
    private_endpoint_acr     = "pe-${local.sanitized_dns_safe}-acr"
    container_registry       = substr("acr${local.sanitized_alnum_safe}${local.hash_suffix}", 0, 50)
    user_assigned_identity   = "id-aks-${local.sanitized_dns_safe}"
    aks_cluster_name         = "aks-${local.sanitized_dns_safe}"
    dns_prefix               = "aks-${local.sanitized_dns_safe}"
    key_vault_prefix         = "kv-${local.sanitized_dns_safe}"
    # Private DNS Zone names (Azure standard naming)
    private_dns_zone_blob    = "privatelink.blob.core.windows.net"
    private_dns_zone_sb      = "privatelink.servicebus.windows.net"
    private_dns_zone_acr     = "privatelink.azurecr.io"
    private_dns_zone_kv      = "privatelink.vaultcore.azure.net"
    # Monitoring resources
    monitoring_rg            = "rg-${local.sanitized_dns_safe}-monitoring"
    log_analytics_workspace  = "log-${local.sanitized_dns_safe}"
    app_insights             = "appi-${local.sanitized_dns_safe}"
    action_group             = "ag-${local.sanitized_dns_safe}-alerts"
  }

  # Backend config for shared bootstrap storage
  # All stamps share the same backend, but use stamp-prefixed state keys
  backend = {
    resource_group_name  = local.bootstrap_rg_name
    storage_account_name = local.bootstrap_storage_name
    container_name       = "tfstate"
    # State key prefixes for each layer
    state_key_prefix     = local.normalized_stamp_id
    networking_key       = "${local.normalized_stamp_id}/networking.tfstate"
    shared_key           = "${local.normalized_stamp_id}/shared.tfstate"
    database_key         = "${local.normalized_stamp_id}/database.tfstate"
    compute_key          = "${local.normalized_stamp_id}/compute.tfstate"
    monitoring_key       = "${local.normalized_stamp_id}/monitoring.tfstate"
  }

  tags = {
    stamp_id    = local.normalized_stamp_id
    environment = try(local.resolved_config.environment, "default")
    managed_by  = "terraform"
  }
}
