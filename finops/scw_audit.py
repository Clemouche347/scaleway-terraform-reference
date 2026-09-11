#!/usr/bin/env python3
"""Audit live Scaleway resources for tag drift and idle waste.

Why this exists alongside the Conftest policies: those run on a Terraform plan,
so they only see what Terraform manages. Anything created in the console, and
any tag edited there afterwards, is invisible to them. This script reads the
live state through the product APIs instead.

It is detective, not preventive. It reports, it never modifies anything.

Products covered: Instances, flexible IPs, Load Balancers. Extending it means
adding an entry to PRODUCTS below. Endpoint paths are the ones documented at
https://www.scaleway.com/en/developers/api/ and are worth rechecking, since
some products are still on alpha or beta API versions.

Auth: an API secret key with read access on the products audited.

Usage:
    export SCW_SECRET_KEY=...
    export SCW_DEFAULT_ORGANIZATION_ID=...

    python3 scw_audit.py
    python3 scw_audit.py --zone fr-par-1 --zone fr-par-2
    python3 scw_audit.py --required-tags env owner --out findings.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

API_ROOT = "https://api.scaleway.com"
DEFAULT_ZONES = ["fr-par-1", "fr-par-2", "nl-ams-1"]
DEFAULT_REQUIRED_TAGS = ["managed-by", "stack", "env", "owner"]
TAG_PATTERN = re.compile(r"^[a-z][a-z0-9-]*:[A-Za-z0-9][A-Za-z0-9._@-]*$")

PRODUCTS = {
    "instance": {
        "path": "/instance/v1/zones/{zone}/servers",
        "collection": "servers",
        "label": "Instance",
    },
    "flexible_ip": {
        "path": "/instance/v1/zones/{zone}/ips",
        "collection": "ips",
        "label": "Flexible IP",
    },
    "load_balancer": {
        "path": "/lb/v1/zones/{zone}/lbs",
        "collection": "lbs",
        "label": "Load Balancer",
    },
}


def call(path: str, secret_key: str, params: dict[str, str]) -> dict:
    url = f"{API_ROOT}{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"X-Auth-Token": secret_key})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        if exc.code in (403, 404):
            # Product not enabled, or the key lacks permission on it. Skip
            # rather than abort, so a partial audit still returns something.
            return {}
        sys.exit(f"HTTP {exc.code} on {path}: {exc.read().decode('utf-8', 'replace')}")


def list_all(product: dict, zone: str, secret_key: str, organization_id: str) -> list[dict]:
    items: list[dict] = []
    page = 1
    while True:
        payload = call(
            product["path"].format(zone=zone),
            secret_key,
            {"organization": organization_id, "page": str(page), "per_page": "100"},
        )
        batch = payload.get(product["collection"]) or []
        items.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return items


def tag_findings(tags: list[str] | None, required: list[str]) -> list[str]:
    tags = tags or []
    problems = []

    if not tags:
        return ["no tags at all"]

    malformed = [t for t in tags if not TAG_PATTERN.match(t)]
    if malformed:
        problems.append(f"malformed tags: {', '.join(malformed)}")

    present = {t.split(":", 1)[0] for t in tags if ":" in t}
    missing = [k for k in required if k not in present]
    if missing:
        problems.append(f"missing keys: {', '.join(missing)}")

    return problems


def waste_findings(kind: str, item: dict) -> list[str]:
    """Idle resources that are billed regardless. The flexible IP case is the
    single most common source of unnoticed spend on Scaleway."""
    problems = []

    if kind == "flexible_ip" and not item.get("server"):
        problems.append("IP reserved but attached to nothing, billed per hour")

    if kind == "instance" and item.get("state") == "stopped":
        problems.append("instance stopped, volumes still billed, check whether it is needed")

    if kind == "load_balancer" and item.get("status") not in (None, "ready"):
        problems.append(f"load balancer in state {item.get('status')}, still billed per hour")

    return problems


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit live Scaleway resources")
    parser.add_argument("--zone", action="append", dest="zones", help="zone to scan, repeatable")
    parser.add_argument("--required-tags", nargs="*", default=DEFAULT_REQUIRED_TAGS,
                        help="mandatory tag keys")
    parser.add_argument("--out", help="write findings to this CSV file")
    args = parser.parse_args()

    secret_key = os.environ.get("SCW_SECRET_KEY")
    organization_id = os.environ.get("SCW_DEFAULT_ORGANIZATION_ID") or os.environ.get("SCW_ORGANIZATION_ID")
    if not secret_key or not organization_id:
        sys.exit("set SCW_SECRET_KEY and SCW_DEFAULT_ORGANIZATION_ID")

    zones = args.zones or DEFAULT_ZONES
    findings: list[dict] = []
    scanned = 0

    for zone in zones:
        for kind, product in PRODUCTS.items():
            for item in list_all(product, zone, secret_key, organization_id):
                scanned += 1
                problems = tag_findings(item.get("tags"), args.required_tags)
                problems += waste_findings(kind, item)
                for problem in problems:
                    findings.append({
                        "zone": zone,
                        "kind": product["label"],
                        "id": item.get("id"),
                        "name": item.get("name") or item.get("address") or "",
                        "project_id": item.get("project") or item.get("project_id") or "",
                        "finding": problem,
                    })

    print(f"scanned {scanned} resources across {len(zones)} zones")
    print(f"{len(findings)} findings\n")

    for f in findings:
        print(f"[{f['kind']}] {f['name'] or f['id']} ({f['zone']}): {f['finding']}")

    if args.out:
        with open(args.out, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=["zone", "kind", "id", "name", "project_id", "finding"],
            )
            writer.writeheader()
            writer.writerows(findings)
        print(f"\nwritten to {args.out}")

    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
