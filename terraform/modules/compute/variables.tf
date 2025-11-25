variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "service_cidr" {
  description = "Service CIDR for the AKS cluster"
  type        = string
}

variable "dns_service_ip" {
  description = "DNS service IP address inside the service CIDR"
  type        = string
}

variable "tenant_id" {
  type = string
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS API server"
  type        = string
}

variable "identity_name" {
  description = "Name of the User Assigned Managed Identity for AKS"
  type        = string
}

variable "key_vault_name_prefix" {
  description = "Prefix used to build a globally unique Key Vault name"
  type        = string
}

variable "aks_vm_size" {
  description = "VM size for AKS default node pool (memory-optimized recommended for JVM)"
  type        = string
  default     = "Standard_E4s_v5"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "aks_max_pods" {
  description = "Maximum number of pods per node (Azure CNI recommended: 30)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to compute resources"
  type        = map(string)
  default     = {}
}
