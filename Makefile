# Set envs that must be defined before including tardigrade-ci
SHELL := /bin/bash

TERRAFORM_VERSION ?= $(shell grep terraform-version $${PWD}/tardigrade/vendor/versions.tf | grep -oE '[0-9]+(\.[0-9]+){1,2}')

include $(shell test -f .tardigrade-ci || curl -sSL -o .tardigrade-ci "https://raw.githubusercontent.com/plus3it/tardigrade-ci/master/bootstrap/Makefile.bootstrap"; echo .tardigrade-ci)

terraform/% terraform-bundle/%: TF_VENDOR_DIR ?= $(PWD)/tardigrade/vendor

## Vendors external modules to tardigrade/vendor/.terraform
terraform/vendor: | guard/program/terraform
	terraform -chdir=$(TF_VENDOR_DIR) init -backend=false -lock=false
	rm -rf $(TF_VENDOR_DIR)/.terraform/providers
	find $(TF_VENDOR_DIR) -depth -type d \( -name "tests" -o -name "examples" -o -name ".github" -o -name ".git" \) -exec rm -rf {} +

## Locks terraform providers for multiple platforms
terraform/lock: | guard/program/terraform
	@ echo "[$@]: Locking terraform providers..."
	rm -f $(TF_VENDOR_DIR)/.terraform.lock.hcl
	terraform -chdir=$(TF_VENDOR_DIR) init -upgrade -backend=false -lock=false
	terraform -chdir=$(TF_VENDOR_DIR) providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=windows_amd64 -platform=linux_arm64
	@ echo "[$@]: Completed successfully!"

## Validates terraform roots (requires vendored modules)
terraform/validate-roots: terraform/vendor | guard/program/terraform
	@ echo "[$@]: Validating terraform roots..."
	@ set -e; for root_dir in tardigrade/roots/*/; do \
		root=$$(basename $$root_dir); \
		echo "[$@]: Validating root: $$root"; \
		cp tardigrade/stacks/aws/providers.tf $$root_dir/_providers.tf; \
		terraform -chdir=$$root_dir init -backend=false; \
		terraform -chdir=$$root_dir validate; \
		rm -f $$root_dir/_providers.tf $$root_dir/.terraform.lock.hcl; \
		rm -rf $$root_dir/.terraform; \
	done
	@ echo "[$@]: Completed successfully!"

PARTITIONS ?= aws

## Initializes repository by substituting placeholders and creating partition stacks
init/repo: | guard/env/REPO_NAME guard/env/REPO_URL guard/env/GLOBAL_REGION guard/env/MANAGEMENT_ACCOUNT_ID guard/env/BACKEND_ROLE_NAME
	@ echo "[$@]: Substituting placeholders..."
	grep -rl --exclude='*.md' '{{' tardigrade/ | xargs sed -i \
		-e 's|{{repo_name}}|$(REPO_NAME)|g' \
		-e 's|{{repo_url}}|$(REPO_URL)|g' \
		-e 's|{{global_region}}|$(GLOBAL_REGION)|g' \
		-e 's|{{management_account_id}}|$(MANAGEMENT_ACCOUNT_ID)|g' \
		-e 's|{{backend_role_name}}|$(BACKEND_ROLE_NAME)|g'
	@ for partition in $(filter-out aws,$(PARTITIONS)); do \
		echo "[$@]: Creating stacks/$$partition..."; \
		cp -r tardigrade/stacks/aws tardigrade/stacks/$$partition; \
	done
	@ echo "[$@]: Completed successfully!"
