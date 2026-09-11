output "id" {
  value       = scaleway_lb.this.id
  description = "Load balancer ID."
}

output "ip_address" {
  value       = scaleway_lb_ip.this.ip_address
  description = "Public IP of the load balancer."
}
