# Tagging rules.
#
# Worth being explicit about what these buy you: Scaleway tags are absent from
# billing, so enforcing them does nothing for cost allocation. They serve
# inventory, ownership and automation. The rule that protects allocation is
# ALLOC001, not anything in this file.
package main

import data.lib
import rego.v1

# Deliberately conservative. Add a type here only after checking that the
# provider actually exposes a tags argument on it.
taggable := {
	"scaleway_block_volume",
	"scaleway_instance_ip",
	"scaleway_instance_security_group",
	"scaleway_instance_server",
	"scaleway_k8s_cluster",
	"scaleway_lb",
	"scaleway_object_bucket",
	"scaleway_rdb_instance",
	"scaleway_vpc",
	"scaleway_vpc_private_network",
	"scaleway_vpc_public_gateway",
}

mandatory_tag_keys := {"env", "managed-by", "owner", "stack"}

# key:value, lowercase key, no spaces.
tag_pattern := `^[a-z][a-z0-9-]*:[A-Za-z0-9][A-Za-z0-9._@-]*$`

deny contains msg if {
	some r in lib.changed
	r.type in taggable
	not lib.has_tags(r)
	not lib.exempt("TAG001", r.address)
	msg := sprintf("TAG001 %s has no tags. Expected at least %v.", [r.address, sort(mandatory_tag_keys)])
}

deny contains msg if {
	some r in lib.changed
	r.type in taggable
	is_array(r.change.after.tags)
	some t in r.change.after.tags
	not regex.match(tag_pattern, t)
	not lib.exempt("TAG002", r.address)
	msg := sprintf("TAG002 %s carries the tag %q, which does not follow the key:value convention.", [r.address, t])
}

deny contains msg if {
	some r in lib.changed
	r.type in taggable
	lib.has_tags(r)
	missing := mandatory_tag_keys - lib.tag_keys(r)
	count(missing) > 0
	not lib.exempt("TAG003", r.address)
	msg := sprintf("TAG003 %s is missing the mandatory tag keys %v.", [r.address, sort(missing)])
}
