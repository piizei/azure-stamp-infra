variable "stamp_id" {
  description = "Logical identifier for the stamp (for example, weu or neu)."
  type        = string
}

variable "subscription_id" {
  description = "Optional subscription identifier used to salt globally unique resource names"
  type        = string
  default     = ""
}
