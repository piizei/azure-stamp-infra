output "connection_string" {
  value     = mongodbatlas_cluster.this.connection_strings[0].standard_srv
  sensitive = true
}

output "project_id" {
  value = mongodbatlas_project.this.id
}
