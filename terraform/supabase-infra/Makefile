
# Variables
TERRAFORM = terraform
ENVS_DIR = env

.PHONY: help init dev staging prod plan apply destroy clean fmt validate

help:
	@echo "Usage: make [env] [action]"
	@echo "Examples:"
	@echo "  make dev plan      - Plan for development"
	@echo "  make staging apply - Apply for staging"
	@echo "  make prod apply    - Apply for production"

# 1. Initialize with remote backend
init:
	$(TERRAFORM) init

# 2. Environment Selectors
dev:
	$(eval WORKSPACE=dev)
	$(eval VAR_FILE=$(ENVS_DIR)/dev.tfvars)
	@echo "--- Context: DEV ---"

staging:
	$(eval WORKSPACE=staging)
	$(eval VAR_FILE=$(ENVS_DIR)/staging.tfvars)
	@echo "--- Context: STAGING ---"

prod:
	$(eval WORKSPACE=prod)
	$(eval VAR_FILE=$(ENVS_DIR)/prod.tfvars)
	@echo "--- Context: PRODUCTION ---"

# 3. Workspace Management Helper
set-workspace:
	@$(TERRAFORM) workspace select $(WORKSPACE) || $(TERRAFORM) workspace new $(WORKSPACE)

# 4. Core Actions
plan: set-workspace
	$(TERRAFORM) plan -var-file=$(VAR_FILE)

apply: set-workspace
	$(TERRAFORM) apply -var-file=$(VAR_FILE)

destroy: set-workspace
	$(TERRAFORM) destroy -var-file=$(VAR_FILE)

# 5. Code Quality & Maintenance
fmt:
	$(TERRAFORM) fmt -recursive

validate:
	$(TERRAFORM) validate

clean:
	rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate.d/

