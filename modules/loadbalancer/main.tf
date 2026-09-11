# The Load Balancer is the most predictable fixed cost in this reference: it is
# billed per hour from creation to deletion, whatever the traffic. That makes it
# a good marker to check that budget alerts and the FinOps export actually work.

resource "scaleway_lb_ip" "this" {
  project_id = var.project_id
  zone       = var.zone
}

resource "scaleway_lb" "this" {
  name       = var.name
  project_id = var.project_id
  zone       = var.zone
  type       = var.lb_type
  ip_ids     = [scaleway_lb_ip.this.id]
  tags       = var.tags

  dynamic "private_network" {
    for_each = var.private_network_id == null ? [] : [1]
    content {
      private_network_id = var.private_network_id
    }
  }
}

resource "scaleway_lb_backend" "this" {
  lb_id            = scaleway_lb.this.id
  name             = "${var.name}-backend"
  forward_protocol = "http"
  forward_port     = var.backend_port
  server_ips       = var.backend_server_ips

  health_check_http {
    uri = var.health_check_uri
  }
}

resource "scaleway_lb_frontend" "this" {
  lb_id        = scaleway_lb.this.id
  backend_id   = scaleway_lb_backend.this.id
  name         = "${var.name}-frontend"
  inbound_port = var.frontend_port
}
