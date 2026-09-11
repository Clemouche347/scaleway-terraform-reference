# Allocation rules. These are the ones that actually protect the cost model.
#
# On Scaleway the Project is the only dimension billing reports on. A resource
# created without an explicit project_id lands in the provider default project,
# and no amount of later work will separate its cost from everything else there.
package main

import data.lib
import rego.v1

allocatable := {
	"scaleway_block_snapshot",
	"scaleway_block_volume",
	"scaleway_container_namespace",
	"scaleway_function_namespace",
	"scaleway_instance_ip",
	"scaleway_instance_security_group",
	"scaleway_instance_server",
	"scaleway_instance_snapshot",
	"scaleway_k8s_cluster",
	"scaleway_lb",
	"scaleway_lb_ip",
	"scaleway_object_bucket",
	"scaleway_rdb_instance",
	"scaleway_redis_cluster",
	"scaleway_registry_namespace",
	"scaleway_secret",
	"scaleway_vpc",
	"scaleway_vpc_private_network",
	"scaleway_vpc_public_gateway",
	"scaleway_vpc_public_gateway_ip",
}

deny contains msg if {
	some r in lib.changed
	r.type in allocatable
	not lib.known(r, "project_id")
	not lib.exempt("ALLOC001", r.address)
	msg := sprintf(
		"ALLOC001 %s has no explicit project_id. Project is the only cost allocation dimension on Scaleway, and the provider default project produces spend nobody can attribute.",
		[r.address],
	)
}
