# A VPC and a Private Network are free. The Public Gateway is not: it is a
# billed appliance (VPC-GW-S and up) plus a flexible IPv4. Keep it optional so
# the baseline footprint stays close to zero.

resource "scaleway_vpc" "this" {
  name       = "${var.name}-vpc"
  project_id = var.project_id
  tags       = var.tags
  region     = var.region
}

resource "scaleway_vpc_private_network" "this" {
  name       = "${var.name}-pn"
  project_id = var.project_id
  vpc_id     = scaleway_vpc.this.id
  tags       = var.tags
  region     = var.region

  ipv4_subnet {
    subnet = var.ipv4_subnet
  }
}

resource "scaleway_vpc_public_gateway_ip" "this" {
  count      = var.enable_public_gateway ? 1 : 0
  project_id = var.project_id
  zone       = var.zone
  tags       = var.tags
}

resource "scaleway_vpc_public_gateway" "this" {
  count      = var.enable_public_gateway ? 1 : 0
  name       = "${var.name}-gw"
  type       = var.public_gateway_type
  ip_id      = scaleway_vpc_public_gateway_ip.this[0].id
  project_id = var.project_id
  zone       = var.zone
  tags       = var.tags
}

resource "scaleway_vpc_gateway_network" "this" {
  count              = var.enable_public_gateway ? 1 : 0
  gateway_id         = scaleway_vpc_public_gateway.this[0].id
  private_network_id = scaleway_vpc_private_network.this.id
  enable_masquerade  = true
  zone               = var.zone

  ipam_config {
    push_default_route = true
  }
}
