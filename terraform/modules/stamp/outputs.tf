output "stamp_id" {
  value = local.normalized_stamp_id
}

output "location" {
  value = local.resolved_config.location
}

output "networking" {
  value = {
    address_space   = local.resolved_config.address_space
    aks_subnet_cidr = local.resolved_config.aks_subnet_cidr
    pe_subnet_cidr  = local.resolved_config.pe_subnet_cidr
  }
}

output "aks" {
  value = {
    service_cidr   = local.resolved_config.service_cidr
    dns_service_ip = local.resolved_config.dns_service_ip
    vm_size        = try(local.resolved_config.aks_vm_size, "Standard_D2s_v5")
    node_count     = try(local.resolved_config.aks_node_count, 2)
    max_pods       = try(local.resolved_config.aks_max_pods, 30)
  }
}

output "user_nodepool" {
  value = {
    enabled    = try(local.resolved_config.user_nodepool.enabled, false)
    vm_size    = try(local.resolved_config.user_nodepool.vm_size, "Standard_E4s_v5")
    node_count = try(local.resolved_config.user_nodepool.node_count, 2)
    max_pods   = try(local.resolved_config.user_nodepool.max_pods, 30)
  }
}

output "environment" {
  value = try(local.resolved_config.environment, "default")
}

output "service_bus" {
  value = {
    capacity   = local.resolved_config.service_bus_capacity
    partitions = local.resolved_config.service_bus_partitions
  }
}

output "naming" {
  value = local.naming
}

output "backend" {
  value = local.backend
}

output "tags" {
  value = local.tags
}

output "shared" {
  value = local.shared_config
}
