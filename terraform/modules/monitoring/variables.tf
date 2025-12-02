variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "application_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
}

variable "action_group_name" {
  description = "Name of the action group for alerts"
  type        = string
}

variable "alert_email_addresses" {
  description = "List of email addresses to notify on alerts"
  type        = list(string)
  default     = []
}

variable "availability_tests" {
  description = "Map of availability tests to create"
  type = map(object({
    name                  = string
    url                   = string
    frequency             = optional(number, 300)  # seconds (default 5 minutes)
    timeout               = optional(number, 120)  # seconds
    enabled               = optional(bool, true)
    expected_status_code  = optional(number, 200)
    ssl_check_enabled     = optional(bool, false)
    geo_locations         = optional(list(string), ["emea-nl-ams-azr", "emea-gb-db3-azr", "emea-se-sto-edge"])
    failed_location_count = optional(number, 2)
    alert_severity        = optional(number, 1)  # 0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose
    alert_enabled         = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
