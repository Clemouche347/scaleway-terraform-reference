# FinOps tooling

## scw_charges.py

Pulls raw charges from the Scaleway Billing FinOps API and prints or exports a
per resource breakdown. Standard library only.

### Auth

Needs an API secret key holding `BillingReadOnly` at Organization level. The
`modules/iam` module in this repo creates exactly that identity.

```bash
export SCW_SECRET_KEY=...
export SCW_DEFAULT_ORGANIZATION_ID=...
```

### Examples

```bash
# Month to date, grouped by project
python3 scw_charges.py --start 2026-09-01 --end 2026-09-30 --group-by project

# Top 20 resources of last month
python3 scw_charges.py --start 2026-08-01 --end 2026-09-01 --group-by resource --top 20

# One project only, raw lines to CSV
python3 scw_charges.py --start 2026-08-01 --end 2026-09-01 \
  --project-id 11111111-1111-1111-1111-111111111111 \
  --out august.csv
```

### Notes

- `--end` is exclusive.
- `clamp_to_time_range=true` is always sent, so a charge spanning the window
  boundary is sliced rather than dropped.
- Prices come back as `google.type.Money`: `units` plus `nanos` divided by 1e9.
- The API is beta and its figures can differ slightly from the invoice.
