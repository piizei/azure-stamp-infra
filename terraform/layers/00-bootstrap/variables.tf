variable "subscription_id" {
  description = "Subscription where the state resources will be created"
  type        = string
}

variable "stamp_id" {
  description = "Stamp identifier used to derive the backend naming convention"
  type        = string
}
