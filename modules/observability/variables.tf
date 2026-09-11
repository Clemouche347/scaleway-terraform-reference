variable "name" {
  type        = string
  description = "Prefix for the Cockpit data sources."
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID. Cockpit is scoped per project."
}

variable "region" {
  type        = string
  description = "Region, for example fr-par."
  default     = "fr-par"
}

variable "alert_emails" {
  type        = list(string)
  description = "Contact points receiving technical alerts."
  default     = []
}

variable "metrics_retention_days" {
  type        = number
  description = "Metrics retention. Longer retention costs more, and the free plan caps what is included."
  default     = 31
}
