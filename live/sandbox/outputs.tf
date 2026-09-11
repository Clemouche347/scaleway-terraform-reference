output "project_ids" {
  value = {
    app    = module.project_app.id
    data   = module.project_data.id
    shared = module.project_shared.id
  }
  description = "Project IDs, the keys used to read cost per allocation unit."
}

output "app_server_public_ip" {
  value       = module.app_server.public_ip
  description = "Public IPv4 of the app server."
}

output "load_balancer_ip" {
  value       = try(module.load_balancer[0].ip_address, null)
  description = "Public IP of the load balancer when enabled."
}

output "bucket_endpoint" {
  value       = module.data_bucket.endpoint
  description = "Object storage endpoint."
}

output "finops_access_key" {
  value       = module.finops_identity.access_key
  description = "Access key of the read only FinOps identity."
}

output "finops_secret_key" {
  value       = module.finops_identity.secret_key
  description = "Secret key of the read only FinOps identity."
  sensitive   = true
}
