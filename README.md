# scaleway-terraform-reference

A Terraform reference for Scaleway, written from a cost governance angle.

Small, readable modules for the resources you actually meet on a Scaleway
footprint, a root stack that wires them into a working multi project layout,
a mapping of AWS vocabulary and concepts, and a FinOps exporter for the Billing
FinOps API.

The bias throughout: **the Project is the only cost allocation dimension on
Scaleway**. Tags exist and are ignored by billing. Everything in this repo is
arranged around that constraint.

## Layout

```
modules/
  project         Account project, the allocation unit
  network         VPC, private network, optional public gateway
  compute         Instance, security group, flexible IP
  storage         Object bucket with lifecycle rules that remove billed waste
  loadbalancer    Load balancer, backend, frontend
  iam             Read only FinOps application, policy and API key
  observability   Cockpit data source, alert manager, Grafana user
live/
  sandbox         Root stack, three projects, one small workload
policy/
  *.rego          Conftest policies run on the plan JSON
  exemptions.yaml Dated, documented rule exemptions
  fixtures/       Compliant and violating plans, so the rules are tested
finops/
  scw_charges.py  Charge exporter and breakdown, zero dependencies
  scw_audit.py    Tag drift and idle resource audit on the live account
docs/
  aws-to-scaleway.md   Vocabulary map and the gaps that have no equivalent
  cost-governance.md   Baseline checklist, waste items, rightsizing sequence
  policy.md            Rule reference and the exemption model
```

## Requirements

- Terraform 1.5 or later, or OpenTofu
- Scaleway provider 2.70 or later
- A Scaleway API key with permission to create projects at Organization level

## Usage

```bash
cd live/sandbox
cp terraform.tfvars.example terraform.tfvars   # then edit it

export SCW_ACCESS_KEY=...
export SCW_SECRET_KEY=...
export SCW_DEFAULT_ORGANIZATION_ID=...

terraform init -backend=false    # or configure the S3 backend, see backend.tf
terraform plan
terraform apply
```

`terraform destroy` removes everything, including the flexible IPs, which is the
point of keeping them in state.

## What the root stack costs

The stack is deliberately small but not free, because a governance baseline that
generates no charge cannot be verified.

| Component | Billing shape | Toggle |
| --- | --- | --- |
| Instance, PLAY2-PICO | per hour while running | `instance_type` |
| Root volume, 20 GB SBS | per GB per month, whatever the server state | `root_volume_size_gb` |
| Flexible IPv4 | per hour, including when detached | `enable_public_ip` |
| Load balancer, LB-S | per hour from creation, traffic independent | `enable_load_balancer` |
| Object bucket | per GB stored, near zero when empty | always on |
| VPC, private network | free | always on |
| Public gateway | per hour plus one IPv4 | `enable_public_gateway`, off by default |
| Cockpit | free plan, ingestion above the allowance is metered | always on |

Order of magnitude for the defaults: low tens of euros per month, dominated by
the load balancer. Check current prices before relying on any figure, Scaleway
revised part of its catalogue upward on 1 June 2026.

Set `enable_load_balancer = false` to bring the footprint down to a few euros.

## Policy as code

Conftest policies run on the plan JSON and block a pull request on anything that
breaks the cost model. Full reference in `docs/policy.md`.

```bash
make plan          # writes live/sandbox/tfplan
make policy        # evaluates the rules against it
make policy-selftest   # proves the rules still catch what they should
```

The rule that matters is ALLOC001: every resource must set `project_id`
explicitly, because Project is the only dimension Scaleway bills on and the
provider default project produces spend nobody can attribute. The tag rules
(TAG001 to TAG003) buy inventory and ownership, not allocation, since Scaleway
tags are absent from billing.

Exemptions live in `policy/exemptions.yaml`, carry a reason and an expiry date,
and grant nothing without one.

## FinOps export

```bash
export SCW_SECRET_KEY=...
export SCW_DEFAULT_ORGANIZATION_ID=...

python3 finops/scw_charges.py --start 2026-08-01 --end 2026-09-01 --group-by project
python3 finops/scw_charges.py --start 2026-08-01 --end 2026-09-01 --group-by resource --top 20
python3 finops/scw_charges.py --start 2026-08-01 --end 2026-09-01 --out charges.csv
```

Standard library only, no dependencies. It calls
`GET /billing/v2beta1/charges`, pages through the results, and prints or writes
a per resource breakdown.

The FinOps API is in beta and Scaleway states its figures can diverge slightly
from the invoice. Reconcile before publishing numbers to anyone in finance.

## Audit

Policies see only what Terraform manages. `finops/scw_audit.py` reads the live
account instead, and reports tag drift, detached flexible IPs and stopped
instances still carrying billed volumes.

```bash
python3 finops/scw_audit.py --zone fr-par-1
```

## Known limits

- Billing alerts have no Terraform resource. Console or Billing API only, one
  Organization wide monthly budget, up to ten percentage thresholds, no
  forecast, no automated action. Details in `docs/aws-to-scaleway.md`.
- Savings plans are purchased in the console.
- Resource names on some products do not reach the billing API, so
  `resource_name` can be empty.
- There is no Service Control Policy equivalent, so the policies here gate the
  Terraform path only. Nothing stops a console user creating an untagged
  resource in the default project.
- The Scaleway provider moves quickly. Attribute names in a few resources,
  notably object bucket lifecycle blocks and Cockpit, have shifted across minor
  versions. Run `terraform validate` against your pinned version before
  reporting an issue.

## Contributing

Modules stay small and single purpose. Every cost relevant argument carries a
comment explaining the billing shape, not just the syntax. Pull requests adding
a service are welcome if they follow that pattern.

## License

MIT.
