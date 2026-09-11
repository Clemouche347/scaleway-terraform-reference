# Cost rules. Each one maps to a waste pattern listed in docs/cost-governance.md.
package main

import data.lib
import rego.v1

# Offers that should never appear by accident in a reference or sandbox stack.
expensive_offer_prefixes := ["GPU-", "H100", "L40S", "RENDER-", "POP2-HM", "POP2-HC"]

deny contains msg if {
	some r in lib.changed
	r.type == "scaleway_instance_server"
	some prefix in expensive_offer_prefixes
	startswith(r.change.after.type, prefix)
	not lib.exempt("COST001", r.address)
	msg := sprintf("COST001 %s uses the offer %q, which is on the restricted list. Request an exemption with an expiry date if this is intentional.", [r.address, r.change.after.type])
}

deny contains msg if {
	some r in lib.changed
	r.type == "scaleway_instance_server"
	some volume in r.change.after.root_volume
	volume.delete_on_termination != true
	not lib.exempt("COST002", r.address)
	msg := sprintf("COST002 %s keeps its root volume after termination. Block storage is billed per GB per month whether or not a server is attached.", [r.address])
}

deny contains msg if {
	some r in lib.changed
	r.type == "scaleway_object_bucket"
	not aborts_multipart(r)
	not lib.exempt("COST003", r.address)
	msg := sprintf("COST003 %s has no lifecycle rule aborting incomplete multipart uploads. Orphaned parts are invisible in the console and billed as stored data.", [r.address])
}

deny contains msg if {
	some r in lib.changed
	r.type == "scaleway_object_bucket"
	versioning_enabled(r)
	not expires_noncurrent(r)
	not lib.exempt("COST004", r.address)
	msg := sprintf("COST004 %s enables versioning with no expiration on non current versions. Storage then grows without bound.", [r.address])
}

warn contains msg if {
	some r in lib.changed
	r.type in {"scaleway_lb", "scaleway_vpc_public_gateway"}
	"create" in r.change.actions
	msg := sprintf("COST005 %s is a fixed hourly cost billed from creation regardless of traffic. Confirm it is needed for the whole life of the stack.", [r.address])
}

warn contains msg if {
	some r in lib.changed
	r.type in {"scaleway_instance_ip", "scaleway_lb_ip", "scaleway_vpc_public_gateway_ip"}
	"create" in r.change.actions
	msg := sprintf("COST006 %s reserves a flexible IPv4, billed per hour including while detached. Keep it in Terraform state so destroy releases it.", [r.address])
}

aborts_multipart(r) if {
	some rule in r.change.after.lifecycle_rule
	rule.enabled == true
	rule.abort_incomplete_multipart_upload_days > 0
}

versioning_enabled(r) if {
	some v in r.change.after.versioning
	v.enabled == true
}

expires_noncurrent(r) if {
	some rule in r.change.after.lifecycle_rule
	rule.enabled == true
	some expiration in rule.noncurrent_version_expiration
	expiration.noncurrent_days > 0
}
