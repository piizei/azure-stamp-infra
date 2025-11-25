resource "mongodbatlas_project" "this" {
  name   = var.project_name
  org_id = var.mongodbatlas_org_id
}

resource "mongodbatlas_cluster" "this" {
  project_id = mongodbatlas_project.this.id
  name       = var.cluster_name

  # Provider Settings "block"
  provider_name = "TENANT"
  backing_provider_name = "AZURE"
  provider_region_name = "EUROPE_WEST"
  provider_instance_size_name = "M0"
}

resource "mongodbatlas_database_user" "this" {
  username           = var.db_username
  password           = var.db_password
  project_id         = mongodbatlas_project.this.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}
