# Reference stack.
#
# Three projects, because the Project is the only dimension Scaleway bills on:
#   app     the workload, compute and load balancing
#   data    object storage
#   shared  cross cutting identities and observability
#
# Every resource below carries a project_id explicitly. Relying on the provider
# default project is the fastest way to end up with unallocatable spend.

# Tag convention: a flat list of "key:value" strings, since Scaleway tags are a
# list and not a map. Enforced by policy/tags.rego, which requires managed-by,
# stack, env and owner on every taggable resource.
locals {
  common_tags = [
    "managed-by:terraform",
    "stack:${var.prefix}",
    "env:${var.environment}",
    "owner:${var.owner}",
  ]

  common_tag_map = {
    "managed-by" = "terraform"
    "stack"      = var.prefix
    "env"        = var.environment
    "owner"      = var.owner
  }
}

module "project_app" {
  source          = "../../modules/project"
  name            = "${var.prefix}-app"
  description     = "Workload project. Allocation unit for compute and network spend."
  organization_id = var.organization_id
}

module "project_data" {
  source          = "../../modules/project"
  name            = "${var.prefix}-data"
  description     = "Data project. Allocation unit for object storage spend."
  organization_id = var.organization_id
}

module "project_shared" {
  source          = "../../modules/project"
  name            = "${var.prefix}-shared"
  description     = "Shared services project. Identities and observability."
  organization_id = var.organization_id
}

module "network" {
  source                = "../../modules/network"
  name                  = var.prefix
  project_id            = module.project_app.id
  region                = var.region
  zone                  = var.zone
  enable_public_gateway = var.enable_public_gateway
  tags                  = local.common_tags
}

module "app_server" {
  source             = "../../modules/compute"
  name               = "${var.prefix}-app-01"
  project_id         = module.project_app.id
  zone               = var.zone
  instance_type      = var.instance_type
  private_network_id = module.network.private_network_id
  tags               = concat(local.common_tags, ["role:app"])

  allowed_inbound_ports = [
    { port = 22, ip_range = var.admin_source_cidr },
    { port = 80, ip_range = "0.0.0.0/0" },
  ]
}

module "load_balancer" {
  count              = var.enable_load_balancer ? 1 : 0
  source             = "../../modules/loadbalancer"
  name               = "${var.prefix}-lb"
  project_id         = module.project_app.id
  zone               = var.zone
  private_network_id = module.network.private_network_id
  backend_server_ips = compact([module.app_server.private_ip])
  tags               = concat(local.common_tags, ["role:edge"])
}

module "data_bucket" {
  source                             = "../../modules/storage"
  name                               = "${var.prefix}-data-${var.organization_id}"
  project_id                         = module.project_data.id
  region                             = var.region
  versioning_enabled                 = true
  noncurrent_version_expiration_days = 30
  abort_multipart_after_days         = 7

  # Object Storage is the one product taking a real key value map.
  tags = local.common_tag_map
}

module "finops_identity" {
  source             = "../../modules/iam"
  application_name   = "${var.prefix}-finops-reader"
  organization_id    = var.organization_id
  default_project_id = module.project_shared.id
}

module "observability" {
  source       = "../../modules/observability"
  name         = var.prefix
  project_id   = module.project_shared.id
  region       = var.region
  alert_emails = var.alert_emails
}
