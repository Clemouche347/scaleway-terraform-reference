# Credentials come from the environment:
#   SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_ORGANIZATION_ID
# or from ~/.config/scw/config.yaml.
provider "scaleway" {
  organization_id = var.organization_id
  region          = var.region
  zone            = var.zone
}
