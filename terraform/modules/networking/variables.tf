variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = string
}

variable "aks_subnet_cidr" {
  type = string
}

variable "pe_subnet_cidr" {
  type = string
}

variable "aks_subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
}

variable "pe_subnet_name" {
  description = "Name of the Private Endpoint subnet"
  type        = string
}

variable "nsg_name" {
  description = "Name for the AKS subnet network security group"
  type        = string
}

variable "tags" {
  description = "Optional tags applied to networking resources"
  type        = map(string)
  default     = {}
}
