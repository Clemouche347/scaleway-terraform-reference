output "vpc_id" {
  value       = scaleway_vpc.this.id
  description = "VPC ID."
}

output "private_network_id" {
  value       = scaleway_vpc_private_network.this.id
  description = "Private network ID, to attach instances and managed services."
}

output "public_gateway_id" {
  value       = try(scaleway_vpc_public_gateway.this[0].id, null)
  description = "Public gateway ID when enabled, null otherwise."
}
