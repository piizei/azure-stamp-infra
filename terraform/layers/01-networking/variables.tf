variable "subscription_id" {
  description = "Subscription that hosts the networking resources for the stamp"
  type        = string
}

variable "stamp_id" {
  description = "Stamp identifier that drives naming and configuration"
  type        = string
}

variable "bootstrap_subscription_id" {
  description = "Subscription where Terraform state backend lives. Defaults to subscription_id for single-subscription deployments."
  type        = string
  default     = null
}
