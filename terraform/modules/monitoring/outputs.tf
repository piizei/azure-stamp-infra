output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.this.id
}

output "instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "action_group_id" {
  description = "ID of the action group"
  value       = azurerm_monitor_action_group.alerts.id
}

output "availability_test_ids" {
  description = "Map of availability test IDs"
  value       = { for k, v in azurerm_application_insights_standard_web_test.endpoints : k => v.id }
}
