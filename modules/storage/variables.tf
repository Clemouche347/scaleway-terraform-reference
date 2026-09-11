variable "name" {
  type        = string
  description = "Bucket name. Globally unique per region."
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID."
}

variable "region" {
  type        = string
  description = "Region, for example fr-par."
  default     = "fr-par"
}

variable "versioning_enabled" {
  type        = bool
  description = "Enable versioning. Every version is billed, hence the expiration rule."
  default     = true
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days before a non current version is deleted."
  default     = 30
}

variable "abort_multipart_after_days" {
  type        = number
  description = "Days before an incomplete multipart upload is aborted and its parts released."
  default     = 7
}

variable "transition_to_glacier_days" {
  type        = number
  description = "Days before objects move to Glacier. Null disables the rule."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Bucket tags. Inventory only, no billing effect."
  default     = {}
}
