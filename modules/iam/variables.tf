variable "application_name" {
  type        = string
  description = "Name of the IAM application."
  default     = "finops-reader"
}

variable "organization_id" {
  type        = string
  description = "Organization ID. Billing lives at this level, not at project level."
}

variable "default_project_id" {
  type        = string
  description = "Default project attached to the API key."
  default     = null
}

variable "permission_set_names" {
  type        = list(string)
  description = "Permission sets granted to the application."
  default     = ["BillingReadOnly", "ProjectReadOnly", "AllProductsReadOnly"]
}
