STACK ?= live/sandbox
CONFTEST ?= conftest

.PHONY: fmt validate plan apply destroy policy policy-selftest costs audit

fmt:
	terraform fmt -recursive

validate:
	cd $(STACK) && terraform init -backend=false && terraform validate

plan:
	cd $(STACK) && terraform plan -out=tfplan

# Run the policies against a real plan. Requires `make plan` first.
policy:
	cd $(STACK) && terraform show -json tfplan > tfplan.json
	$(CONFTEST) test --policy policy --data policy/exemptions.yaml $(STACK)/tfplan.json

# Prove the policies still catch what they are supposed to catch.
policy-selftest:
	$(CONFTEST) test --policy policy --data policy/exemptions.yaml policy/fixtures/compliant_plan.json
	! $(CONFTEST) test --policy policy --data policy/exemptions.yaml policy/fixtures/violating_plan.json

apply:
	cd $(STACK) && terraform apply

destroy:
	cd $(STACK) && terraform destroy

# Month to date cost breakdown by project.
costs:
	python3 finops/scw_charges.py \
		--start $(shell date -u +%Y-%m-01) \
		--end $(shell date -u +%Y-%m-%d) \
		--group-by project

# Tag drift and idle resources on the live account.
audit:
	python3 finops/scw_audit.py
