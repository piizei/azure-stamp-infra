variable "mongodbatlas_public_key" {
  type = string
}

variable "mongodbatlas_private_key" {
  type      = string
  sensitive = true
}

variable "mongodbatlas_org_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
