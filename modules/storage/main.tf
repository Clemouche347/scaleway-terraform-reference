# Object Storage is S3 compatible. Two lifecycle rules below are pure FinOps
# hygiene and belong in any governance baseline:
#   - expire non current versions, otherwise versioning silently grows the bill
#   - abort incomplete multipart uploads, which are invisible in the console
#     but billed as stored data

resource "scaleway_object_bucket" "this" {
  name       = var.name
  project_id = var.project_id
  region     = var.region
  tags       = var.tags

  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    id      = "abort-incomplete-multipart-uploads"
    enabled = true

    abort_incomplete_multipart_upload_days = var.abort_multipart_after_days
  }

  lifecycle_rule {
    id      = "expire-noncurrent-versions"
    enabled = var.versioning_enabled

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.transition_to_glacier_days == null ? [] : [1]
    content {
      id      = "transition-to-glacier"
      enabled = true

      transition {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }
  }
}

resource "scaleway_object_bucket_acl" "this" {
  bucket     = scaleway_object_bucket.this.id
  project_id = var.project_id
  acl        = "private"
}
