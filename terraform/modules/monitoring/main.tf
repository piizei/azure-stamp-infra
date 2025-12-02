# Monitoring module - Application Insights availability tests and alerts

# Log Analytics Workspace (required for workspace-based Application Insights)
resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights (workspace-based)
resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}

# Action Group for alerts (email notification)
resource "azurerm_monitor_action_group" "alerts" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "alerts"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# Standard Availability Test for each endpoint
resource "azurerm_application_insights_standard_web_test" "endpoints" {
  for_each = var.availability_tests

  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = azurerm_application_insights.this.id
  
  geo_locations = each.value.geo_locations
  frequency     = each.value.frequency
  timeout       = each.value.timeout
  enabled       = each.value.enabled
  retry_enabled = true

  request {
    url                              = each.value.url
    http_verb                        = "GET"
    parse_dependent_requests_enabled = false
  }

  validation_rules {
    expected_status_code = each.value.expected_status_code
    ssl_check_enabled    = each.value.ssl_check_enabled
  }

  tags = merge(var.tags, {
    "hidden-link:${azurerm_application_insights.this.id}" = "Resource"
  })
}

# Metric Alert for availability test failures
resource "azurerm_monitor_metric_alert" "availability" {
  for_each = var.availability_tests

  name                = "alert-${each.value.name}"
  resource_group_name = var.resource_group_name
  # Both web test and App Insights must be in scopes for availability alerts
  scopes = [
    azurerm_application_insights.this.id,
    azurerm_application_insights_standard_web_test.endpoints[each.key].id
  ]
  description = "Alert when ${each.value.name} availability test fails from ${each.value.failed_location_count} or more locations"
  severity    = each.value.alert_severity
  frequency   = "PT1M"
  window_size = "PT5M"
  enabled     = each.value.alert_enabled

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.endpoints[each.key].id
    component_id          = azurerm_application_insights.this.id
    failed_location_count = each.value.failed_location_count
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }

  tags = merge(var.tags, {
    "hidden-link:${azurerm_application_insights.this.id}"                                   = "Resource"
    "hidden-link:${azurerm_application_insights_standard_web_test.endpoints[each.key].id}" = "Resource"
  })
}
