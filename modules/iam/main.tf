# A read only FinOps identity, scoped at the Organization level because billing
# data is an Organization object, not a Project object.
#
# Permission sets used here:
#   BillingReadOnly      read consumption, invoices, discounts, budget alerts
#   ProjectReadOnly      list projects, needed to resolve project_id to a name
#   AllProductsReadOnly  read resource inventory for mapping and rightsizing
#
# List what is available on your organization with:
#   scw iam permission-set list

resource "scaleway_iam_application" "finops" {
  name            = var.application_name
  description     = "Read only identity used by FinOps tooling and cost exports"
  organization_id = var.organization_id
}

resource "scaleway_iam_policy" "finops_readonly" {
  name            = "${var.application_name}-readonly"
  description     = "Organization wide read access to billing and inventory"
  application_id  = scaleway_iam_application.finops.id
  organization_id = var.organization_id

  rule {
    organization_id      = var.organization_id
    permission_set_names = var.permission_set_names
  }
}

resource "scaleway_iam_api_key" "finops" {
  application_id     = scaleway_iam_application.finops.id
  description        = "FinOps export key"
  default_project_id = var.default_project_id
}
