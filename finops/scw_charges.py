#!/usr/bin/env python3
"""Export Scaleway charges from the Billing FinOps API.

Endpoint: GET https://api.scaleway.com/billing/v2beta1/charges
Docs:     https://www.scaleway.com/en/developers/api/billing_finops/

The FinOps API returns raw consumption with per resource granularity. It is the
closest thing Scaleway has to an AWS Cost and Usage Report. Scaleway states that
the figures may differ slightly from the Consumption API and from the invoice,
because aggregation and rounding are done differently. Reconcile against the
invoice before publishing any number to a finance team.

The API is in beta. Fields and behaviour can change.

Auth: X-Auth-Token header with an API secret key holding BillingReadOnly.

Usage:
    export SCW_SECRET_KEY=...
    export SCW_DEFAULT_ORGANIZATION_ID=...

    python scw_charges.py --start 2026-08-01 --end 2026-09-01 --out charges.csv
    python scw_charges.py --start 2026-08-01 --end 2026-09-01 --group-by project
    python scw_charges.py --start 2026-08-01 --end 2026-09-01 --group-by resource --top 20
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone

API_URL = "https://api.scaleway.com/billing/v2beta1/charges"
PAGE_SIZE = 1000


def money_to_float(price: dict | None) -> float:
    """google.type.Money to float. units are whole currency, nanos are 1e-9."""
    if not price:
        return 0.0
    return float(price.get("units") or 0) + float(price.get("nanos") or 0) / 1e9


def currency_of(price: dict | None) -> str:
    return (price or {}).get("currency_code") or "EUR"


def to_rfc3339(day: str) -> str:
    return datetime.strptime(day, "%Y-%m-%d").replace(tzinfo=timezone.utc).isoformat().replace("+00:00", "Z")


def fetch_charges(secret_key: str, organization_id: str, start: str, end: str,
                  project_ids: list[str] | None = None) -> list[dict]:
    """Page through every charge in the window. clamp_to_time_range keeps
    charges that straddle the boundary, sliced to the requested window."""
    charges: list[dict] = []
    page_token = None

    while True:
        params: list[tuple[str, str]] = [
            ("organization_id", organization_id),
            ("start_date_after", to_rfc3339(start)),
            ("end_date_before", to_rfc3339(end)),
            ("clamp_to_time_range", "true"),
            ("order_by", "start_date_asc"),
            ("page_size", str(PAGE_SIZE)),
        ]
        for pid in project_ids or []:
            params.append(("project_ids", pid))
        if page_token:
            params.append(("page_token", page_token))

        req = urllib.request.Request(
            f"{API_URL}?{urllib.parse.urlencode(params)}",
            headers={"X-Auth-Token": secret_key, "Content-Type": "application/json"},
        )

        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                payload = json.load(resp)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", "replace")
            sys.exit(f"HTTP {exc.code} from the billing API: {body}")

        charges.extend(payload.get("charges") or [])
        page_token = payload.get("next_page_token")
        if not page_token:
            break

    return charges


def group(charges: list[dict], key: str) -> list[tuple[str, float]]:
    keys = {
        "project": lambda c: c.get("project_name") or c.get("project_id") or "unknown",
        "sku": lambda c: c.get("sku") or "unknown",
        "resource": lambda c: c.get("resource_name") or c.get("resource_id") or "unknown",
    }
    if key not in keys:
        raise ValueError(f"unknown grouping: {key}")

    totals: dict[str, float] = defaultdict(float)
    for charge in charges:
        totals[keys[key](charge)] += money_to_float(charge.get("price"))

    return sorted(totals.items(), key=lambda kv: kv[1], reverse=True)


def write_csv(charges: list[dict], path: str) -> None:
    columns = [
        "organization_name", "project_name", "project_id", "sku",
        "resource_id", "resource_name", "amount", "currency",
        "start_date", "end_date", "invoice_id",
    ]
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for charge in charges:
            writer.writerow({
                "organization_name": charge.get("organization_name"),
                "project_name": charge.get("project_name"),
                "project_id": charge.get("project_id"),
                "sku": charge.get("sku"),
                "resource_id": charge.get("resource_id"),
                "resource_name": charge.get("resource_name"),
                "amount": f"{money_to_float(charge.get('price')):.6f}",
                "currency": currency_of(charge.get("price")),
                "start_date": charge.get("start_date"),
                "end_date": charge.get("end_date"),
                "invoice_id": charge.get("invoice_id"),
            })


def main() -> None:
    parser = argparse.ArgumentParser(description="Export Scaleway charges")
    parser.add_argument("--start", required=True, help="inclusive start date, YYYY-MM-DD")
    parser.add_argument("--end", required=True, help="exclusive end date, YYYY-MM-DD")
    parser.add_argument("--project-id", action="append", dest="project_ids",
                        help="restrict to one or more projects, repeatable")
    parser.add_argument("--group-by", choices=["project", "sku", "resource"],
                        help="print an aggregated breakdown")
    parser.add_argument("--top", type=int, default=25, help="rows to print in the breakdown")
    parser.add_argument("--out", help="write the raw charge lines to this CSV file")
    args = parser.parse_args()

    secret_key = os.environ.get("SCW_SECRET_KEY")
    organization_id = os.environ.get("SCW_DEFAULT_ORGANIZATION_ID") or os.environ.get("SCW_ORGANIZATION_ID")
    if not secret_key or not organization_id:
        sys.exit("set SCW_SECRET_KEY and SCW_DEFAULT_ORGANIZATION_ID")

    charges = fetch_charges(secret_key, organization_id, args.start, args.end, args.project_ids)
    if not charges:
        print("no charge returned for this window")
        return

    currency = currency_of(charges[0].get("price"))
    total = sum(money_to_float(c.get("price")) for c in charges)
    print(f"{len(charges)} charge lines, total {total:.2f} {currency}")

    if args.group_by:
        print()
        rows = group(charges, args.group_by)[: args.top]
        width = max(len(name) for name, _ in rows)
        for name, amount in rows:
            share = amount / total * 100 if total else 0
            print(f"{name.ljust(width)}  {amount:10.2f} {currency}  {share:5.1f}%")

    if args.out:
        write_csv(charges, args.out)
        print(f"\nwritten to {args.out}")


if __name__ == "__main__":
    main()
