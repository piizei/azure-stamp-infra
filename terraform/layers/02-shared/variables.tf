variable "subscription_id" {
  description = "Subscription hosting shared services for the stamp"
  type        = string
}

variable "stamp_id" {
  description = "Stamp identifier"
  type        = string
}

variable "bootstrap_subscription_id" {
  description = "Subscription where Terraform state backend lives. Defaults to subscription_id for single-subscription deployments."
  type        = string
  default     = null
}
