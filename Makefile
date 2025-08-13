# Stylze AI Fashion App - Makefile
# ===================================

# Variables
DOCKER_COMPOSE = docker-compose -f ai-styling-backend/docker-compose.yml
KUBECTL = kubectl
TERRAFORM = terraform
NPM = npm
PYTHON = python3
PROJECT_NAME = stylze

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Stylze AI Fashion App - Available Commands$(NC)"
	@echo "==========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# ===== Development Commands =====

.PHONY: setup
setup: ## Initial project setup
	@echo "$(YELLOW)Setting up Stylze project...$(NC)"
	@./scripts/setup.sh
	@echo "$(GREEN)Setup complete!$(NC)"

.PHONY: start
start: ## Start all services
	@echo "$(YELLOW)Starting all services...$(NC)"
	@./start-all.sh

.PHONY: stop
stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@./stop-all.sh

.PHONY: restart
restart: stop start ## Restart all services

.PHONY: logs
logs: ## Show logs for all services
	@$(DOCKER_COMPOSE) logs -f

.PHONY: status
status: ## Check status of all services
	@echo "$(BLUE)Service Status:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo "\n$(BLUE)Node Services:$(NC)"
	@ps aux | grep -E "node.*(user|avatar|notification|api|recommendation)" | grep -v grep || echo "No Node services running"
	@echo "\n$(BLUE)Python Services:$(NC)"
	@ps aux | grep -E "python.*main.py" | grep -v grep || echo "No Python services running"

# ===== Docker Commands =====

.PHONY: docker-build
docker-build: ## Build all Docker images
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Docker images built!$(NC)"

.PHONY: docker-up
docker-up: ## Start Docker infrastructure
	@echo "$(YELLOW)Starting Docker infrastructure...$(NC)"
	@$(DOCKER_COMPOSE) up -d postgres redis rabbitmq minio
	@echo "$(GREEN)Infrastructure started!$(NC)"

.PHONY: docker-down
docker-down: ## Stop Docker infrastructure
	@echo "$(YELLOW)Stopping Docker infrastructure...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Infrastructure stopped!$(NC)"

.PHONY: docker-clean
docker-clean: ## Clean Docker volumes and images
	@echo "$(RED)Cleaning Docker resources...$(NC)"
	@$(DOCKER_COMPOSE) down -v
	@docker system prune -af
	@echo "$(GREEN)Docker resources cleaned!$(NC)"

# ===== Database Commands =====

.PHONY: db-migrate
db-migrate: ## Run database migrations
	@echo "$(YELLOW)Running database migrations...$(NC)"
	@cd ai-styling-backend/services/user-service && npx prisma migrate dev
	@echo "$(GREEN)Migrations complete!$(NC)"

.PHONY: db-seed
db-seed: ## Seed database with sample data
	@echo "$(YELLOW)Seeding database...$(NC)"
	@cd ai-styling-backend/services/user-service && npm run seed
	@echo "$(GREEN)Database seeded!$(NC)"

.PHONY: db-reset
db-reset: ## Reset database
	@echo "$(RED)Resetting database...$(NC)"
	@cd ai-styling-backend/services/user-service && npx prisma migrate reset --force
	@echo "$(GREEN)Database reset!$(NC)"

.PHONY: db-studio
db-studio: ## Open Prisma Studio
	@echo "$(BLUE)Opening Prisma Studio...$(NC)"
	@cd ai-styling-backend/services/user-service && npx prisma studio

# ===== Testing Commands =====

.PHONY: test
test: test-unit test-integration ## Run all tests

.PHONY: test-unit
test-unit: ## Run unit tests
	@echo "$(YELLOW)Running unit tests...$(NC)"
	@cd ai-styling-backend && npm test
	@cd ai-styling-web && npm test
	@cd ai-styling-mobile && npm test
	@echo "$(GREEN)Unit tests complete!$(NC)"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "$(YELLOW)Running integration tests...$(NC)"
	@cd tests/integration && npm test
	@echo "$(GREEN)Integration tests complete!$(NC)"

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "$(YELLOW)Running E2E tests...$(NC)"
	@cd tests/e2e && npm run cypress:run
	@echo "$(GREEN)E2E tests complete!$(NC)"

.PHONY: test-coverage
test-coverage: ## Generate test coverage report
	@echo "$(YELLOW)Generating coverage report...$(NC)"
	@cd ai-styling-backend && npm run test:coverage
	@echo "$(GREEN)Coverage report generated!$(NC)"

# ===== Linting & Formatting =====

.PHONY: lint
lint: ## Run linters
	@echo "$(YELLOW)Running linters...$(NC)"
	@cd ai-styling-backend && npm run lint
	@cd ai-styling-web && npm run lint
	@cd ai-styling-mobile && npm run lint
	@cd ai-styling-ai && python -m pylint src/
	@echo "$(GREEN)Linting complete!$(NC)"

.PHONY: format
format: ## Format code
	@echo "$(YELLOW)Formatting code...$(NC)"
	@cd ai-styling-backend && npm run format
	@cd ai-styling-web && npm run format
	@cd ai-styling-mobile && npm run format
	@cd ai-styling-ai && python -m black src/
	@echo "$(GREEN)Formatting complete!$(NC)"

# ===== Build Commands =====

.PHONY: build
build: build-backend build-frontend build-mobile ## Build all applications

.PHONY: build-backend
build-backend: ## Build backend services
	@echo "$(YELLOW)Building backend services...$(NC)"
	@cd ai-styling-backend && npm run build
	@echo "$(GREEN)Backend built!$(NC)"

.PHONY: build-frontend
build-frontend: ## Build web frontend
	@echo "$(YELLOW)Building web frontend...$(NC)"
	@cd ai-styling-web && npm run build
	@echo "$(GREEN)Frontend built!$(NC)"

.PHONY: build-mobile
build-mobile: ## Build mobile app
	@echo "$(YELLOW)Building mobile app...$(NC)"
	@cd ai-styling-mobile && npm run build
	@echo "$(GREEN)Mobile app built!$(NC)"

# ===== Deployment Commands =====

.PHONY: deploy-dev
deploy-dev: ## Deploy to development environment
	@echo "$(YELLOW)Deploying to development...$(NC)"
	@./scripts/deploy.sh development
	@echo "$(GREEN)Deployed to development!$(NC)"

.PHONY: deploy-staging
deploy-staging: ## Deploy to staging environment
	@echo "$(YELLOW)Deploying to staging...$(NC)"
	@./scripts/deploy.sh staging
	@echo "$(GREEN)Deployed to staging!$(NC)"

.PHONY: deploy-prod
deploy-prod: ## Deploy to production environment
	@echo "$(RED)Deploying to PRODUCTION...$(NC)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./scripts/deploy.sh production; \
		echo "$(GREEN)Deployed to production!$(NC)"; \
	else \
		echo "$(YELLOW)Deployment cancelled$(NC)"; \
	fi

# ===== Kubernetes Commands =====

.PHONY: k8s-apply
k8s-apply: ## Apply Kubernetes manifests
	@echo "$(YELLOW)Applying Kubernetes manifests...$(NC)"
	@$(KUBECTL) apply -f ai-styling-infra/kubernetes/
	@echo "$(GREEN)Kubernetes manifests applied!$(NC)"

.PHONY: k8s-delete
k8s-delete: ## Delete Kubernetes resources
	@echo "$(RED)Deleting Kubernetes resources...$(NC)"
	@$(KUBECTL) delete -f ai-styling-infra/kubernetes/
	@echo "$(GREEN)Kubernetes resources deleted!$(NC)"

.PHONY: k8s-status
k8s-status: ## Check Kubernetes status
	@echo "$(BLUE)Kubernetes Status:$(NC)"
	@$(KUBECTL) get all -n stylze-prod

.PHONY: k8s-logs
k8s-logs: ## Show Kubernetes logs
	@$(KUBECTL) logs -f deployment/api-gateway -n stylze-prod

# ===== Terraform Commands =====

.PHONY: terraform-init
terraform-init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	@cd ai-styling-infra/terraform && $(TERRAFORM) init
	@echo "$(GREEN)Terraform initialized!$(NC)"

.PHONY: terraform-plan
terraform-plan: ## Plan Terraform changes
	@echo "$(YELLOW)Planning Terraform changes...$(NC)"
	@cd ai-styling-infra/terraform && $(TERRAFORM) plan
	@echo "$(GREEN)Terraform plan complete!$(NC)"

.PHONY: terraform-apply
terraform-apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes...$(NC)"
	@cd ai-styling-infra/terraform && $(TERRAFORM) apply
	@echo "$(GREEN)Terraform changes applied!$(NC)"

.PHONY: terraform-destroy
terraform-destroy: ## Destroy Terraform resources
	@echo "$(RED)Destroying Terraform resources...$(NC)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd ai-styling-infra/terraform && $(TERRAFORM) destroy; \
		echo "$(GREEN)Terraform resources destroyed!$(NC)"; \
	else \
		echo "$(YELLOW)Destruction cancelled$(NC)"; \
	fi

# ===== Monitoring Commands =====

.PHONY: monitor-start
monitor-start: ## Start monitoring stack
	@echo "$(YELLOW)Starting monitoring stack...$(NC)"
	@docker-compose -f ai-styling-infra/monitoring/docker-compose.yml up -d
	@echo "$(GREEN)Monitoring started!$(NC)"
	@echo "Prometheus: http://localhost:9090"
	@echo "Grafana: http://localhost:3007"

.PHONY: monitor-stop
monitor-stop: ## Stop monitoring stack
	@echo "$(YELLOW)Stopping monitoring stack...$(NC)"
	@docker-compose -f ai-styling-infra/monitoring/docker-compose.yml down
	@echo "$(GREEN)Monitoring stopped!$(NC)"

# ===== Utility Commands =====

.PHONY: clean
clean: ## Clean build artifacts and dependencies
	@echo "$(YELLOW)Cleaning project...$(NC)"
	@rm -rf ai-styling-backend/node_modules
	@rm -rf ai-styling-backend/services/*/node_modules
	@rm -rf ai-styling-web/node_modules
	@rm -rf ai-styling-web/.next
	@rm -rf ai-styling-mobile/node_modules
	@rm -rf ai-styling-ai/__pycache__
	@rm -rf ai-styling-ai/venv
	@echo "$(GREEN)Project cleaned!$(NC)"

.PHONY: install
install: ## Install all dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@cd ai-styling-backend && npm install
	@cd ai-styling-web && npm install
	@cd ai-styling-mobile && npm install
	@cd ai-styling-ai && pip install -r requirements.txt
	@echo "$(GREEN)Dependencies installed!$(NC)"

.PHONY: update
update: ## Update all dependencies
	@echo "$(YELLOW)Updating dependencies...$(NC)"
	@cd ai-styling-backend && npm update
	@cd ai-styling-web && npm update
	@cd ai-styling-mobile && npm update
	@cd ai-styling-ai && pip install -r requirements.txt --upgrade
	@echo "$(GREEN)Dependencies updated!$(NC)"

.PHONY: check-deps
check-deps: ## Check for dependency vulnerabilities
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@cd ai-styling-backend && npm audit
	@cd ai-styling-web && npm audit
	@cd ai-styling-mobile && npm audit
	@cd ai-styling-ai && pip-audit
	@echo "$(GREEN)Dependency check complete!$(NC)"

.PHONY: generate-docs
generate-docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@cd docs && npm run build
	@echo "$(GREEN)Documentation generated!$(NC)"

.PHONY: version
version: ## Show version information
	@echo "$(BLUE)Stylze Version Information:$(NC)"
	@echo "Backend: $$(cd ai-styling-backend && npm version | grep stylze)"
	@echo "Frontend: $$(cd ai-styling-web && npm version | grep stylze)"
	@echo "Mobile: $$(cd ai-styling-mobile && npm version | grep stylze)"
	@echo "Node: $$(node --version)"
	@echo "Python: $$(python3 --version)"
	@echo "Docker: $$(docker --version)"
	@echo "Kubernetes: $$(kubectl version --client --short)"

# Default target
.DEFAULT_GOAL := help