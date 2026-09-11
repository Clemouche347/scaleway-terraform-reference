variable "name" {
  type        = string
  description = "Project name. Becomes the allocation label in Cost Manager and in the FinOps API (project_name)."
}

variable "description" {
  type        = string
  description = "Free text. Use it to carry owner and cost centre, since Scaleway has no billing tags."
  default     = ""
}

variable "organization_id" {
  type        = string
  description = "Organization the project belongs to. Falls back to the provider organization when null."
  default     = null
}
