output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "The ID of the Application Insights resource"
  value       = module.monitoring.application_insights_id
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key for Application Insights"
  value       = module.monitoring.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The Connection String for Application Insights"
  value       = module.monitoring.connection_string
  sensitive   = true
}

output "availability_test_ids" {
  description = "Map of availability test names to their IDs"
  value       = module.monitoring.availability_test_ids
}

output "action_group_id" {
  description = "The ID of the Action Group for alerts"
  value       = module.monitoring.action_group_id
}
