output "application_id" {
  value       = scaleway_iam_application.finops.id
  description = "IAM application ID."
}

output "access_key" {
  value       = scaleway_iam_api_key.finops.access_key
  description = "API access key."
}

output "secret_key" {
  value       = scaleway_iam_api_key.finops.secret_key
  description = "API secret key. Sensitive, lands in the state file."
  sensitive   = true
}
