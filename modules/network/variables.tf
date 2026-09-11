variable "name" {
  type        = string
  description = "Prefix applied to the VPC and private network names."
}

variable "project_id" {
  type        = string
  description = "Scaleway Project ID that owns the network resources."
}

variable "region" {
  type        = string
  description = "Region, for example fr-par."
  default     = "fr-par"
}

variable "zone" {
  type        = string
  description = "Zone used by the public gateway, for example fr-par-1."
  default     = "fr-par-1"
}

variable "ipv4_subnet" {
  type        = string
  description = "CIDR of the private network."
  default     = "172.16.32.0/22"
}

variable "enable_public_gateway" {
  type        = bool
  description = "Deploy a Public Gateway. Billed hourly plus one flexible IPv4. Off by default."
  default     = false
}

variable "public_gateway_type" {
  type        = string
  description = "Public Gateway offer. VPC-GW-S is the smallest."
  default     = "VPC-GW-S"
}

variable "tags" {
  type        = list(string)
  description = "Resource tags. Useful for inventory and automation, ignored by billing."
  default     = []
}
