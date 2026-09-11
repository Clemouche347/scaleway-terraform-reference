# AWS to Scaleway, mapping and gaps

Written for people who already know AWS. The vocabulary translates easily. The
governance model does not.

## The one difference that matters

On AWS you allocate cost with tags, and the account is a secondary boundary.
On Scaleway there is no tag based cost breakdown at all. Tags exist on most
resources, they are useful for inventory and automation, and they are absent
from billing.

The allocation dimension is the **Project**. If two workloads sit in the same
Project, their costs are merged and nothing will separate them after the fact.
Project design is therefore a day one decision, not a cleanup task, and it is
the first thing to look at on any Scaleway cost governance engagement.

Practical consequence: create more Projects than feels natural coming from AWS.
A Project is free, has no quota of its own, and is the only lever you have.

## Vocabulary

| AWS | Scaleway | Notes |
| --- | --- | --- |
| Account | Project | The allocation unit |
| Organization | Organization | Flat, no Organizational Units |
| Service Control Policy | none | No preventive guardrail equivalent |
| IAM user, role, policy | IAM user, application, group, policy | Applications replace machine users |
| STS AssumeRole | none | Applications hold their own API keys |
| Cost allocation tags | none | Tags are not billing dimensions |
| Cost and Usage Report | Billing FinOps API, `/billing/v2beta1/charges` | Beta, per resource granularity |
| Cost Explorer | Cost Manager | Free, filter by category, project, resource type |
| AWS Budgets | Billing alerts | See limits below |
| Savings Plans | Savings Plans | Commitment discount up to 25 percent |
| Reserved Instances | none | Only savings plans |
| Cost Anomaly Detection | none | Build it from the FinOps API |
| Compute Optimizer, Trusted Advisor | none | Rightsizing is manual, Cockpit plus FinOps API |
| CloudWatch | Cockpit | Managed Grafana, Mimir, Loki, Tempo |
| EC2 | Instances | |
| EBS | Block Storage, SBS | |
| S3 | Object Storage | S3 API compatible |
| Glacier | Glacier storage class | |
| VPC, subnet | VPC, Private Network | Regional, IPAM managed |
| NAT Gateway | Public Gateway | Billed appliance plus a flexible IPv4 |
| Security Group | Security Group | |
| ALB, NLB | Load Balancer | Billed per hour from creation |
| RDS | Managed Database for PostgreSQL and MySQL | |
| ElastiCache | Managed Redis | |
| EKS | Kubernetes Kapsule, Kosmos for multi cloud | |
| ECR | Container Registry | |
| Lambda | Serverless Functions | |
| Fargate | Serverless Containers | |
| Route 53 | Domains and DNS | |
| Secrets Manager | Secret Manager | |
| Systems Manager Parameter Store | Secret Manager | |
| Region, Availability Zone | Region, Zone | fr-par, nl-ams, pl-waw |

## Billing alerts, and what they cannot do

Scaleway billing alerts are configured at Organization level. You set a single
monthly budget in euros, then up to ten thresholds expressed as a percentage of
that budget. Notification goes to email, SMS, or a webhook.

What is missing compared to AWS Budgets:

- no budget per Project, only one Organization wide amount
- no forecast based alert, only consumption already recorded
- no budget action, nothing stops or restricts anything
- thresholds are percentages of one shared budget, so changing the budget
  silently changes every alert at once
- the documentation itself describes the alert as a rough estimate of the
  eventual invoice

For anything more granular you build it: a scheduled job hitting the FinOps API,
per project thresholds held in your own configuration, and a webhook or a
Cockpit alert as the output. That gap is usually the deliverable on a Scaleway
cost governance engagement rather than a reason to look elsewhere.

## The FinOps API as a CUR substitute

`GET https://api.scaleway.com/billing/v2beta1/charges` returns individual
charges with organization, project, SKU, resource ID, resource name, price,
start and end date, and invoice ID. Filters exist on project, resource, SKU and
invoice. Pagination is by `next_page_token`. `clamp_to_time_range=true` slices
charges that straddle the window boundary.

Three caveats worth stating to a client before building on it:

1. It is beta. Fields and semantics can move.
2. Scaleway says the numbers can differ slightly from the Consumption API and
   the invoice, because aggregation and rounding differ. Reconcile before
   publishing anything to finance.
3. `resource_name` is only populated when the product sends it. Expect blanks,
   and fall back to `resource_id`.

Compared to a CUR there is no equivalent of `line_item_line_item_type`, so
splitting out tax, credits and fees is not something you can do from this API.
Use the invoice for that.

## Permission sets

Billing is an Organization level object, so a FinOps reader needs an
Organization scoped policy, not a Project scoped one.

- `BillingReadOnly` reads consumption, invoices, discounts, budget alerts and
  payment methods
- `BillingManager` adds write access on contacts, payment details, alerts

List what your organization actually exposes with `scw iam permission-set list`
rather than trusting any static list, including this one.
