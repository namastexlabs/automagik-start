# ===================================================================
# 🚀 Automagik Suite - Master Installation & Management
# ===================================================================

.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
SHELL := /bin/bash

# ===========================================
# 🎨 Colors & Symbols
# ===========================================
FONT_RED := $(shell tput setaf 1)
FONT_GREEN := $(shell tput setaf 2)
FONT_YELLOW := $(shell tput setaf 3)
FONT_BLUE := $(shell tput setaf 4)
FONT_PURPLE := $(shell tput setaf 5)
FONT_CYAN := $(shell tput setaf 6)
FONT_GRAY := $(shell tput setaf 7)
FONT_BLACK := $(shell tput setaf 8)
FONT_BOLD := $(shell tput bold)
FONT_RESET := $(shell tput sgr0)
CHECKMARK := ✅
WARNING := ⚠️
ERROR := ❌
ROCKET := 🚀
MAGIC := 🪄
SUITE := 🎯
INFO := ℹ️
SPARKLES := ✨
GEAR := ⚙️
DATABASE := 🗄️
TOOLS := 🛠️
CHART := 📊

# Service-specific colors for logging
AGENTS_COLOR := $(FONT_BLUE)
SPARK_COLOR := $(FONT_CYAN)
TOOLS_COLOR := $(FONT_PURPLE)
OMNI_COLOR := $(FONT_GREEN)
UI_COLOR := $(FONT_YELLOW)
INFRA_COLOR := $(FONT_RED)

# ===========================================
# 📁 Paths & Configuration
# ===========================================
PROJECT_ROOT := $(shell pwd)
DOCKER_COMPOSE := $(shell if command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker compose"; fi)
INFRASTRUCTURE_COMPOSE := docker-infrastructure.yml

# Service directories
SERVICES_DIR := $(PROJECT_ROOT)
AM_AGENTS_LABS_DIR := $(SERVICES_DIR)/am-agents-labs
AUTOMAGIK_SPARK_DIR := $(SERVICES_DIR)/automagik-spark
AUTOMAGIK_TOOLS_DIR := $(SERVICES_DIR)/automagik-tools
AUTOMAGIK_OMNI_DIR := $(SERVICES_DIR)/automagik-omni
AUTOMAGIK_UI_DIR := $(SERVICES_DIR)/automagik-ui-v2

# Service names (logical)
SERVICES := am-agents-labs automagik-spark automagik-tools automagik-omni automagik-ui-v2

# Actual runnable services (excludes automagik-tools which is a library)
RUNNABLE_SERVICES := am-agents-labs automagik-spark automagik-omni automagik-ui-v2

# Systemd service names (for backward compatibility)
SYSTEMD_SERVICES := automagik-agents automagik-spark automagik-omni

# Repository URLs
AM_AGENTS_LABS_URL := https://github.com/namastexlabs/am-agents-labs.git
AUTOMAGIK_SPARK_URL := https://github.com/namastexlabs/automagik-spark.git
AUTOMAGIK_TOOLS_URL := https://github.com/namastexlabs/automagik-tools.git
AUTOMAGIK_OMNI_URL := https://github.com/namastexlabs/automagik-omni.git
AUTOMAGIK_UI_URL := https://github.com/namastexlabs/automagik-ui-v2.git

# Configuration
CONFIG_DIR := $(PROJECT_ROOT)/config
ENV_FILE := $(CONFIG_DIR)/local-services.env

# ===========================================
# 🛠️ Utility Functions
# ===========================================
define print_status
	@echo -e "$(FONT_PURPLE)$(SUITE) $(1)$(FONT_RESET)"
endef

define print_success
	@echo -e "$(FONT_GREEN)$(CHECKMARK) $(1)$(FONT_RESET)"
endef

define print_warning
	@echo -e "$(FONT_YELLOW)$(WARNING) $(1)$(FONT_RESET)"
endef

define print_error
	@echo -e "$(FONT_RED)$(ERROR) $(1)$(FONT_RESET)"
endef

define print_info
	@echo -e "$(FONT_CYAN)$(INFO) $(1)$(FONT_RESET)"
endef

define ensure_repository
	@repo_name="$(1)"; \
	repo_dir="$(2)"; \
	repo_url="$(3)"; \
	if [ ! -d "$$repo_dir" ]; then \
		echo -e "$(FONT_YELLOW)$(WARNING) Repository $$repo_name not found$(FONT_RESET)"; \
		echo -e "$(FONT_CYAN)$(INFO) Cloning $$repo_name from $$repo_url...$(FONT_RESET)"; \
		if git clone "$$repo_url" "$$repo_dir"; then \
			echo -e "$(FONT_GREEN)$(CHECKMARK) Successfully cloned $$repo_name$(FONT_RESET)"; \
		else \
			echo -e "$(FONT_RED)$(ERROR) Failed to clone $$repo_name$(FONT_RESET)"; \
			exit 1; \
		fi; \
	elif [ ! -d "$$repo_dir/.git" ]; then \
		echo -e "$(FONT_RED)$(ERROR) Directory $$repo_dir exists but is not a Git repository$(FONT_RESET)"; \
		exit 1; \
	else \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Repository $$repo_name already exists$(FONT_RESET)"; \
	fi
endef

define delegate_to_service
	@repo_dir="$(1)"; \
	target="$(2)"; \
	service_name="$$(basename $$repo_dir)"; \
	if [ -f "$$repo_dir/Makefile" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Running $$target for $$service_name...$(FONT_RESET)"; \
		if cd "$$repo_dir" && make -n "$$target" >/dev/null 2>&1; then \
			cd "$$repo_dir" && make "$$target"; \
		else \
			echo -e "$(FONT_YELLOW)$(WARNING) No $$target target found in $$service_name - skipping$(FONT_RESET)"; \
		fi; \
	else \
		echo -e "$(FONT_RED)$(ERROR) No Makefile found in $$repo_dir$(FONT_RESET)"; \
	fi
endef

define check_service_health
	@service_name="$(1)"; \
	color="$(2)"; \
	port="$(3)"; \
	if systemctl is-active --quiet $$service_name 2>/dev/null; then \
		status="$(FONT_GREEN)RUNNING$(FONT_RESET)"; \
		pid=$$(systemctl show $$service_name --property=MainPID --value 2>/dev/null); \
		uptime=$$(systemctl show $$service_name --property=ActiveEnterTimestamp --value 2>/dev/null | awk '{print $$2 " " $$3}'); \
	elif systemctl is-enabled --quiet $$service_name 2>/dev/null; then \
		status="$(FONT_YELLOW)STOPPED$(FONT_RESET)"; \
		pid="-"; \
		uptime="-"; \
	else \
		status="$(FONT_RED)NOT INSTALLED$(FONT_RESET)"; \
		pid="-"; \
		uptime="-"; \
	fi; \
	printf "  %s%-20s%s %-15s %s%-8s%s %s%-10s%s %s%s%s\n" \
		"$$color" "$$service_name" "$(FONT_RESET)" \
		"$$status" \
		"$(FONT_CYAN)" "$$port" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$${pid:-N/A}" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$${uptime:-N/A}" "$(FONT_RESET)"
endef

define check_pm2_service_health
	@service_name="$(1)"; \
	color="$(2)"; \
	port="$(3)"; \
	if pm2 list 2>/dev/null | grep -q "$$service_name.*online"; then \
		status="$(FONT_GREEN)RUNNING$(FONT_RESET)"; \
		pid=$$(pm2 list --no-color 2>/dev/null | awk '/$$service_name.*online/ {print $$10}'); \
		uptime=$$(pm2 show $$service_name 2>/dev/null | grep uptime | awk -F'│' '{print $$3}' | xargs); \
	elif pm2 list 2>/dev/null | grep -q "$$service_name"; then \
		status="$(FONT_YELLOW)STOPPED$(FONT_RESET)"; \
		pid="-"; \
		uptime="-"; \
	else \
		status="$(FONT_RED)NOT INSTALLED$(FONT_RESET)"; \
		pid="-"; \
		uptime="-"; \
	fi; \
	printf "  %s%-20s%s %-15s %s%-8s%s %s%-10s%s %s%s%s\n" \
		"$$color" "$$service_name" "$(FONT_RESET)" \
		"$$status" \
		"$(FONT_CYAN)" "$$port" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$${pid:-N/A}" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$${uptime:-N/A}" "$(FONT_RESET)"
endef


define print_infrastructure_status
	@echo -e "$(FONT_PURPLE)$(DATABASE) Infrastructure Status:$(FONT_RESET)"
	@if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(postgres|redis|rabbitmq|evolution)" >/dev/null 2>&1; then \
		docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(postgres|redis|rabbitmq|evolution)" | while read line; do \
			if echo "$$line" | grep -q "Names"; then \
				echo -e "  $(FONT_GRAY)$$line$(FONT_RESET)"; \
			elif echo "$$line" | grep -q "healthy"; then \
				echo -e "  $(FONT_GREEN)$$line$(FONT_RESET)"; \
			elif echo "$$line" | grep -q "starting\|health: starting"; then \
				echo -e "  $(FONT_YELLOW)$$line$(FONT_RESET)"; \
			elif echo "$$line" | grep -q "unhealthy"; then \
				echo -e "  $(FONT_RED)$$line$(FONT_RESET)"; \
			else \
				echo -e "  $(FONT_CYAN)$$line$(FONT_RESET)"; \
			fi; \
		done; \
	else \
		echo -e "  $(FONT_RED)No infrastructure containers running$(FONT_RESET)"; \
	fi
	@echo ""
endef

define show_automagik_logo
	@echo ""
	@echo -e "$(FONT_PURPLE)                                                                                            $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)                                                                                            $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)     -+*         -=@%*@@@@@@*  -#@@@%*  =@@*      -%@#+   -*       +%@@@@*-%@*-@@*  -+@@*   $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)     =@#*  -@@*  -=@%+@@@@@@*-%@@#%*%@@+=@@@*    -+@@#+  -@@*   -#@@%%@@@*-%@+-@@* -@@#*    $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)    -%@@#* -@@*  -=@@* -@%* -@@**   --@@=@@@@*  -+@@@#+ -#@@%* -*@%*-@@@@*-%@+:@@+#@@*      $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)   -#@+%@* -@@*  -=@@* -@%* -@@*-+@#*-%@+@@=@@* +@%#@#+ =@##@* -%@#*-@@@@*-%@+-@@@@@*       $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)  -*@#==@@*-@@*  -+@%* -@%* -%@#*   -+@@=@@++@%-@@=*@#=-@@*-@@*:+@@*  -%@*-%@+-@@#*@@**     $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)  -@@* -+@%-+@@@@@@@*  -@%*  -#@@@@%@@%+=@@+-=@@@*    -%@*  -@@*-*@@@@%@@*#@@#=%*  -%@@*    $(FONT_RESET)"
	@echo -e "$(FONT_PURPLE) -@@*+  -%@*  -#@%+    -@%+     =#@@*   =@@+          +@%+  -#@#   -*%@@@*@@@@%+     =@@+   $(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_CYAN)🏢 Built by$(FONT_RESET) $(FONT_BOLD)Namastex Labs$(FONT_RESET) | $(FONT_YELLOW)📄 MIT Licensed$(FONT_RESET) | $(FONT_YELLOW)🌟 Open Source Forever$(FONT_RESET)"
	@echo -e "$(FONT_PURPLE)✨ \"Automagik Suite - Local Installation Made Simple\"$(FONT_RESET)"
	@echo ""
endef

define print_success_with_logo
	@echo -e "$(FONT_GREEN)$(CHECKMARK) $(1)$(FONT_RESET)"
	@$(call show_automagik_logo)
endef

# ===========================================
# 📋 Help System
# ===========================================
.PHONY: help
help: ## 🚀 Show this help message
	@$(call show_automagik_logo)
	@echo -e "$(FONT_BOLD)$(FONT_PURPLE)🚀 Automagik Suite$(FONT_RESET) - $(FONT_GRAY)Master Installation & Management$(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_YELLOW)🎯 Hybrid architecture: Docker infrastructure + Local systemd services$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)📦 GitHub:$(FONT_RESET) https://github.com/namastexlabs/automagik-suite"
	@echo ""
	@echo -e "$(FONT_PURPLE)✨ \"Production-grade AI orchestration with native service performance\"$(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_CYAN)$(ROCKET) ESSENTIAL COMMANDS:$(FONT_RESET)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)install$(FONT_RESET)             🚀 Complete installation (infra + services + env)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)start$(FONT_RESET)               🚀 Start everything (infra + all services)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)stop$(FONT_RESET)                🛑 Stop everything (services + infra)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)restart$(FONT_RESET)             🔄 Restart everything"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)update$(FONT_RESET)              🔄 Git pull and restart all services"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)pull$(FONT_RESET)                📌 Pull from all GitHub repos (no restart)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)uninstall$(FONT_RESET)           🗑️ Complete uninstall (remove everything)"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)logs$(FONT_RESET)                📋 Show all colorized logs"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)status$(FONT_RESET)              📊 Check status of everything"
	@echo ""
	@echo -e "$(FONT_CYAN)📋 Individual Service Commands:$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)install-[service]$(FONT_RESET)          Install specific service (agents, spark, tools, omni, ui)"
	@echo -e "  $(FONT_GRAY)start-[service]$(FONT_RESET)            Start specific service"
	@echo -e "  $(FONT_GRAY)stop-[service]$(FONT_RESET)             Stop specific service"
	@echo -e "  $(FONT_GRAY)restart-[service]$(FONT_RESET)          Restart specific service"
	@echo -e "  $(FONT_GRAY)status-[service]$(FONT_RESET)           Check specific service status"
	@echo -e "  $(FONT_GRAY)pull-[service]$(FONT_RESET)             Pull specific service repo"
	@echo -e "  $(FONT_GRAY)logs-[service]$(FONT_RESET)             Follow specific service logs"
	@echo ""
	@echo -e "$(FONT_CYAN)🔧 Advanced Commands (for troubleshooting):$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)install-all-services$(FONT_RESET)       Install services only"
	@echo -e "  $(FONT_GRAY)uninstall-all-services$(FONT_RESET)     Uninstall services only"
	@echo -e "  $(FONT_GRAY)start-all-services$(FONT_RESET)         Start services only"
	@echo -e "  $(FONT_GRAY)stop-all-services$(FONT_RESET)          Stop services only"
	@echo -e "  $(FONT_GRAY)start-infrastructure$(FONT_RESET)       Start infrastructure only"
	@echo -e "  $(FONT_GRAY)stop-infrastructure$(FONT_RESET)        Stop infrastructure only"
	@echo -e "  $(FONT_GRAY)uninstall-infrastructure$(FONT_RESET)   Uninstall infrastructure only"
	@echo ""
	@echo -e "$(FONT_GRAY)Service Colors & Ports:$(FONT_RESET)"
	@echo -e "  $(AGENTS_COLOR)AGENTS$(FONT_RESET) (🎨 Orange):  $(FONT_CYAN)8881$(FONT_RESET)  |  $(SPARK_COLOR)SPARK$(FONT_RESET) (🎨 Yellow):   $(FONT_CYAN)8883$(FONT_RESET)"
	@echo -e "  $(TOOLS_COLOR)TOOLS$(FONT_RESET) (🎨 Blue):     $(FONT_CYAN)8884$(FONT_RESET)  |  $(OMNI_COLOR)OMNI$(FONT_RESET) (🎨 Purple):     $(FONT_CYAN)8882$(FONT_RESET)"
	@echo -e "  $(UI_COLOR)UI$(FONT_RESET) (🎨 Green):        $(FONT_CYAN)8888$(FONT_RESET)  |  $(INFRA_COLOR)EVOLUTION$(FONT_RESET) (🎨 Red):    $(FONT_CYAN)9000$(FONT_RESET)"
	@echo -e "  $(FONT_CYAN)📋 Use 'make logs' to see beautiful colorized output!$(FONT_RESET)"
	@echo ""

# ===========================================
# 🏗️ Infrastructure Management (Docker)
# ===========================================
.PHONY: install-infrastructure start-infrastructure stop-infrastructure uninstall-infrastructure restart-infrastructure status-infrastructure
install-infrastructure: start-infrastructure ## 🗄️ Install Docker infrastructure (alias for start)

start-infrastructure: ## 🚀 Start Docker infrastructure
	$(call print_status,Starting Docker infrastructure...)
	@if [ ! -f "$(INFRASTRUCTURE_COMPOSE)" ]; then \
		$(call print_error,Infrastructure compose file not found: $(INFRASTRUCTURE_COMPOSE)); \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) up -d
	@$(call print_status,Waiting for infrastructure to be ready...)
	@sleep 10
	@$(call print_success,Docker infrastructure started successfully!)
	@$(call print_infrastructure_status)

stop-infrastructure: ## 🛑 Stop Docker infrastructure
	$(call print_status,Stopping Docker infrastructure...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) down
	@$(call print_success,Docker infrastructure stopped!)

uninstall-infrastructure: ## 🗑️ Uninstall Docker infrastructure (remove containers, images, volumes)
	$(call print_status,Uninstalling Docker infrastructure...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) down -v --rmi all --remove-orphans 2>/dev/null || true
	@docker system prune -f 2>/dev/null || true
	@$(call print_success,Docker infrastructure uninstalled!)

restart-infrastructure: ## 🔄 Restart Docker infrastructure
	$(call print_status,Restarting Docker infrastructure...)
	@$(MAKE) stop-infrastructure
	@sleep 2
	@$(MAKE) start-infrastructure

status-infrastructure: ## 📊 Check infrastructure status
	@$(call print_infrastructure_status)

# ===========================================
# 📝 Environment Setup
# ===========================================
.PHONY: setup-env-files
setup-env-files: ## 📝 Setup and sync .env files from central configuration
	$(call print_status,Setting up environment files...)
	@# Create main .env file if it doesn't exist
	@if [ ! -f .env ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Creating main .env file from template...$(FONT_RESET)"; \
		cp .env.example .env; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Main .env file created$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Main .env file already exists$(FONT_RESET)"; \
	fi
	@# Sync central .env to all repositories (always overwrite for consistency)
	@echo -e "$(FONT_CYAN)$(INFO) Syncing central .env to all repositories...$(FONT_RESET)"
	@for repo_dir in $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		repo_name=$$(basename $$repo_dir); \
		if [ -d "$$repo_dir" ]; then \
			echo -e "$(FONT_CYAN)$(INFO) Syncing .env to $$repo_name...$(FONT_RESET)"; \
			cp .env "$$repo_dir/.env"; \
			echo -e "$(FONT_GREEN)$(CHECKMARK) .env synced to $$repo_name$(FONT_RESET)"; \
		fi; \
	done
	@$(call print_success,Environment files synced from central configuration!)

# ===========================================
# 🏗️ Service Building (Optimized)
# ===========================================
.PHONY: build-all-services build-essential-services build-agents build-spark build-tools build-omni build-ui
build-all-services: ## 🏗️ Build all services (includes UI - can be slow)
	$(call print_status,Building all Automagik services...)
	@$(MAKE) build-essential-services
	@$(MAKE) build-ui
	@$(call print_success,All services built successfully!)

build-essential-services: ## 🏗️ Build essential services only (fast - no UI)
	$(call print_status,Building essential Automagik services...)
	@echo -e "$(FONT_CYAN)$(INFO) Building backend services in parallel...$(FONT_RESET)"
	@$(MAKE) build-agents &
	@$(MAKE) build-spark &
	@$(MAKE) build-tools &
	@$(MAKE) build-omni &
	@wait
	@$(call print_success,Essential services built successfully!)

build-agents: ## Build am-agents-labs service
	$(call print_status,Building $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	@if [ -d "$(AM_AGENTS_LABS_DIR)" ] && [ -f "$(AM_AGENTS_LABS_DIR)/Makefile" ]; then \
		cd "$(AM_AGENTS_LABS_DIR)" && make build 2>/dev/null || echo -e "$(FONT_YELLOW)$(WARNING) No build target for am-agents-labs$(FONT_RESET)"; \
	fi

build-spark: ## Build automagik-spark service
	$(call print_status,Building $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@if [ -d "$(AUTOMAGIK_SPARK_DIR)" ] && [ -f "$(AUTOMAGIK_SPARK_DIR)/Makefile" ]; then \
		cd "$(AUTOMAGIK_SPARK_DIR)" && make build 2>/dev/null || echo -e "$(FONT_YELLOW)$(WARNING) No build target for automagik-spark$(FONT_RESET)"; \
	fi

build-tools: ## Build automagik-tools service
	$(call print_status,Building $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@if [ -d "$(AUTOMAGIK_TOOLS_DIR)" ] && [ -f "$(AUTOMAGIK_TOOLS_DIR)/Makefile" ]; then \
		cd "$(AUTOMAGIK_TOOLS_DIR)" && make build 2>/dev/null || echo -e "$(FONT_YELLOW)$(WARNING) No build target for automagik-tools$(FONT_RESET)"; \
	fi

build-omni: ## Build automagik-omni service
	$(call print_status,Building $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@if [ -d "$(AUTOMAGIK_OMNI_DIR)" ] && [ -f "$(AUTOMAGIK_OMNI_DIR)/Makefile" ]; then \
		cd "$(AUTOMAGIK_OMNI_DIR)" && make build 2>/dev/null || echo -e "$(FONT_YELLOW)$(WARNING) No build target for automagik-omni$(FONT_RESET)"; \
	fi

build-ui: ## Build automagik-ui-v2 service (can be slow)
	$(call print_status,Building $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	@if [ -d "$(AUTOMAGIK_UI_DIR)" ] && [ -f "$(AUTOMAGIK_UI_DIR)/Makefile" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Building UI (this may take a few minutes)...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_UI_DIR)" && make build || echo -e "$(FONT_RED)$(ERROR) Failed to build automagik-ui-v2$(FONT_RESET)"; \
	fi

build-ui-fast: ## Build automagik-ui-v2 service (smart - skip if recent)
	$(call print_status,Building $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service (smart mode)...)
	@if [ -d "$(AUTOMAGIK_UI_DIR)" ] && [ -f "$(AUTOMAGIK_UI_DIR)/Makefile" ]; then \
		cd "$(AUTOMAGIK_UI_DIR)" && make build-fast; \
	fi

# ===========================================
# ⚙️ Service Installation
# ===========================================
.PHONY: install-all-services uninstall-all-services install-agents install-spark install-tools install-omni install-ui install-dependencies-only
install-all-services: ## ⚙️ Install all services as systemd services
	$(call print_status,Installing all Automagik services...)
	@# Install services in dependency order
	@$(MAKE) install-agents
	@$(MAKE) install-spark
	@$(MAKE) install-omni
	@$(MAKE) install-ui
	@# Install tools library
	@$(MAKE) install-tools
	@$(call print_success_with_logo,All services installed successfully!)

install-dependencies-only: ## 📦 Install only dependencies (no systemd services)
	$(call print_status,Installing dependencies for all services...)
	@# Install Python dependencies for each service
	@if [ -d "$(AM_AGENTS_LABS_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for am-agents-labs...$(FONT_RESET)"; \
		cd "$(AM_AGENTS_LABS_DIR)" && make install 2>&1 | grep -v "sudo" || true; \
	fi
	@if [ -d "$(AUTOMAGIK_SPARK_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-spark...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_SPARK_DIR)" && make install 2>&1 | grep -v "sudo" || true; \
	fi
	@if [ -d "$(AUTOMAGIK_TOOLS_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-tools...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_TOOLS_DIR)" && make install 2>&1 | grep -v "sudo" || true; \
	fi
	@if [ -d "$(AUTOMAGIK_OMNI_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-omni...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_OMNI_DIR)" && make install 2>&1 | grep -v "sudo" || true; \
	fi
	@if [ -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-ui-v2...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_UI_DIR)" && pnpm install; \
		if [ -f "$(AUTOMAGIK_UI_DIR)/.env.local.example" ] && [ ! -f "$(AUTOMAGIK_UI_DIR)/.env.local" ]; then \
			cp "$(AUTOMAGIK_UI_DIR)/.env.local.example" "$(AUTOMAGIK_UI_DIR)/.env.local"; \
			echo -e "$(FONT_GREEN)$(CHECKMARK) Created .env.local for UI$(FONT_RESET)"; \
		fi; \
	fi
	@$(call print_success,All dependencies installed!)

install-agents: ## Install am-agents-labs service
	$(call print_status,Installing $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	@if [ ! -d "$(AM_AGENTS_LABS_DIR)" ]; then \
		$(call ensure_repository,am-agents-labs,$(AM_AGENTS_LABS_DIR),$(AM_AGENTS_LABS_URL)); \
	fi
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),install)
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),install-service)

install-spark: ## Install automagik-spark service
	$(call print_status,Installing $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_SPARK_DIR)" ]; then \
		$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),install)
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),install-service)

install-tools: ## Install automagik-tools service
	$(call print_status,Installing $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_TOOLS_DIR)" ]; then \
		$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_TOOLS_DIR),install)
	$(call delegate_to_service,$(AUTOMAGIK_TOOLS_DIR),install-service)

install-omni: ## Install automagik-omni service
	$(call print_status,Installing $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_OMNI_DIR)" ]; then \
		$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),install)
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),install-service)

install-ui: ## Install automagik-ui-v2 service
	$(call print_status,Installing $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		$(call ensure_repository,automagik-ui-v2,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),install)
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),install-service)

uninstall-all-services: ## 🗑️ Uninstall all services (remove systemd services)
	$(call print_status,Uninstalling all Automagik services...)
	@$(MAKE) stop-all-services
	@for service in am-agents-labs automagik-spark automagik-tools automagik-omni automagik-ui-v2; do \
		echo -e "Removing $$service systemd service..."; \
		sudo systemctl disable $$service 2>/dev/null || true; \
		sudo rm -f /etc/systemd/system/$$service.service 2>/dev/null || true; \
	done
	@sudo systemctl daemon-reload
	@$(call print_success,All services uninstalled!)

uninstall: ## 🗑️ Complete uninstall (stop everything, remove services and infrastructure)
	$(call print_status,Complete Automagik uninstall...)
	@$(MAKE) stop
	@$(MAKE) uninstall-all-services
	@$(MAKE) uninstall-infrastructure
	@$(call print_success_with_logo,Complete uninstall finished!)

# ===========================================
# 🎛️ Service Management
# ===========================================
.PHONY: start-all-services stop-all-services restart-all-services status-all-services
start-all-services: ## 🚀 Start all services
	$(call print_status,Starting all Automagik services...)
	@echo -e "$(AGENTS_COLOR)[1/4] Starting am-agents-labs (core orchestrator)...$(FONT_RESET)"
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),start-service)
	@sleep 2
	@echo -e "$(SPARK_COLOR)[2/4] Starting automagik-spark (workflow engine)...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),start-service)
	@sleep 2
	@echo -e "$(OMNI_COLOR)[3/4] Starting automagik-omni (multi-tenant hub)...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),start-service)
	@sleep 2
	@echo -e "$(UI_COLOR)[4/4] Starting automagik-ui-v2 (frontend - PM2)...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),start-service)
	@sleep 3
	@$(call print_success,All services started!)

start-all-dev: ## 🚀 Start all services in dev mode (no sudo required)
	$(call print_status,Starting all Automagik services in dev mode...)
	@echo -e "$(FONT_YELLOW)$(WARNING) Dev mode: Services will run on 999x ports$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)Port mapping: agents(9991), omni(9992), spark(9993), tools(9994), ui(9998)$(FONT_RESET)"
	@echo -e "$(AGENTS_COLOR)[1/5] Starting am-agents-labs on port 9991...$(FONT_RESET)"
	@cd $(AM_AGENTS_LABS_DIR) && AM_PORT=9991 $(MAKE) dev &
	@sleep 3
	@echo -e "$(OMNI_COLOR)[2/5] Starting automagik-omni on port 9992...$(FONT_RESET)"
	@cd $(AUTOMAGIK_OMNI_DIR) && API_PORT=9992 $(MAKE) dev &
	@sleep 3
	@echo -e "$(SPARK_COLOR)[3/5] Starting automagik-spark on port 9993...$(FONT_RESET)"
	@cd $(AUTOMAGIK_SPARK_DIR) && source .venv/bin/activate && uvicorn automagik.api.app:app --host 0.0.0.0 --port 9993 --reload &
	@sleep 3
	@echo -e "$(TOOLS_COLOR)[4/5] Starting automagik-tools on port 9994...$(FONT_RESET)"
	@cd $(AUTOMAGIK_TOOLS_DIR) && PORT=9994 $(MAKE) serve-all 2>/dev/null &
	@sleep 3
	@echo -e "$(UI_COLOR)[5/5] Starting automagik-ui-v2 on port 9998...$(FONT_RESET)"
	@cd $(AUTOMAGIK_UI_DIR) && PORT=9998 $(MAKE) dev &
	@sleep 3
	@$(call print_success,All services started in dev mode!)
	@echo -e "$(FONT_YELLOW)$(INFO) Services running on 999x ports. Production services remain on 888x.$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)Access URLs: agents(9991), omni(9992), spark(9993), tools(9994), ui(9998)$(FONT_RESET)"

stop-all-services: ## 🛑 Stop all services
	$(call print_status,Stopping all Automagik services...)
	@echo -e "$(AGENTS_COLOR)Stopping am-agents-labs...$(FONT_RESET)"
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),stop-service)
	@echo -e "$(SPARK_COLOR)Stopping automagik-spark...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),stop-service)
	@echo -e "$(OMNI_COLOR)Stopping automagik-omni...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),stop-service)
	@echo -e "$(UI_COLOR)Stopping automagik-ui-v2...$(FONT_RESET)"
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),stop-service)
	@$(call print_success,All services stopped!)

restart-all-services: ## 🔄 Restart all services
	$(call print_status,Restarting all Automagik services...)
	@$(MAKE) stop-all-services
	@sleep 2
	@$(MAKE) start-all-services

status-all-services: ## 📊 Check status of all services
	@echo -e "$(FONT_PURPLE)$(CHART) Automagik Services Status:$(FONT_RESET)"
	@echo -e "  $(FONT_BOLD)Service Name         Status          Port     PID        Uptime$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)──────────────────────────────────────────────────────────────────────$(FONT_RESET)"
	$(call check_service_health,automagik-agents,$(AGENTS_COLOR),8881)
	$(call check_service_health,automagik-spark,$(SPARK_COLOR),8883)
	$(call check_service_health,omni-hub,$(OMNI_COLOR),8882)
	$(call check_pm2_service_health,automagik-ui-v2,$(UI_COLOR),8888)
	@echo -e "  $(FONT_GRAY)automagik-tools      [LIBRARY]       8884     -          -$(FONT_RESET)"
	@echo ""
	@$(call print_infrastructure_status)

# ===========================================
# 🔧 Individual Service Commands
# ===========================================
.PHONY: start-agents start-spark start-tools start-omni start-ui
.PHONY: stop-agents stop-spark stop-tools stop-omni stop-ui
.PHONY: restart-agents restart-spark restart-tools restart-omni restart-ui
.PHONY: status-agents status-spark status-tools status-omni status-ui

# Individual Start Commands
start-agents: ## 🚀 Start am-agents-labs service only
	$(call print_status,Starting $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),start-service)

start-agents-dev: ## 🚀 Start am-agents-labs in dev mode (no sudo)
	$(call print_status,Starting $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) in dev mode on port 9991...)
	@cd $(AM_AGENTS_LABS_DIR) && AM_PORT=9991 $(MAKE) dev

start-agents-user: ## 🚀 Start am-agents-labs with user systemd (no sudo)
	$(call print_status,Starting $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) with user systemd...)
	@cd $(AM_AGENTS_LABS_DIR) && systemctl --user start automagik-agents 2>/dev/null || echo "User service not installed. Use 'make install-user-services' first."

start-spark: ## 🚀 Start automagik-spark service only
	$(call print_status,Starting $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),start-service)

start-spark-dev: ## 🚀 Start automagik-spark in dev mode (no sudo)
	$(call print_status,Starting $(SPARK_COLOR)automagik-spark$(FONT_RESET) in dev mode...)
	@echo -e "$(FONT_YELLOW)Starting on port 9993 with auto-reload...$(FONT_RESET)"
	@cd $(AUTOMAGIK_SPARK_DIR) && source .venv/bin/activate && uvicorn automagik.api.app:app --host 0.0.0.0 --port 9993 --reload 2>/dev/null || echo "Failed to start dev mode - check dependencies"

start-spark-user: ## 🚀 Start automagik-spark with user systemd (no sudo)
	$(call print_status,Starting $(SPARK_COLOR)automagik-spark$(FONT_RESET) with user systemd...)
	@systemctl --user start automagik-spark 2>/dev/null || echo "User service not installed. Use 'make install-user-services' first."

start-tools: ## 🚀 Start automagik-tools service only
	$(call print_warning,automagik-tools is a library, not a service)

start-tools-dev: ## 🚀 Start automagik-tools in dev mode (no sudo)
	$(call print_status,Starting $(TOOLS_COLOR)automagik-tools$(FONT_RESET) in dev mode on port 9994...)
	@cd $(AUTOMAGIK_TOOLS_DIR) && PORT=9994 $(MAKE) serve-all 2>/dev/null || echo "Tools dev mode not available"

start-omni: ## 🚀 Start automagik-omni service only
	$(call print_status,Starting $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),start-service)

start-omni-dev: ## 🚀 Start automagik-omni in dev mode (no sudo)
	$(call print_status,Starting $(OMNI_COLOR)automagik-omni$(FONT_RESET) in dev mode on port 9992...)
	@cd $(AUTOMAGIK_OMNI_DIR) && API_PORT=9992 $(MAKE) dev

start-omni-user: ## 🚀 Start automagik-omni with user systemd (no sudo)
	$(call print_status,Starting $(OMNI_COLOR)automagik-omni$(FONT_RESET) with user systemd...)
	@systemctl --user start omni-hub 2>/dev/null || echo "User service not installed. Use 'make install-user-services' first."

start-ui: ## 🚀 Start automagik-ui-v2 service only (PM2)
	$(call print_status,Starting $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),start-service)

start-ui-dev: ## 🚀 Start automagik-ui-v2 in dev mode (no sudo)
	$(call print_status,Starting $(UI_COLOR)automagik-ui-v2$(FONT_RESET) in dev mode on port 9998...)
	@cd $(AUTOMAGIK_UI_DIR) && PORT=9998 $(MAKE) dev

# Individual Stop Commands
stop-agents: ## 🛑 Stop am-agents-labs service only
	$(call print_status,Stopping $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),stop-service)

stop-spark: ## 🛑 Stop automagik-spark service only
	$(call print_status,Stopping $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),stop-service)

stop-tools: ## 🛑 Stop automagik-tools service only
	$(call print_warning,automagik-tools is a library, not a service)

stop-omni: ## 🛑 Stop automagik-omni service only
	$(call print_status,Stopping $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),stop-service)

stop-ui: ## 🛑 Stop automagik-ui-v2 service only (PM2)
	$(call print_status,Stopping $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),stop-service)

# Individual Restart Commands
restart-agents: ## 🔄 Restart am-agents-labs service only
	$(call print_status,Restarting $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),restart-service)

restart-spark: ## 🔄 Restart automagik-spark service only
	$(call print_status,Restarting $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),restart-service)

restart-tools: ## 🔄 Restart automagik-tools service only
	$(call print_warning,automagik-tools is a library, not a service)

restart-omni: ## 🔄 Restart automagik-omni service only
	$(call print_status,Restarting $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),restart-service)

restart-ui: ## 🔄 Restart automagik-ui-v2 service only (PM2)
	$(call print_status,Restarting $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),restart-service)

# Individual Status Commands
status-agents: ## 📊 Check am-agents-labs status only
	$(call show_service_status,$(AM_AGENTS_LABS_DIR),$(AGENTS_COLOR))

status-spark: ## 📊 Check automagik-spark status only
	$(call show_service_status,$(AUTOMAGIK_SPARK_DIR),$(SPARK_COLOR))

status-tools: ## 📊 Check automagik-tools status only
	$(call print_warning,automagik-tools is a library, not a service)

status-omni: ## 📊 Check automagik-omni status only
	$(call show_service_status,$(AUTOMAGIK_OMNI_DIR),$(OMNI_COLOR))

status-ui: ## 📊 Check automagik-ui-v2 status only (PM2)
	$(call show_service_status,$(AUTOMAGIK_UI_DIR),$(UI_COLOR))

# ===========================================
# 📋 Logging & Monitoring
# ===========================================
.PHONY: logs-all logs-agents logs-spark logs-tools logs-omni logs-ui logs-infrastructure
logs-all: ## 📋 Follow logs from all services (colorized)
	$(call print_status,Following logs from all services...)
	@echo -e "$(FONT_YELLOW)Press Ctrl+C to stop following logs$(FONT_RESET)"
	@(journalctl -u automagik-agents -f --no-pager 2>/dev/null | sed "s/^/$(AGENTS_COLOR)[AGENTS]$(FONT_RESET) /" &); \
	(journalctl -u automagik-spark -f --no-pager 2>/dev/null | sed "s/^/$(SPARK_COLOR)[SPARK]$(FONT_RESET)  /" &); \
	(journalctl -u automagik-omni -f --no-pager 2>/dev/null | sed "s/^/$(OMNI_COLOR)[OMNI]$(FONT_RESET)   /" &); \
	(pm2 logs automagik-ui-v2 --follow --lines 0 2>/dev/null | sed "s/^/$(UI_COLOR)[UI]$(FONT_RESET)     /" &); \
	wait

logs-agents: ## 📋 Follow am-agents-labs logs
	$(call print_status,Following $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) logs...)
	$(call delegate_to_service,$(AM_AGENTS_LABS_DIR),logs)

logs-spark: ## 📋 Follow automagik-spark logs
	$(call print_status,Following $(SPARK_COLOR)automagik-spark$(FONT_RESET) logs...)
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),logs)

logs-tools: ## 📋 Follow automagik-tools logs
	$(call print_warning,automagik-tools is a library, not a service)

logs-omni: ## 📋 Follow automagik-omni logs
	$(call print_status,Following $(OMNI_COLOR)automagik-omni$(FONT_RESET) logs...)
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),logs)

logs-ui: ## 📋 Follow automagik-ui-v2 logs (PM2)
	$(call print_status,Following $(UI_COLOR)automagik-ui-v2$(FONT_RESET) logs...)
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),logs)

logs-infrastructure: ## 📋 Follow Docker infrastructure logs
	$(call print_status,Following Docker infrastructure logs...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) logs -f

# ===========================================
# 🚀 Local Development Commands  
# ===========================================

start-local: ## 🚀 Start complete local stack
	$(call print_status,Starting complete local stack...)
	@$(MAKE) start-infrastructure
	@sleep 5
	@$(MAKE) start-all-services
	@$(call print_success,Complete local stack started!)

stop-local: ## 🛑 Stop complete local stack
	$(call print_status,Stopping complete local stack...)
	@$(MAKE) stop-all-services
	@$(MAKE) stop-infrastructure
	@$(call print_success,Complete local stack stopped!)

status-local: ## 📊 Check status of complete stack
	@$(call print_status,Complete Local Stack Status)
	@$(MAKE) status-all-services
	@$(MAKE) status-infrastructure

# ===========================================
# 🔄 Development Mode
# ===========================================
.PHONY: dev-local dev-agents dev-spark dev-ui

# ===========================================
# 🔧 Maintenance & Health
# ===========================================
.PHONY: clean-all


clean-all: ## 🧹 Clean all service artifacts (parallel execution)
	$(call print_status,Cleaning all service artifacts...)
	@echo -e "$(FONT_CYAN)$(INFO) Cleaning services in parallel...$(FONT_RESET)"
	@for service_dir in $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			(echo -e "Cleaning $$(basename $$service_dir)..."; cd $$service_dir && make clean 2>/dev/null || true) & \
		fi; \
	done
	@# Clean UI separately as it's the slowest
	@if [ -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Cleaning UI (may take longer)...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_UI_DIR)" && make clean 2>/dev/null || true; \
	fi
	@wait
	@$(call print_success,All artifacts cleaned!)

clean-fast: ## 🧹 Clean essential services only (skip UI for speed)
	$(call print_status,Fast cleaning (essential services only)...)
	@for service_dir in $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			(echo -e "Cleaning $$(basename $$service_dir)..."; cd $$service_dir && make clean 2>/dev/null || true) & \
		fi; \
	done
	@wait
	@$(call print_success,Essential services cleaned!)

# ===========================================
# 📚 Docker Preservation (Legacy Support)
# ===========================================
.PHONY: docker-full docker-start docker-stop
docker-full: ## 🐳 Start full Docker stack (legacy mode)
	$(call print_warning,Starting full Docker stack (legacy mode)...)
	@if [ -f "docker-compose.docker.yml" ]; then \
		$(DOCKER_COMPOSE) -f docker-compose.docker.yml up -d; \
		$(call print_success,Full Docker stack started!); \
	else \
		$(call print_error,Docker compose file not found. Legacy Docker mode not available.); \
	fi

docker-start: docker-full ## 🐳 Alias for docker-full

docker-stop: ## 🛑 Stop full Docker stack
	$(call print_status,Stopping full Docker stack...)
	@$(DOCKER_COMPOSE) -f docker-compose.docker.yml down 2>/dev/null || true
	@$(call print_success,Full Docker stack stopped!)

# ===========================================
# 🚀 ESSENTIAL COMMANDS
# ===========================================
.PHONY: install install-full start stop restart update uninstall pull pull-agents pull-spark pull-tools pull-omni pull-ui logs status
.PHONY: start-agents start-spark start-tools start-omni start-ui stop-agents stop-spark stop-tools stop-omni stop-ui
.PHONY: restart-agents restart-spark restart-tools restart-omni restart-ui status-agents status-spark status-tools status-omni status-ui
.PHONY: clean-fast build-essential-services

install-local: ## 🏠 Local installation (no sudo required - uses PM2)
	$(call print_status,🏠 Installing Automagik suite locally (no sudo)...)
	@# Clone all repositories first
	@$(call ensure_repository,am-agents-labs,$(AM_AGENTS_LABS_DIR),$(AM_AGENTS_LABS_URL))
	@$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@$(call ensure_repository,automagik-ui-v2,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@# Now setup environment files after all repos exist
	@$(MAKE) setup-env-files
	@$(MAKE) start-infrastructure
	@$(MAKE) build-essential-services
	@$(MAKE) install-dependencies-only
	@$(call print_success_with_logo,Local installation finished!)
	@echo -e "$(FONT_CYAN)🌐 Frontend: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 APIs:$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Agents: http://localhost:8881$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Omni: http://localhost:8882$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Spark: http://localhost:8883$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Tools: http://localhost:8884$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)💡 To start services: make -f Makefile.local start-all$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)💡 Or use PM2 setup: make -f Makefile.local setup-pm2$(FONT_RESET)"

install: ## 🚀 Install Automagik suite (infrastructure + services - no auto-start)
	$(call print_status,🚀 Installing Automagik suite...)
	@# Clone all repositories first
	@$(call ensure_repository,am-agents-labs,$(AM_AGENTS_LABS_DIR),$(AM_AGENTS_LABS_URL))
	@$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@$(call ensure_repository,automagik-ui-v2,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@# Now setup environment files after all repos exist
	@$(MAKE) setup-env-files
	@$(MAKE) start-infrastructure
	@$(MAKE) build-essential-services
	@$(MAKE) install-all-services
	@$(call print_success_with_logo,Installation completed!)
	@echo -e "$(FONT_CYAN)🌐 Frontend: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 APIs:$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Agents: http://localhost:8881$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Omni: http://localhost:8882$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Spark: http://localhost:8883$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   - Tools: http://localhost:8884$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)💡 Start services with: make start$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)💡 Check status with: make status$(FONT_RESET)"

install-full: ## 🚀 Complete installation (includes UI build - slower but fully ready)
	$(call print_status,🚀 Installing complete Automagik suite with UI build...)
	@# Clone all repositories first
	@$(call ensure_repository,am-agents-labs,$(AM_AGENTS_LABS_DIR),$(AM_AGENTS_LABS_URL))
	@$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@$(call ensure_repository,automagik-ui-v2,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@# Now setup environment files after all repos exist
	@$(MAKE) setup-env-files
	@$(MAKE) start-infrastructure
	@$(MAKE) build-all-services
	@$(MAKE) install-all-services
	@$(MAKE) start-all-services
	@$(call print_success_with_logo,Complete installation finished!)
	@echo -e "$(FONT_CYAN)🌐 Frontend: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 API: http://localhost:8881$(FONT_RESET)"

start: ## 🚀 Start everything (infrastructure + all services)
	$(call print_status,🚀 Starting complete Automagik stack...)
	@$(MAKE) start-infrastructure
	@sleep 5
	@$(MAKE) start-all-services
	@$(call print_success,Complete stack started!)
	@echo ""
	@$(MAKE) status

start-nosudo: ## 🚀 Start everything without sudo (dev mode)
	$(call print_status,🚀 Starting Automagik stack in dev mode (no sudo)...)
	@$(MAKE) start-infrastructure
	@sleep 5
	@$(MAKE) start-all-dev
	@$(call print_success,Complete dev stack started! All services on 999x ports.)

stop: ## 🛑 Stop everything (services + infrastructure)
	$(call print_status,🛑 Stopping complete Automagik stack...)
	@$(MAKE) stop-all-services
	@$(MAKE) stop-infrastructure
	@$(call print_success,Complete stack stopped!)

restart: ## 🔄 Restart everything
	$(call print_status,🔄 Restarting complete Automagik stack...)
	@$(MAKE) stop
	@sleep 3
	@$(MAKE) start
	@$(call print_success,Complete stack restarted!)

restart-nosudo: ## 🔄 Restart everything without sudo
	$(call print_status,🔄 Restarting stack in dev mode (no sudo)...)
	@$(MAKE) stop
	@sleep 3
	@$(MAKE) start-nosudo
	@$(call print_success,Dev stack restarted!)

update: ## 🔄 Git pull and restart all services
	$(call print_status,🔄 Updating Automagik suite...)
	@$(MAKE) pull
	@$(MAKE) restart
	@$(call print_success,Update complete!)

pull: ## 🔄 Pull from all GitHub repos (main + all services)
	$(call print_status,🔄 Pulling from all GitHub repositories...)
	@echo -e "$(FONT_CYAN)📌 Pulling main repository...$(FONT_RESET)"
	@git pull
	@for service_dir in $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			echo -e "$(FONT_CYAN)📌 Pulling $$(basename $$service_dir)...$(FONT_RESET)"; \
			cd $$service_dir && git pull 2>/dev/null || echo "  $(FONT_YELLOW)⚠️ Not a git repository or no remote$(FONT_RESET)"; \
			cd - >/dev/null; \
		fi; \
	done
	@$(call print_success,All repositories updated!)

pull-agents: ## 🔄 Pull am-agents-labs repository only
	$(call print_status,Pulling $(AGENTS_COLOR)am-agents-labs$(FONT_RESET)...)
	$(call ensure_repository,am-agents-labs,$(AM_AGENTS_LABS_DIR),$(AM_AGENTS_LABS_URL))
	@cd $(AM_AGENTS_LABS_DIR) && git pull
	@$(call print_success,am-agents-labs updated!)

pull-spark: ## 🔄 Pull automagik-spark repository only
	$(call print_status,Pulling $(SPARK_COLOR)automagik-spark$(FONT_RESET)...)
	$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@cd $(AUTOMAGIK_SPARK_DIR) && git pull
	@$(call print_success,automagik-spark updated!)

pull-tools: ## 🔄 Pull automagik-tools repository only
	$(call print_status,Pulling $(TOOLS_COLOR)automagik-tools$(FONT_RESET)...)
	$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@cd $(AUTOMAGIK_TOOLS_DIR) && git pull
	@$(call print_success,automagik-tools updated!)

pull-omni: ## 🔄 Pull automagik-omni repository only
	$(call print_status,Pulling $(OMNI_COLOR)automagik-omni$(FONT_RESET)...)
	$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@cd $(AUTOMAGIK_OMNI_DIR) && git pull
	@$(call print_success,automagik-omni updated!)

pull-ui: ## 🔄 Pull automagik-ui-v2 repository only
	$(call print_status,Pulling $(UI_COLOR)automagik-ui-v2$(FONT_RESET)...)
	$(call ensure_repository,automagik-ui-v2,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@cd $(AUTOMAGIK_UI_DIR) && git pull
	@$(call print_success,automagik-ui-v2 updated!)

logs: ## 📋 Show last 30 lines from all services (colorized)
	$(call print_status,📋 Showing last 30 lines from all services...)
	@echo -e "$(AGENTS_COLOR)[AGENTS] Last 30 lines:$(FONT_RESET)"
	@journalctl -u automagik-agents -n 30 --no-pager 2>/dev/null | sed "s/^/$(AGENTS_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"
	@echo -e "$(SPARK_COLOR)[SPARK] Last 30 lines:$(FONT_RESET)"
	@journalctl -u automagik-spark -n 30 --no-pager 2>/dev/null | sed "s/^/$(SPARK_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"
	@echo -e "$(TOOLS_COLOR)[TOOLS] automagik-tools is a library, not a service$(FONT_RESET)"
	@echo -e "$(OMNI_COLOR)[OMNI] Last 30 lines:$(FONT_RESET)"
	@journalctl -u automagik-omni -n 30 --no-pager 2>/dev/null | sed "s/^/$(OMNI_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"
	@echo -e "$(UI_COLOR)[UI] Last 30 lines:$(FONT_RESET)"
	@pm2 logs automagik-ui-v2 --lines 30 2>/dev/null | sed "s/^/$(UI_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"

status: ## 📊 Check status of everything
	@$(MAKE) status-all-services

# Legacy aliases for compatibility
start-local: start
stop-local: stop
status-local: status
logs-all: logs

# Ensure default goal shows help
.DEFAULT_GOAL := help
