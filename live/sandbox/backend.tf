# Remote state on Object Storage, which is S3 compatible.
# Create the bucket once, outside of this configuration, then run:
#
#   terraform init \
#     -backend-config="bucket=<your-state-bucket>" \
#     -backend-config="key=sandbox/terraform.tfstate" \
#     -backend-config="region=fr-par" \
#     -backend-config="endpoints={s3=\"https://s3.fr-par.scw.cloud\"}" \
#     -backend-config="access_key=$SCW_ACCESS_KEY" \
#     -backend-config="secret_key=$SCW_SECRET_KEY"
#
# The flags below tell the S3 backend to skip AWS specific calls that Scaleway
# does not implement.
terraform {
  backend "s3" {
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = false
  }
}
