# Cost governance baseline on Scaleway

A checklist, and what part of it Terraform can carry.

## What Terraform can hold

| Control | Resource | In this repo |
| --- | --- | --- |
| Allocation model | `scaleway_account_project` | `modules/project` |
| Read only FinOps identity | `scaleway_iam_application`, `scaleway_iam_policy`, `scaleway_iam_api_key` | `modules/iam` |
| Storage lifecycle, waste removal | `scaleway_object_bucket` lifecycle rules | `modules/storage` |
| Technical alerting | `scaleway_cockpit_alert_manager` | `modules/observability` |
| Explicit project attribution | `project_id` on every resource | `live/sandbox` |

## What Terraform cannot hold

- **Billing alerts.** Console or Billing API only. No provider resource.
- **Savings plans.** Purchased in the console.
- **Preventive guardrails.** There is no SCP equivalent, so a policy such as
  "no GPU instance in the sandbox" has to be enforced in CI, not in the cloud.
- **Quotas.** Raised through support, not declaratively.

This is the honest boundary. On an engagement, the operating model has to cover
these four by process, and the process has to be written down, because nothing
in the platform will enforce it.

## Allocation

1. One Project per thing you will ever want to see as its own number: per
   environment, per team, per client, per product. Retrofitting is impossible.
2. Encode owner and cost centre in the Project description. It is the only
   metadata field that follows the Project into the billing views.
3. Set `project_id` explicitly on every resource. The provider default project
   is how unallocatable spend appears.
4. Name Projects with a stable convention. `project_name` is what you will be
   grouping on in every report.

## Detection

Scaleway ships no anomaly detection and no rightsizing advisor, so build a
minimal loop:

- daily pull of `/billing/v2beta1/charges` for the current month
- store the raw lines, they are the only per resource history you will have
- compare each project against its own expected run rate
- alert through the Cockpit alert manager or a webhook

`finops/scw_charges.py` in this repo is the pull step.

## Recurring waste items

Ranked by how often they show up rather than by amount.

1. **Flexible IPv4 reserved and detached.** Billed per hour whether or not
   anything uses it. Deleting a server does not release an IP created
   separately. First thing to audit.
2. **Volumes surviving their instance.** Block storage is billed per GB per
   month independently of the server state. `delete_on_termination` on the root
   volume, and an inventory pass on orphan volumes.
3. **Snapshots and images with no retention.** Nothing expires them by default.
4. **Incomplete multipart uploads.** Invisible in the console, billed as stored
   data. One lifecycle rule fixes it, see `modules/storage`.
5. **Non current object versions.** Versioning without expiration grows without
   bound.
6. **Load balancers and public gateways left running.** Fixed hourly cost with
   zero traffic. The largest single line in most small footprints.
7. **Stopped instances still billed.** Depending on the offer and the volume
   type, a stopped server is not a free server. Verify per offer rather than
   assuming AWS semantics.
8. **Cockpit ingestion.** Observability above the included volume is metered.
   A verbose log pipeline is a cost line.

## Rightsizing

There is no advisor, so the inputs are Cockpit metrics on one side and FinOps
API charges on the other, joined on `resource_id`. Practical sequence:

1. Pull per resource cost for a full month.
2. Sort descending, stop at whatever covers 80 percent of the bill. That is
   usually a handful of resources.
3. For each, pull CPU, memory and network from Cockpit over the same window.
4. Compare against the offer catalogue and propose one step down where
   utilisation stays low at the peak, not at the average.
5. Only then look at savings plans, and only for what survives the resize.
   Committing to an oversized footprint locks in the waste for the term.

Step 5 in that order matters. Commitment discounts on Scaleway reach 25 percent,
while a wrong instance size routinely costs more than that.
