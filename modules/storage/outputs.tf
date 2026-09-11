output "id" {
  value       = scaleway_object_bucket.this.id
  description = "Bucket ID, region/name form."
}

output "name" {
  value       = scaleway_object_bucket.this.name
  description = "Bucket name."
}

output "endpoint" {
  value       = scaleway_object_bucket.this.endpoint
  description = "Bucket endpoint."
}
