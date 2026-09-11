variable "name" {
  type        = string
  description = "Load balancer name."
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID."
}

variable "zone" {
  type        = string
  description = "Zone, for example fr-par-1."
  default     = "fr-par-1"
}

variable "lb_type" {
  type        = string
  description = "Load balancer offer. LB-S is the entry level."
  default     = "LB-S"
}

variable "private_network_id" {
  type        = string
  description = "Optional private network attachment."
  default     = null
}

variable "backend_server_ips" {
  type        = list(string)
  description = "Backend server IPs."
  default     = []
}

variable "backend_port" {
  type        = number
  description = "Backend port."
  default     = 80
}

variable "frontend_port" {
  type        = number
  description = "Frontend listening port."
  default     = 80
}

variable "health_check_uri" {
  type        = string
  description = "HTTP health check path."
  default     = "/"
}

variable "tags" {
  type        = list(string)
  description = "Resource tags. Inventory only, no billing effect."
  default     = []
}
