module "stamp" {
  source                    = "../../modules/stamp"
  stamp_id                  = var.stamp_id
  subscription_id           = var.subscription_id
  bootstrap_subscription_id = var.bootstrap_subscription_id
}

data "terraform_remote_state" "compute" {
  backend = "azurerm"
  config = {
    resource_group_name  = module.stamp.backend.resource_group_name
    storage_account_name = module.stamp.backend.storage_account_name
    container_name       = module.stamp.backend.container_name
    use_azuread_auth     = true
    key                  = module.stamp.backend.compute_key
  }
}

resource "azurerm_resource_group" "monitoring" {
  name     = "rg-${module.stamp.stamp_id}-monitoring"
  location = module.stamp.location
  tags     = module.stamp.tags
}

# Get the ingress IP from AKS (via data source if available)
# For now, we'll use a variable for the endpoint URL

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name          = azurerm_resource_group.monitoring.name
  location                     = azurerm_resource_group.monitoring.location
  log_analytics_workspace_name = "law-${module.stamp.stamp_id}"
  application_insights_name    = "appi-${module.stamp.stamp_id}"
  action_group_name            = "ag-${module.stamp.stamp_id}-alerts"
  alert_email_addresses        = var.alert_email_addresses
  tags                         = module.stamp.tags

  availability_tests = var.availability_tests
}
