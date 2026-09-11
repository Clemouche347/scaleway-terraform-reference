output "id" {
  value       = scaleway_account_project.this.id
  description = "Project ID, passed as project_id to every other resource."
}

output "name" {
  value       = scaleway_account_project.this.name
  description = "Project name."
}
