# Exemption hygiene.
#
# An exemption is a dated decision, not a permanent hole. Entries expire, and an
# expired entry surfaces here so it gets renewed on purpose or deleted.
package main

import data.lib
import rego.v1

warn contains msg if {
	some e in lib.entries
	lib.expired(e)
	msg := sprintf("EXEMPT001 the exemption on %s for rule %s expired on %s. Renew it with a reason or remove it.", [e.address, e.rule, e.expires])
}

warn contains msg if {
	some e in lib.entries
	not e.expires
	msg := sprintf("EXEMPT002 the exemption on %s for rule %s has no expiry date and grants nothing. Add an expires field.", [e.address, e.rule])
}

warn contains msg if {
	some e in lib.entries
	not e.reason
	msg := sprintf("EXEMPT003 the exemption on %s for rule %s has no reason.", [e.address, e.rule])
}
