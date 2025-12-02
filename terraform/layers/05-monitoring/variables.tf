variable "subscription_id" {
  description = "Azure subscription ID for the stamp resources"
  type        = string
}

variable "stamp_id" {
  description = "Unique identifier for the stamp (e.g., swc-dev, neu-prod)"
  type        = string
}

variable "bootstrap_subscription_id" {
  description = "Azure subscription ID where the bootstrap/state backend is located (defaults to subscription_id if not set)"
  type        = string
  default     = ""
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive alerts"
  type        = list(string)
  default     = []
}

variable "availability_tests" {
  description = "Map of availability tests to create"
  type = map(object({
    name                  = string
    url                   = string
    frequency             = optional(number, 300)
    timeout               = optional(number, 120)
    enabled               = optional(bool, true)
    expected_status_code  = optional(number, 200)
    ssl_check_enabled     = optional(bool, false)
    geo_locations         = optional(list(string), ["emea-nl-ams-azr", "emea-gb-db3-azr", "emea-se-sto-edge"])
    failed_location_count = optional(number, 2)
    alert_severity        = optional(number, 1)
    alert_enabled         = optional(bool, true)
  }))
  default = {}
}
