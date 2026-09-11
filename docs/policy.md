# Policy as code

Three layers, because no single one covers the ground.

| Layer | Runs on | Catches | Blocks |
| --- | --- | --- | --- |
| `validation` blocks in modules | plan | bad input to a module | yes, but only for code using the modules |
| Conftest on the plan JSON | pull request | anything Terraform is about to create | yes |
| `finops/scw_audit.py` | schedule | drift and console created resources | no, reports only |

The second layer is the one that matters. The third exists because the second
is blind to everything created outside Terraform, which on a real account is
never zero.

## Running the policies

```bash
cd live/sandbox
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
cd ../..

conftest test --policy policy --data policy/exemptions.yaml live/sandbox/tfplan.json
```

Or `make plan && make policy`.

No credentials are needed to evaluate the policies themselves, only to produce
the plan. That is why CI runs them against the fixtures in `policy/fixtures/`
rather than against a live plan.

## Rules

### Allocation

| ID | Severity | Rule |
| --- | --- | --- |
| ALLOC001 | deny | Every resource that accepts a `project_id` must set one explicitly |

This is the only rule that protects the cost model. Scaleway bills on Project
and nothing else, so a resource landing in the provider default project becomes
spend that cannot be attributed to anyone, ever, retroactively or otherwise.

The rule accepts a `project_id` that Terraform marks as known only after apply,
which is what a module output looks like at plan time. Without that, every
resource wired to the `project` module would trip it.

### Tags

| ID | Severity | Rule |
| --- | --- | --- |
| TAG001 | deny | Taggable resources carry at least one tag |
| TAG002 | deny | Tags follow the `key:value` convention |
| TAG003 | deny | Tags include `env`, `managed-by`, `owner`, `stack` |

Scaleway tags are a flat `list(string)`, not a key value map, and Object Storage
is the exception that takes a real map. The `key:value` convention is a
workaround for that, not a platform feature, and it is worth saying out loud on
an engagement: tags here buy you inventory and ownership, not cost allocation.

### Cost

| ID | Severity | Rule |
| --- | --- | --- |
| COST001 | deny | No GPU or high memory offer without an exemption |
| COST002 | deny | Root volumes set `delete_on_termination` |
| COST003 | deny | Buckets abort incomplete multipart uploads |
| COST004 | deny | Buckets with versioning expire non current versions |
| COST005 | warn | Load balancers and public gateways are fixed hourly costs |
| COST006 | warn | Flexible IPs are billed while detached |

The two warnings are deliberate. Neither resource is wrong to create, both are
routinely forgotten, and a warning that appears in a pull request is the cheapest
possible moment to reconsider.

## Exemptions

`policy/exemptions.yaml`:

```yaml
exemptions:
  - rule: COST001
    address: module.training.scaleway_instance_server.this
    reason: Model training bench, approved by the platform team for Q4
    expires: 2026-12-31
```

Four fields, all required in practice:

- `rule` the ID as printed by conftest
- `address` a Terraform address, glob wildcards allowed
- `reason` one sentence, for whoever reads this in six months
- `expires` `YYYY-MM-DD`, and an entry without it grants nothing at all

Once the date passes, the rule fires again and `EXEMPT001` warns that the
exemption lapsed. `EXEMPT002` and `EXEMPT003` flag entries with no expiry and no
reason.

This shape is the whole point. Every enforcement mechanism gets bypassed the
first time it blocks something legitimate at a bad moment, and if the only
available bypass is deleting the rule, the rule gets deleted and never comes
back. A dated, documented, visible exemption is what keeps the rule alive.

## Adding a rule

1. Write it in the matching file under `policy/`, in `package main`.
2. Give it an ID and make the message say why it costs money, not just what is
   wrong. The message is what a developer reads in a failed pull request.
3. Add a case to `policy/fixtures/violating_plan.json`.
4. Run `make policy-selftest`. The compliant fixture must pass and the violating
   one must fail.

Rules land as `warn` first. Promote to `deny` once the existing footprint is
clean, otherwise the first pull request after the merge is blocked by something
nobody introduced.

## What this cannot do

Scaleway has no Service Control Policy equivalent, so none of this is a
preventive control at the platform level. Anyone with console access and the
right IAM permissions can create an untagged GPU instance in the default project,
and no policy in this repository will stop them. The controls here are
gatekeeping on the Terraform path plus detection everywhere else.

Saying so plainly is part of the deliverable. A governance document that implies
the platform enforces something it does not is worse than no document.
