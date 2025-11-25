# Stamp Deployment Makefile
#
# Quick shortcuts for common operations.
# Usage: make <target> [STAMP=<stamp_id>]
#

STAMP ?= swc-dev
SCRIPTS := ./scripts

.PHONY: help list bootstrap init plan deploy deploy-all destroy status validate fmt clean

help: ## Show this help
	@echo "Usage: make <target> [STAMP=<stamp_id>]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Workflow:"
	@echo "  1. make bootstrap        # One-time: create shared state backend"
	@echo "  2. make deploy STAMP=swc-dev  # Deploy a stamp"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy STAMP=swc-dev"
	@echo "  make plan STAMP=swc-prod"
	@echo "  make status STAMP=neu-dev"

list: ## List available stamps
	@$(SCRIPTS)/stamp list

bootstrap: ## Bootstrap shared state backend (run once)
	@$(SCRIPTS)/stamp bootstrap

init: ## Initialize layer backends for a stamp
	@$(SCRIPTS)/stamp init $(STAMP)

plan: ## Plan all layers for a stamp
	@$(SCRIPTS)/stamp plan $(STAMP)

deploy: ## Deploy all layers (requires bootstrap first)
	@$(SCRIPTS)/stamp deploy $(STAMP)

deploy-all: ## Full deployment (bootstrap if needed + deploy)
	@$(SCRIPTS)/stamp deploy-all $(STAMP)

destroy: ## Destroy all stamp layers (with confirmation)
	@$(SCRIPTS)/stamp destroy $(STAMP)

status: ## Show deployment status
	@$(SCRIPTS)/stamp status $(STAMP)

validate: ## Validate Terraform configuration
	@$(SCRIPTS)/stamp validate

fmt: ## Format Terraform files
	@$(SCRIPTS)/stamp fmt

clean: ## Clean Terraform caches
	@find terraform -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find terraform -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "Cleaned Terraform caches"

# Shortcuts for common stamps
.PHONY: dev staging prod

dev: ## Deploy swc-dev (bootstrap if needed)
	@$(SCRIPTS)/stamp deploy-all swc-dev

staging: ## Deploy swc-staging (bootstrap if needed)
	@$(SCRIPTS)/stamp deploy-all swc-staging

prod: ## Deploy swc-prod (with extra confirmation)
	@echo "⚠️  You are about to deploy to PRODUCTION"
	@$(SCRIPTS)/stamp deploy-all swc-prod