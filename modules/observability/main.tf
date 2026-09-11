# Cockpit is the managed Grafana, Mimir and Loki stack. The free plan covers a
# small retention window; ingestion above the included volume is billed, so
# observability is itself a cost line worth watching.
#
# The alert manager here carries technical alerts. Budget alerts are a separate,
# console or API only feature at Organization level, with no Terraform resource.

resource "scaleway_cockpit_source" "metrics" {
  project_id     = var.project_id
  name           = "${var.name}-metrics"
  type           = "metrics"
  region         = var.region
  retention_days = var.metrics_retention_days
}

resource "scaleway_cockpit_alert_manager" "this" {
  project_id = var.project_id
  region     = var.region

  dynamic "contact_points" {
    for_each = var.alert_emails
    content {
      email = contact_points.value
    }
  }
}
