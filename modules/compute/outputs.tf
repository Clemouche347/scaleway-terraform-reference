output "id" {
  value       = scaleway_instance_server.this.id
  description = "Instance ID, zoned form zone/uuid."
}

output "private_ip" {
  value       = try(scaleway_instance_server.this.private_ips[0].address, null)
  description = "First private IP allocated by IPAM."
}

output "public_ip" {
  value       = try(scaleway_instance_ip.this[0].address, null)
  description = "Flexible public IPv4 when enabled."
}
