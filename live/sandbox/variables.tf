variable "organization_id" {
  type        = string
  description = "Scaleway Organization ID."
}

variable "region" {
  type        = string
  description = "Default region."
  default     = "fr-par"
}

variable "zone" {
  type        = string
  description = "Default zone."
  default     = "fr-par-1"
}

variable "prefix" {
  type        = string
  description = "Prefix applied to every resource name."
  default     = "ref"
}

variable "alert_emails" {
  type        = list(string)
  description = "Recipients for Cockpit technical alerts."
  default     = []
}

variable "enable_load_balancer" {
  type        = bool
  description = "Deploy the load balancer. This is the largest fixed cost line of the stack."
  default     = true
}

variable "enable_public_gateway" {
  type        = bool
  description = "Deploy a public gateway in the app project."
  default     = false
}

variable "instance_type" {
  type        = string
  description = "Instance offer used by the app server."
  default     = "PLAY2-PICO"
}

variable "admin_source_cidr" {
  type        = string
  description = "Source range allowed to reach SSH. Narrow this to your own address."
  default     = "0.0.0.0/0"
}

variable "owner" {
  type        = string
  description = "Team or person accountable for the stack. Enforced as a mandatory tag by policy TAG003."
  default     = "platform"
}

variable "environment" {
  type        = string
  description = "Environment name. Enforced as a mandatory tag by policy TAG003."
  default     = "sandbox"
}
