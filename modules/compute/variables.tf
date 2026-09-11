variable "name" {
  type        = string
  description = "Instance name."
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

variable "instance_type" {
  type        = string
  description = "Instance offer. PLAY2-PICO and DEV1-S sit at the bottom of the catalogue."
  default     = "PLAY2-PICO"
}

variable "image" {
  type        = string
  description = "Image label or ID."
  default     = "ubuntu_jammy"
}

variable "root_volume_size_gb" {
  type        = number
  description = "Root volume size in GB. Billed per GB per month whatever the server state."
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "Root volume type. sbs_volume is Block Storage, l_ssd is local storage bundled with some offers."
  default     = "sbs_volume"
}

variable "enable_public_ip" {
  type        = bool
  description = "Attach a flexible IPv4. Billed per hour, including when detached."
  default     = true
}

variable "private_network_id" {
  type        = string
  description = "Private network to attach the instance to."
}

variable "allowed_inbound_ports" {
  type = list(object({
    port     = number
    ip_range = string
  }))
  description = "Inbound rules. Default policy is drop."
  default     = []
}

variable "tags" {
  type        = list(string)
  description = "Resource tags. Inventory only, no billing effect."
  default     = []
}
