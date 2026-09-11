# Cost drivers on an Instance:
#   1. the Instance type itself, billed per hour while the server is running
#   2. the root volume, billed per GB per month even when the server is stopped
#   3. the flexible IPv4, billed per hour even when detached
#
# Point 3 is the classic Scaleway waste item: a released instance whose IP was
# reserved separately keeps costing money. Keep IPs in Terraform state so they
# are destroyed with the rest.

resource "scaleway_instance_ip" "this" {
  count      = var.enable_public_ip ? 1 : 0
  project_id = var.project_id
  zone       = var.zone
  type       = "routed_ipv4"
  tags       = var.tags
}

resource "scaleway_instance_security_group" "this" {
  name                   = "${var.name}-sg"
  project_id             = var.project_id
  zone                   = var.zone
  inbound_default_policy = "drop"
  # Outbound stays open: egress is free between Scaleway resources and metered
  # only on internet transfer above the monthly allowance.
  outbound_default_policy = "accept"
  tags                    = var.tags

  dynamic "inbound_rule" {
    for_each = var.allowed_inbound_ports
    content {
      action   = "accept"
      port     = inbound_rule.value.port
      ip_range = inbound_rule.value.ip_range
    }
  }
}

resource "scaleway_instance_server" "this" {
  name              = var.name
  type              = var.instance_type
  image             = var.image
  project_id        = var.project_id
  zone              = var.zone
  ip_ids            = var.enable_public_ip ? [scaleway_instance_ip.this[0].id] : []
  security_group_id = scaleway_instance_security_group.this.id
  tags              = var.tags

  root_volume {
    size_in_gb            = var.root_volume_size_gb
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  private_network {
    pn_id = var.private_network_id
  }
}
