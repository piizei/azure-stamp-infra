variable "stamp_id" {
  description = "Logical identifier for the stamp (for example, swc-dev or neu-prod)."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID where stamp resources will be deployed."
  type        = string
}

variable "bootstrap_subscription_id" {
  description = "Azure subscription ID where the Terraform state backend lives. Defaults to subscription_id if not specified."
  type        = string
  default     = null
}
