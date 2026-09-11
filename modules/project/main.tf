# Project is the cost allocation unit on Scaleway.
# There is no tag-based cost breakdown: anything you want to read as a separate
# line in Cost Manager or in the FinOps API has to be its own Project.
resource "scaleway_account_project" "this" {
  name            = var.name
  description     = var.description
  organization_id = var.organization_id
}
