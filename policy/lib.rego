# Helpers shared by every policy file.
package lib

import rego.v1

# Resources being created or updated. Deletions and no-ops are ignored, so a
# terraform destroy plan never trips a rule.
changed contains r if {
	some r in input.resource_changes
	r.mode == "managed"
	some action in r.change.actions
	action in {"create", "update"}
}

# An attribute is satisfied either when it has a concrete value in the plan, or
# when Terraform marks it as known only after apply. Module outputs land in the
# second case, and treating them as missing would produce false positives on
# every resource wired to another module.
known(r, attribute) if {
	r.change.after[attribute] != null
}

known(r, attribute) if {
	r.change.after_unknown[attribute] == true
}

# Scaleway tags are a flat list of strings, not a key value map. The convention
# used across this repo is "key:value", which is the closest equivalent.
# Object Storage is the exception and uses a real map.
tag_keys(r) := keys if {
	is_array(r.change.after.tags)
	keys := {k |
		some t in r.change.after.tags
		parts := split(t, ":")
		count(parts) >= 2
		k := parts[0]
	}
}

tag_keys(r) := keys if {
	is_object(r.change.after.tags)
	keys := {k | some k, _ in r.change.after.tags}
}

has_tags(r) if {
	count(r.change.after.tags) > 0
}

# An exemption suppresses one rule for one address, and only until its expiry
# date. An entry without an expires field grants nothing, on purpose.
# Conftest merges a --data file into the document root, so exemptions.yaml
# lands at data.exemptions. The object form is accepted too, in case the file is
# loaded through a different mechanism.
entries := l if {
	is_array(data.exemptions)
	l := data.exemptions
}

entries := l if {
	is_object(data.exemptions)
	l := data.exemptions.exemptions
}

exempt(rule_id, address) if {
	some e in entries
	e.rule == rule_id
	glob.match(e.address, [], address)
	e.expires
	not expired(e)
}

expired(e) if {
	time.parse_rfc3339_ns(concat("", [e.expires, "T00:00:00Z"])) < time.now_ns()
}
