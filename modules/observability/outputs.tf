output "metrics_source_url" {
  value       = scaleway_cockpit_source.metrics.url
  description = "Metrics data source URL."
}

output "alert_manager_url" {
  value       = scaleway_cockpit_alert_manager.this.alert_manager_url
  description = "Alert manager URL."
}
