# ===================================================================
# 🚀 Automagik Suite - Master Installation & Management
# ===================================================================

.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
# Use modern bash if available (needed for associative arrays on macOS)
SHELL := $(shell if [ -x "/opt/homebrew/bin/bash" ]; then echo "/opt/homebrew/bin/bash"; else echo "/bin/bash"; fi)

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
FONT_BRIGHT_BLUE := $(shell tput setaf 12)
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

# ===========================================
# 🎨 PROJECT COLOR SCHEME - SINGLE SOURCE OF TRUTH
# ===========================================
# Namastex Labs Repository Colors
AGENTS_COLOR := $(FONT_BRIGHT_BLUE)  # automagik: Bright Blue (cyan blue)
SPARK_COLOR := $(FONT_YELLOW)        # automagik-spark: Amber Yellow  
TOOLS_COLOR := $(FONT_BLUE)          # automagik-tools: Dark Blue
OMNI_COLOR := $(FONT_PURPLE)         # automagik-omni: Purple
UI_COLOR := $(FONT_GREEN)            # automagik-ui: Green
INFRA_COLOR := $(FONT_RED)           # infrastructure: Red

# ===========================================
# 📁 Paths & Configuration
# ===========================================
PROJECT_ROOT := $(shell pwd)
DOCKER_COMPOSE := $(shell \
	if command -v docker >/dev/null 2>&1; then \
		if docker compose version >/dev/null 2>&1; then \
			echo "docker compose"; \
		elif command -v docker-compose >/dev/null 2>&1; then \
			echo "docker-compose"; \
		else \
			echo "echo 'ERROR: Neither docker compose nor docker-compose is available' >&2; exit 1"; \
		fi; \
	else \
		echo "echo 'ERROR: Docker is not installed' >&2; exit 1"; \
	fi)
INFRASTRUCTURE_COMPOSE := docker-infrastructure.yml

# Service directories
SERVICES_DIR := $(PROJECT_ROOT)
AUTOMAGIK_DIR := $(SERVICES_DIR)/automagik
AUTOMAGIK_SPARK_DIR := $(SERVICES_DIR)/automagik-spark
AUTOMAGIK_TOOLS_DIR := $(SERVICES_DIR)/automagik-tools
AUTOMAGIK_OMNI_DIR := $(SERVICES_DIR)/automagik-omni
AUTOMAGIK_UI_DIR := $(SERVICES_DIR)/automagik-ui

# Service names (logical)
SERVICES := automagik automagik-spark automagik-tools automagik-omni automagik-ui

# Actual runnable services (excludes automagik-tools which is a library)
RUNNABLE_SERVICES := automagik automagik-spark automagik-omni automagik-ui

# PM2 service names
PM2_SERVICES := automagik automagik-spark-api automagik-spark-worker automagik-tools-sse automagik-tools-http automagik-omni automagik-ui

# Repository URLs
AUTOMAGIK_URL := https://github.com/namastexlabs/automagik.git
AUTOMAGIK_SPARK_URL := https://github.com/namastexlabs/automagik-spark.git
AUTOMAGIK_TOOLS_URL := https://github.com/namastexlabs/automagik-tools.git
AUTOMAGIK_OMNI_URL := https://github.com/namastexlabs/automagik-omni.git
AUTOMAGIK_UI_URL := https://github.com/namastexlabs/automagik-ui.git

# Configuration
CONFIG_DIR := $(PROJECT_ROOT)/config
ENV_FILE := $(CONFIG_DIR)/local-services.env

# Docker compose files
LANGFLOW_COMPOSE := docker-langflow.yml
EVOLUTION_COMPOSE := docker-evolution.yml

# ===========================================
# 📌 PHONY Targets Declaration
# ===========================================
.PHONY: help \
        install install-full install-all install-agents install-spark install-tools install-omni install-ui install-dependencies-only \
        install-infrastructure start-infrastructure stop-infrastructure uninstall-infrastructure restart-infrastructure status-infrastructure \
        start start-all start-agents start-spark start-tools start-omni start-ui \
        stop stop-all stop-agents stop-spark stop-tools stop-omni stop-ui \
        restart restart-all restart-agents restart-spark restart-tools restart-omni restart-ui \
        status status-all status-agents status-spark status-tools status-omni status-ui \
        logs logs-all logs-agents logs-spark logs-spark-api logs-spark-worker logs-tools logs-tools-sse logs-tools-http logs-omni logs-ui logs-infrastructure \
        start-langflow stop-langflow restart-langflow status-langflow \
        start-evolution stop-evolution restart-evolution status-evolution \
        setup-env-files sync-service-env-ports env env-status \
        clean-all clean-fast git-status check-updates \
        docker-full docker-start docker-stop \
        uninstall uninstall-all update \
        pull pull-agents pull-spark pull-tools pull-omni pull-ui

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
		echo -e "$(FONT_CYAN)$(INFO) Checking GitHub authentication...$(FONT_RESET)"; \
		if command -v gh >/dev/null 2>&1; then \
			if ! gh auth status >/dev/null 2>&1; then \
				echo -e "$(FONT_YELLOW)$(WARNING) GitHub CLI not authenticated$(FONT_RESET)"; \
				echo -e "$(FONT_CYAN)$(INFO) Please authenticate with GitHub CLI:$(FONT_RESET)"; \
				echo -e "$(FONT_CYAN)   gh auth login$(FONT_RESET)"; \
				echo -e "$(FONT_CYAN)Then re-run the installation.$(FONT_RESET)"; \
				exit 1; \
			else \
				echo -e "$(FONT_GREEN)$(CHECKMARK) GitHub CLI authenticated$(FONT_RESET)"; \
			fi; \
		else \
			echo -e "$(FONT_RED)$(ERROR) GitHub CLI not found but required for private repositories$(FONT_RESET)"; \
			exit 1; \
		fi; \
		echo -e "$(FONT_CYAN)$(INFO) Cloning $$repo_name from $$repo_url...$(FONT_RESET)"; \
		if gh repo clone "$$repo_url" "$$repo_dir"; then \
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
			cd "$$repo_dir" && AUTOMAGIK_QUIET_LOGO=1 make "$$target"; \
		else \
			echo -e "$(FONT_YELLOW)$(WARNING) No $$target target found in $$service_name - skipping$(FONT_RESET)"; \
		fi; \
	else \
		echo -e "$(FONT_RED)$(ERROR) No Makefile found in $$repo_dir$(FONT_RESET)"; \
	fi
endef

# Generic git pull function for any service
define git_pull_service
	$(call print_status,Pulling $(2)$(1)$(FONT_RESET)...)
	$(call ensure_repository,$(1),$(3),$(4))
	@cd $(3) && git pull
	@$(call print_success,$(1) updated!)
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
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo "")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)                                                                                            $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)                                                                                            $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)     -+*         -=@%*@@@@@@*  -#@@@%*  =@@*      -%@#+   -*       +%@@@@*-%@*-@@*  -+@@*   $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)     =@#*  -@@*  -=@%+@@@@@@*-%@@#%*%@@+=@@@*    -+@@#+  -@@*   -#@@%%@@@*-%@+-@@* -@@#*    $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)    -%@@#* -@@*  -=@@* -@%* -@@**   --@@=@@@@*  -+@@@#+ -#@@%* -*@%*-@@@@*-%@+:@@+#@@*      $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)   -#@+%@* -@@*  -=@@* -@%* -@@*-+@#*-%@+@@=@@* +@%#@#+ =@##@* -%@#*-@@@@*-%@+-@@@@@*       $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)  -*@#==@@*-@@*  -+@%* -@%* -%@#*   -+@@=@@++@%-@@=*@#=-@@*-@@*:+@@*  -%@*-%@+-@@#*@@**     $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)  -@@* -+@%-+@@@@@@@*  -@%*  -#@@@@%@@%+=@@+-=@@@*    -%@*  -@@*-*@@@@%@@*#@@#=%*  -%@@*    $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE) -@@*+  -%@*  -#@%+    -@%+     =#@@*   =@@+          +@%+  -#@#   -*%@@@*@@@@%+     =@@+   $(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo "")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_CYAN)🏢 Built by$(FONT_RESET) $(FONT_BOLD)Namastex Labs$(FONT_RESET) | $(FONT_YELLOW)📄 MIT Licensed$(FONT_RESET) | $(FONT_YELLOW)🌟 Open Source Forever$(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo -e "$(FONT_PURPLE)✨ \"Automagik Suite - Local Installation Made Simple\"$(FONT_RESET)")
	$(if $(AUTOMAGIK_QUIET_LOGO),,@echo "")
endef

define print_success_with_logo
	@echo -e "$(FONT_GREEN)$(CHECKMARK) $(1)$(FONT_RESET)"
	@$(call show_automagik_logo)
endef


# ===========================================
# 📋 Help System
# ===========================================
help: ## 🚀 Show this help message
	@$(call show_automagik_logo)
	@echo -e "$(FONT_BOLD)$(FONT_PURPLE)🚀 Automagik Suite$(FONT_RESET) - $(FONT_GRAY)Master Installation & Management$(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_YELLOW)🎯 Hybrid architecture: Docker infrastructure + Local PM2 services$(FONT_RESET)"
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
	@echo -e "$(FONT_CYAN)🌟 Optional Services:$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)start-langflow$(FONT_RESET)             Start LangFlow visual workflow builder"
	@echo -e "  $(FONT_GRAY)stop-langflow$(FONT_RESET)              Stop LangFlow"
	@echo -e "  $(FONT_GRAY)status-langflow$(FONT_RESET)            Check LangFlow status"
	@echo -e "  $(FONT_GRAY)start-evolution$(FONT_RESET)            Start Evolution API (WhatsApp)"
	@echo -e "  $(FONT_GRAY)stop-evolution$(FONT_RESET)             Stop Evolution API"
	@echo -e "  $(FONT_GRAY)status-evolution$(FONT_RESET)           Check Evolution API status"
	@echo ""
	@echo -e "$(FONT_CYAN)🔧 Advanced Commands (for troubleshooting):$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)install-all$(FONT_RESET)       Install services only"
	@echo -e "  $(FONT_GRAY)uninstall-all$(FONT_RESET)     Uninstall services only"
	@echo -e "  $(FONT_GRAY)start-all$(FONT_RESET)         Start services only"
	@echo -e "  $(FONT_GRAY)stop-all$(FONT_RESET)          Stop services only"
	@echo -e "  $(FONT_GRAY)start-infrastructure$(FONT_RESET)       Start infrastructure only"
	@echo -e "  $(FONT_GRAY)stop-infrastructure$(FONT_RESET)        Stop infrastructure only"
	@echo -e "  $(FONT_GRAY)uninstall-infrastructure$(FONT_RESET)   Uninstall infrastructure only"
	@echo ""
	@echo -e "$(FONT_CYAN)🔄 Git & Repository Management:$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)git-status$(FONT_RESET)                 Check uncommitted changes in all repositories"
	@echo -e "  $(FONT_GRAY)check-updates$(FONT_RESET)              Check if there are new pulls available from remote"
	@echo ""
	@echo -e "$(FONT_GRAY)Service Colors & Ports:$(FONT_RESET)"
	@echo -e "  $(AGENTS_COLOR)AGENTS$(FONT_RESET) (🎨 Bright Blue): $(FONT_CYAN)8881$(FONT_RESET)  |  $(SPARK_COLOR)SPARK$(FONT_RESET) (🎨 Yellow):   $(FONT_CYAN)8883$(FONT_RESET)"
	@echo -e "  $(TOOLS_COLOR)TOOLS$(FONT_RESET) (🎨 Blue):     $(FONT_CYAN)8884,8885$(FONT_RESET) |  $(OMNI_COLOR)OMNI$(FONT_RESET) (🎨 Purple):     $(FONT_CYAN)8882$(FONT_RESET)"
	@echo -e "  $(UI_COLOR)UI$(FONT_RESET) (🎨 Green):        $(FONT_CYAN)8888$(FONT_RESET)  |  Optional Services:"
	@echo -e "  $(FONT_CYAN)LANGFLOW$(FONT_RESET):       $(FONT_CYAN)7860$(FONT_RESET)  |  $(FONT_CYAN)EVOLUTION$(FONT_RESET):       $(FONT_CYAN)8080$(FONT_RESET)"
	@echo -e "  $(FONT_CYAN)📋 Use 'make logs' to see beautiful colorized output!$(FONT_RESET)"
	@echo ""

# ===========================================
# 🏗️ Infrastructure Management (Docker)
# ===========================================
install-infrastructure: start-infrastructure ## 🗄️ Install Docker infrastructure (alias for start)

start-infrastructure: ## 🚀 Start Docker infrastructure (idempotent)
	$(call print_status,Starting Docker infrastructure...)
	@if [ ! -f "$(INFRASTRUCTURE_COMPOSE)" ]; then \
		$(call print_error,Infrastructure compose file not found: $(INFRASTRUCTURE_COMPOSE)); \
		exit 1; \
	fi
	@echo -e "$(FONT_CYAN)$(INFO) Starting core infrastructure services...$(FONT_RESET)"
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) -p automagik up -d
	@$(call print_status,Waiting for infrastructure to be ready...)
	@sleep 10
	@$(call print_success,Docker infrastructure started successfully!)
	@$(call print_infrastructure_status)

stop-infrastructure: ## 🛑 Stop Docker infrastructure
	$(call print_status,Stopping Docker infrastructure...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) -p automagik stop
	@$(call print_success,Docker infrastructure stopped!)

uninstall-infrastructure: ## 🗑️ Uninstall Docker infrastructure (remove containers, images, volumes)
	$(call print_status,Uninstalling Docker infrastructure...)
	@# Capture initial disk usage
	@if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then \
		before_size=$$(docker system df --format "table {{.Size}}" | tail -n +2 | head -n 1 | sed 's/[^0-9.]//g' || echo "0"); \
	else \
		before_size="0"; \
	fi
	@# Remove all Automagik Docker resources quietly
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) -p automagik down -v --rmi all --remove-orphans >/dev/null 2>&1 || true
	@if [ -f "$(LANGFLOW_COMPOSE)" ]; then \
		$(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow down -v --rmi all --remove-orphans >/dev/null 2>&1 || true; \
	fi
	@if [ -f "$(EVOLUTION_COMPOSE)" ]; then \
		$(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api down -v --rmi all --remove-orphans >/dev/null 2>&1 || true; \
	fi
	@# Remove automagik docker project
	@if [ -f "automagik/docker/docker-compose.yml" ]; then \
		$(DOCKER_COMPOSE) -f automagik/docker/docker-compose.yml -p docker down -v --rmi all --remove-orphans >/dev/null 2>&1 || true; \
	fi
	@# Clean up any remaining resources
	@if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then \
		docker ps -aq --filter "label=com.docker.compose.project=automagik" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true; \
		docker ps -aq --filter "label=com.docker.compose.project=langflow" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true; \
		docker ps -aq --filter "label=com.docker.compose.project=evolution_api" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true; \
		docker ps -aq --filter "label=com.docker.compose.project=docker" 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1 || true; \
		docker volume ls -q --filter "label=com.docker.compose.project=automagik" 2>/dev/null | xargs -r docker volume rm >/dev/null 2>&1 || true; \
		docker volume ls -q --filter "label=com.docker.compose.project=langflow" 2>/dev/null | xargs -r docker volume rm >/dev/null 2>&1 || true; \
		docker volume ls -q --filter "label=com.docker.compose.project=evolution_api" 2>/dev/null | xargs -r docker volume rm >/dev/null 2>&1 || true; \
		docker volume ls -q --filter "label=com.docker.compose.project=docker" 2>/dev/null | xargs -r docker volume rm >/dev/null 2>&1 || true; \
		docker images --filter "reference=*langflow*" --filter "reference=*evolution*" --filter "reference=*postgres*" --filter "reference=*redis*" -q 2>/dev/null | xargs -r docker rmi -f >/dev/null 2>&1 || true; \
		docker system prune -f --volumes >/dev/null 2>&1 || true; \
		after_size=$$(docker system df --format "table {{.Size}}" | tail -n +2 | head -n 1 | sed 's/[^0-9.]//g' || echo "0"); \
		if [ "$$before_size" != "$$after_size" ]; then \
			echo -e "$(FONT_GREEN)✓ Freed Docker disk space$(FONT_RESET)"; \
		fi; \
	fi
	@$(call print_success,Docker infrastructure uninstalled!)

restart-infrastructure: ## 🔄 Restart Docker infrastructure
	$(call print_status,Restarting Docker infrastructure...)
	@$(MAKE) stop-infrastructure
	@sleep 2
	@$(MAKE) start-infrastructure

status-infrastructure: ## 📊 Check infrastructure status
	@$(call print_infrastructure_status)

# ===========================================
# 🌊 LangFlow Management (Optional Service)
# ===========================================
start-langflow: ## 🌊 Start LangFlow visual workflow builder
	$(call print_status,Starting LangFlow...)
	@if [ ! -f "$(LANGFLOW_COMPOSE)" ]; then \
		$(call print_error,LangFlow compose file not found: $(LANGFLOW_COMPOSE)); \
		exit 1; \
	fi
	@# Ensure LangFlow data directory exists with correct permissions
	@mkdir -p /root/data/langflow
	@chown -R 1000:1000 /root/data/langflow
	@# Using host network mode - no network creation needed
	@$(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow up -d
	@$(call print_status,Waiting for LangFlow to be ready...)
	@sleep 15
	@$(call print_success,LangFlow started successfully!)
	@echo -e "$(FONT_CYAN)🌊 LangFlow UI: http://localhost:7860$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)   Username: admin$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)   Password: automagik123$(FONT_RESET)"

stop-langflow: ## 🛑 Stop LangFlow
	$(call print_status,Stopping LangFlow...)
	@$(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow stop
	@$(call print_success,LangFlow stopped!)

restart-langflow: ## 🔄 Restart LangFlow
	$(call print_status,Restarting LangFlow...)
	@$(MAKE) stop-langflow
	@sleep 2
	@$(MAKE) start-langflow

status-langflow: ## 📊 Check LangFlow status
	@echo -e "$(FONT_CYAN)🌊 LangFlow Status:$(FONT_RESET)"
	@$(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow ps 2>/dev/null || echo "LangFlow not running"

# ===========================================
# 📱 Evolution API Management (Optional Service)
# ===========================================
start-evolution: ## 📱 Start Evolution API (WhatsApp integration)
	$(call print_status,Starting Evolution API...)
	@if [ ! -f "$(EVOLUTION_COMPOSE)" ]; then \
		$(call print_error,Evolution compose file not found: $(EVOLUTION_COMPOSE)); \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api up -d
	@$(call print_status,Waiting for Evolution API to be ready...)
	@sleep 20
	@$(call print_success,Evolution API started successfully!)
	@echo -e "$(FONT_CYAN)📱 Evolution API: http://localhost:8080$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)   API Key: namastex888$(FONT_RESET)"

stop-evolution: ## 🛑 Stop Evolution API
	$(call print_status,Stopping Evolution API...)
	@$(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api stop
	@$(call print_success,Evolution API stopped!)

restart-evolution: ## 🔄 Restart Evolution API
	$(call print_status,Restarting Evolution API...)
	@$(MAKE) stop-evolution
	@sleep 2
	@$(MAKE) start-evolution

status-evolution: ## 📊 Check Evolution API status
	@echo -e "$(FONT_CYAN)📱 Evolution API Status:$(FONT_RESET)"
	@$(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api ps 2>/dev/null || echo "Evolution API not running"

# ===========================================
# 📝 Environment Setup
# ===========================================
setup-env-files: ## 📝 Setup .env files from templates for main and all services
	$(call print_status,Setting up environment files...)
	@# Create main .env file if it doesn't exist
	@if [ ! -f .env ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Creating main .env file from template...$(FONT_RESET)"; \
		cp .env.example .env; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Main .env file created$(FONT_RESET)"; \
		echo -e "$(FONT_YELLOW)$(WARNING) Please update .env with your actual API keys and configuration$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Main .env file already exists$(FONT_RESET)"; \
	fi
	@# Create service .env files from their templates
	@for service in "automagik" "automagik-spark" "automagik-tools" "automagik-omni"; do \
		service_dir="$(SERVICES_DIR)/$$service"; \
		if [ -d "$$service_dir" ]; then \
			if [ -f "$$service_dir/.env.example" ] && [ ! -f "$$service_dir/.env" ]; then \
				echo -e "$(FONT_CYAN)$(INFO) Creating $$service/.env from template...$(FONT_RESET)"; \
				cp "$$service_dir/.env.example" "$$service_dir/.env"; \
				echo -e "$(FONT_GREEN)$(CHECKMARK) $$service/.env created$(FONT_RESET)"; \
			elif [ -f "$$service_dir/.env" ]; then \
				echo -e "$(FONT_GREEN)$(CHECKMARK) $$service/.env already exists$(FONT_RESET)"; \
			elif [ ! -f "$$service_dir/.env.example" ]; then \
				echo -e "$(FONT_YELLOW)$(WARNING) $$service/.env.example not found, skipping$(FONT_RESET)"; \
			fi; \
		fi; \
	done
	@# Handle automagik-ui with special .env.local pattern
	@service_dir="$(AUTOMAGIK_UI_DIR)"; \
	if [ -d "$$service_dir" ]; then \
		if [ -f "$$service_dir/.env.local.example" ] && [ ! -f "$$service_dir/.env.local" ]; then \
			echo -e "$(FONT_CYAN)$(INFO) Creating automagik-ui/.env.local from template...$(FONT_RESET)"; \
			cp "$$service_dir/.env.local.example" "$$service_dir/.env.local"; \
			echo -e "$(FONT_GREEN)$(CHECKMARK) automagik-ui/.env.local created$(FONT_RESET)"; \
		elif [ -f "$$service_dir/.env.local" ]; then \
			echo -e "$(FONT_GREEN)$(CHECKMARK) automagik-ui/.env.local already exists$(FONT_RESET)"; \
		elif [ ! -f "$$service_dir/.env.local.example" ]; then \
			echo -e "$(FONT_YELLOW)$(WARNING) automagik-ui/.env.local.example not found, skipping$(FONT_RESET)"; \
		fi; \
	fi
	@# Note: PM2 ecosystem.config.js loads the main .env and passes it to all services
	@$(call print_success,Environment files ready!)

sync-service-env-ports: ## 🔄 Sync port configuration from main .env to individual services
	$(call print_status,Syncing port configuration to services...)
	@# Extract port values from main .env file
	@AGENTS_PORT=$$(grep "^AUTOMAGIK_API_PORT=" .env | head -1 | cut -d'=' -f2); \
	OMNI_PORT=$$(grep "^AUTOMAGIK_OMNI_API_PORT=" .env | head -1 | cut -d'=' -f2); \
	SPARK_PORT=$$(grep "^AUTOMAGIK_SPARK_API_PORT=" .env | head -1 | cut -d'=' -f2); \
	TOOLS_SSE_PORT=$$(grep "^AUTOMAGIK_TOOLS_SSE_PORT=" .env | head -1 | cut -d'=' -f2); \
	TOOLS_HTTP_PORT=$$(grep "^AUTOMAGIK_TOOLS_HTTP_PORT=" .env | head -1 | cut -d'=' -f2); \
	UI_PORT=$$(grep "^AUTOMAGIK_UI_PORT=" .env | head -1 | cut -d'=' -f2); \
	echo -e "$(FONT_CYAN)$(INFO) Detected ports: Agents=$$AGENTS_PORT, Omni=$$OMNI_PORT, Spark=$$SPARK_PORT, Tools(SSE)=$$TOOLS_SSE_PORT, Tools(HTTP)=$$TOOLS_HTTP_PORT, UI=$$UI_PORT$(FONT_RESET)"; \
	if [ -n "$$AGENTS_PORT" ] && [ -f "$(AUTOMAGIK_DIR)/.env" ]; then \
		sed -i "s/AUTOMAGIK_API_PORT=.*/AUTOMAGIK_API_PORT=$$AGENTS_PORT/" "$(AUTOMAGIK_DIR)/.env"; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated agents port to $$AGENTS_PORT$(FONT_RESET)"; \
	fi; \
	if [ -n "$$OMNI_PORT" ] && [ -f "$(AUTOMAGIK_OMNI_DIR)/.env" ]; then \
		sed -i "s/AUTOMAGIK_OMNI_API_PORT=.*/AUTOMAGIK_OMNI_API_PORT=$$OMNI_PORT/" "$(AUTOMAGIK_OMNI_DIR)/.env"; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated omni port to $$OMNI_PORT$(FONT_RESET)"; \
	fi; \
	if [ -n "$$SPARK_PORT" ] && [ -f "$(AUTOMAGIK_SPARK_DIR)/.env" ]; then \
		sed -i "s/AUTOMAGIK_SPARK_API_PORT=.*/AUTOMAGIK_SPARK_API_PORT=$$SPARK_PORT/" "$(AUTOMAGIK_SPARK_DIR)/.env"; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated spark port to $$SPARK_PORT$(FONT_RESET)"; \
	fi; \
	if [ -n "$$TOOLS_SSE_PORT" ] && [ -f "$(AUTOMAGIK_TOOLS_DIR)/.env" ]; then \
		sed -i "s/^PORT=.*/PORT=$$TOOLS_SSE_PORT/" "$(AUTOMAGIK_TOOLS_DIR)/.env"; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated tools SSE port to $$TOOLS_SSE_PORT$(FONT_RESET)"; \
	fi; \
	if [ -n "$$TOOLS_HTTP_PORT" ] && [ -f "$(AUTOMAGIK_TOOLS_DIR)/.env" ]; then \
		sed -i "s/^AUTOMAGIK_TOOLS_PORT=.*/AUTOMAGIK_TOOLS_PORT=$$TOOLS_HTTP_PORT/" "$(AUTOMAGIK_TOOLS_DIR)/.env"; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated tools HTTP port to $$TOOLS_HTTP_PORT$(FONT_RESET)"; \
	fi; \
	if [ -n "$$UI_PORT" ] && [ -f "$(AUTOMAGIK_UI_DIR)/.env.local" ]; then \
		if ! grep -q "^PORT=" "$(AUTOMAGIK_UI_DIR)/.env.local"; then \
			echo "" >> "$(AUTOMAGIK_UI_DIR)/.env.local"; \
			echo "PORT=$$UI_PORT" >> "$(AUTOMAGIK_UI_DIR)/.env.local"; \
		else \
			sed -i "s/^PORT=.*/PORT=$$UI_PORT/" "$(AUTOMAGIK_UI_DIR)/.env.local"; \
		fi; \
		echo -e "$(FONT_GREEN)$(CHECKMARK) Updated UI port to $$UI_PORT$(FONT_RESET)"; \
	fi
	@$(call print_success,Port synchronization completed!)

env: ## 🔄 Sync main .env to all service .env files (master source of truth)
	$(call print_status,Synchronizing environment variables to all services...)
	@$(PROJECT_ROOT)/scripts/env-manager.sh sync
	@$(call print_success,Environment synchronization completed!)

env-status: ## 📊 Show environment synchronization status across all services
	$(call print_status,Checking environment status...)
	@$(PROJECT_ROOT)/scripts/env-manager.sh status

# ===========================================
# 🏗️ Service Building (Optimized)
# ===========================================


# UI build logic moved to automagik-ui/Makefile install target

# ===========================================
# ⚙️ Service Installation
# ===========================================
install-all: ## ⚙️ Install all services and setup PM2
	$(call print_status,Installing all Automagik services...)
	@# Install services in dependency order
	@$(MAKE) install-agents
	@$(MAKE) install-spark
	@$(MAKE) install-omni
	@$(MAKE) install-ui
	@# Install tools library
	@$(MAKE) install-tools
	@# Setup PM2 ecosystem
	@$(MAKE) setup-pm2
	@$(call print_success,All services installed successfully!)

setup-pm2: ## 📦 Setup PM2 with ecosystem file
	$(call print_status,Setting up PM2 ecosystem...)
	@if ! command -v pm2 >/dev/null 2>&1; then \
		echo -e "$(FONT_RED)Error: PM2 not found. Install with: npm install -g pm2$(FONT_RESET)"; \
		exit 1; \
	fi
	@echo -e "$(FONT_CYAN)$(INFO) Installing PM2 log rotation...$(FONT_RESET)"
	@if ! pm2 list | grep -q pm2-logrotate; then \
		pm2 install pm2-logrotate >/dev/null 2>&1; \
	else \
		echo -e "$(FONT_GREEN)✓ PM2 logrotate already installed$(FONT_RESET)"; \
	fi
	@pm2 set pm2-logrotate:max_size 100M >/dev/null 2>&1
	@pm2 set pm2-logrotate:retain 7 >/dev/null 2>&1
	@pm2 set pm2-logrotate:compress false >/dev/null 2>&1
	@pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss >/dev/null 2>&1
	@pm2 set pm2-logrotate:workerInterval 30 >/dev/null 2>&1
	@pm2 set pm2-logrotate:rotateInterval 0 0 * * * >/dev/null 2>&1
	@pm2 set pm2-logrotate:rotateModule true >/dev/null 2>&1
	@echo -e "$(FONT_CYAN)$(INFO) Setting up PM2 startup...$(FONT_RESET)"
	@pm2 startup -s >/dev/null 2>&1 || echo -e "$(FONT_GRAY)✓ PM2 startup already configured$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)$(INFO) Registering services with PM2...$(FONT_RESET)"
	@# Delete only Automagik services, not all PM2 processes
	@for service in $(PM2_SERVICES); do \
		pm2 describe $$service >/dev/null 2>&1 && pm2 delete $$service >/dev/null 2>&1 || true; \
	done
	@# Start each service from its own ecosystem config
	@cd $(AUTOMAGIK_DIR) && pm2 start ecosystem.config.js >/dev/null 2>&1 || true
	@cd $(AUTOMAGIK_SPARK_DIR) && pm2 start ecosystem.config.js >/dev/null 2>&1 || true
	@cd $(AUTOMAGIK_TOOLS_DIR) && pm2 start ecosystem.config.js >/dev/null 2>&1 || true
	@cd $(AUTOMAGIK_OMNI_DIR) && pm2 start ecosystem.config.js >/dev/null 2>&1 || true
	@cd $(AUTOMAGIK_UI_DIR) && pm2 start ecosystem.prod.config.js >/dev/null 2>&1 || true
	@echo -e "$(FONT_GRAY)Services registered (will start when needed)$(FONT_RESET)"
	@pm2 save --force >/dev/null 2>&1 || true
	@echo -e "$(FONT_GREEN)✓ PM2 ecosystem configured$(FONT_RESET)"

install-dependencies-only: ## 📦 Install only dependencies (no service registration)
	$(call print_status,Installing dependencies for all services...)
	@# Install Python dependencies for each service
	@if [ -d "$(AUTOMAGIK_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_DIR)" && AUTOMAGIK_QUIET_LOGO=1 make install >/dev/null 2>&1 || true; \
	fi
	@if [ -d "$(AUTOMAGIK_SPARK_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-spark...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_SPARK_DIR)" && AUTOMAGIK_QUIET_LOGO=1 make install >/dev/null 2>&1 || true; \
	fi
	@if [ -d "$(AUTOMAGIK_TOOLS_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-tools...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_TOOLS_DIR)" && AUTOMAGIK_QUIET_LOGO=1 make install >/dev/null 2>&1 || true; \
	fi
	@if [ -d "$(AUTOMAGIK_OMNI_DIR)" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Installing dependencies for automagik-omni...$(FONT_RESET)"; \
		cd "$(AUTOMAGIK_OMNI_DIR)" && AUTOMAGIK_QUIET_LOGO=1 make install >/dev/null 2>&1 || true; \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),install)
	@$(call print_success,All dependencies installed!)

install-agents: ## Install automagik service
	$(call print_status,Installing $(AGENTS_COLOR)automagik$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_DIR)" ]; then \
		$(call ensure_repository,automagik,$(AUTOMAGIK_DIR),$(AUTOMAGIK_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_DIR),install)

install-spark: ## Install automagik-spark service
	$(call print_status,Installing $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_SPARK_DIR)" ]; then \
		$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_SPARK_DIR),install)

install-tools: ## Install automagik-tools service
	$(call print_status,Installing $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_TOOLS_DIR)" ]; then \
		$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_TOOLS_DIR),install)

install-omni: ## Install automagik-omni service
	$(call print_status,Installing $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_OMNI_DIR)" ]; then \
		$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_OMNI_DIR),install)

install-ui: ## Install automagik-ui service
	$(call print_status,Installing $(UI_COLOR)automagik-ui$(FONT_RESET) service...)
	@if [ ! -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		$(call ensure_repository,automagik-ui,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL)); \
	fi
	$(call delegate_to_service,$(AUTOMAGIK_UI_DIR),install)

uninstall-all: ## 🗑️ Uninstall all services (remove PM2 services)
	$(call print_status,Uninstalling all Automagik services...)
	@# Remove PM2 services
	@echo -e "$(FONT_CYAN)$(INFO) Removing PM2 services...$(FONT_RESET)"
	@# Stop and delete all PM2 processes
	@if pm2 list 2>/dev/null | grep -q "online\|stopped\|errored"; then \
		echo -e "$(FONT_CYAN)$(INFO) Stopping all PM2 processes...$(FONT_RESET)"; \
		pm2 stop all 2>/dev/null || true; \
		echo -e "$(FONT_CYAN)$(INFO) Deleting all PM2 processes...$(FONT_RESET)"; \
		pm2 delete all 2>/dev/null || true; \
	else \
		echo -e "$(FONT_GRAY)$(INFO) No PM2 processes found to remove$(FONT_RESET)"; \
	fi
	@echo -e "$(FONT_CYAN)$(INFO) Removing PM2 logrotate module...$(FONT_RESET)"
	@pm2 uninstall pm2-logrotate 2>/dev/null || true
	@echo -e "$(FONT_CYAN)$(INFO) Saving PM2 configuration...$(FONT_RESET)"
	@pm2 save --force 2>/dev/null || true
	@$(call print_success,All services uninstalled!)

uninstall: ## 🗑️ Complete uninstall (stop everything, remove services and infrastructure)
	$(call print_status,Complete Automagik uninstall...)
	@$(MAKE) stop
	@$(MAKE) uninstall-all
	@$(MAKE) uninstall-infrastructure
	@$(call print_success,Complete uninstall finished!)

# ===========================================
# 🎛️ Service Management
# ===========================================
start-all: ## 🚀 Start all services with PM2
	$(call print_status,Starting all Automagik services with PM2...)
	@cd $(AUTOMAGIK_DIR) && pm2 start ecosystem.config.js
	@cd $(AUTOMAGIK_SPARK_DIR) && pm2 start ecosystem.config.js
	@cd $(AUTOMAGIK_TOOLS_DIR) && pm2 start ecosystem.config.js
	@cd $(AUTOMAGIK_OMNI_DIR) && pm2 start ecosystem.config.js
	@cd $(AUTOMAGIK_UI_DIR) && pm2 start ecosystem.prod.config.js
	@$(call print_success,All services started!)


stop-all: ## 🛑 Stop all services with PM2
	$(call print_status,Stopping all Automagik services...)
	@# Stop all PM2 processes (more robust than hardcoded names)
	@if pm2 list 2>/dev/null | grep -q "online\|stopped\|errored"; then \
		echo -e "$(FONT_CYAN)$(INFO) Stopping all PM2 processes...$(FONT_RESET)"; \
		pm2 stop all 2>/dev/null || true; \
	else \
		echo -e "$(FONT_GRAY)$(INFO) No PM2 processes found to stop$(FONT_RESET)"; \
	fi
	@$(call print_success,All services stopped!)

restart-all: ## 🔄 Restart everything (PM2 services + infrastructure)
	$(call print_status,🔄 Restarting complete Automagik stack...)
	@$(MAKE) stop
	@sleep 3
	@$(MAKE) start
	@$(call print_success,Complete stack restarted!)

status-all: ## 📊 Check status of all services
	@echo -e "$(FONT_PURPLE)$(CHART) Automagik Services Status:$(FONT_RESET)"
	@pm2 list | sed -E \
		-e 's/(automagik)/\x1b[94m\1\x1b[0m/g' \
		-e 's/(automagik-spark-api|automagik-spark-worker)/\x1b[33m\1\x1b[0m/g' \
		-e 's/(automagik-tools-sse|automagik-tools-http)/\x1b[34m\1\x1b[0m/g' \
		-e 's/(automagik-omni)/\x1b[35m\1\x1b[0m/g' \
		-e 's/(automagik-ui)/\x1b[32m\1\x1b[0m/g' \
		-e 's/online/\x1b[32monline\x1b[0m/g' \
		-e 's/stopped/\x1b[33mstopped\x1b[0m/g' \
		-e 's/errored/\x1b[31merrored\x1b[0m/g'
	@echo ""
	@$(call print_infrastructure_status)
	@echo ""
	@echo -e "$(FONT_CYAN)🌟 Optional Services:$(FONT_RESET)"
	@echo -n -e "$(FONT_BLUE)🌊 LangFlow: $(FONT_RESET)"
	@if $(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow ps 2>/dev/null | grep -q "(healthy)"; then \
		echo -e "$(FONT_GREEN)online$(FONT_RESET) (http://localhost:7860)"; \
	elif $(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow ps 2>/dev/null | grep -q "Up"; then \
		echo -e "$(FONT_YELLOW)starting$(FONT_RESET) (http://localhost:7860)"; \
	else \
		echo -e "$(FONT_YELLOW)stopped$(FONT_RESET)"; \
	fi
	@echo -n -e "$(FONT_BLUE)📱 Evolution API: $(FONT_RESET)"
	@if $(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api ps 2>/dev/null | grep -q "(healthy)"; then \
		echo -e "$(FONT_GREEN)online$(FONT_RESET) (http://localhost:8080)"; \
	elif $(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api ps 2>/dev/null | grep -q "Up"; then \
		echo -e "$(FONT_YELLOW)starting$(FONT_RESET) (http://localhost:8080)"; \
	else \
		echo -e "$(FONT_YELLOW)stopped$(FONT_RESET)"; \
	fi

# ===========================================
# 🔧 Individual Service Commands
# ===========================================

# Individual Start Commands
start-agents: ## 🚀 Start automagik service only
	$(call print_status,Starting $(AGENTS_COLOR)automagik$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_DIR) && pm2 start ecosystem.config.js


start-spark: ## 🚀 Start automagik-spark services (API + Worker)
	$(call print_status,Starting $(SPARK_COLOR)automagik-spark$(FONT_RESET) services...)
	@cd $(AUTOMAGIK_SPARK_DIR) && pm2 start ecosystem.config.js
	@echo -e "$(FONT_CYAN)   API: http://localhost:8883$(FONT_RESET)"


start-tools: ## 🚀 Start automagik-tools services (SSE + HTTP)
	$(call print_status,Starting $(TOOLS_COLOR)automagik-tools$(FONT_RESET) services...)
	@cd $(AUTOMAGIK_TOOLS_DIR) && pm2 start ecosystem.config.js
	@echo -e "$(FONT_CYAN)   SSE Transport: http://localhost:8884$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)   HTTP Transport: http://localhost:8885$(FONT_RESET)"


start-omni: ## 🚀 Start automagik-omni service only
	$(call print_status,Starting $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_OMNI_DIR) && pm2 start ecosystem.config.js


start-ui: ## 🚀 Start automagik-ui service only (PM2)
	$(call print_status,Starting $(UI_COLOR)automagik-ui$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_UI_DIR) && pm2 start ecosystem.prod.config.js


# Individual Stop Commands
stop-agents: ## 🛑 Stop automagik service only
	$(call print_status,Stopping $(AGENTS_COLOR)automagik$(FONT_RESET) service...)
	@pm2 stop automagik 2>/dev/null || true

stop-spark: ## 🛑 Stop automagik-spark services (API + Worker)
	$(call print_status,Stopping $(SPARK_COLOR)automagik-spark$(FONT_RESET) services...)
	@pm2 stop automagik-spark-api automagik-spark-worker 2>/dev/null || true

stop-tools: ## 🛑 Stop automagik-tools services (SSE + HTTP)
	$(call print_status,Stopping $(TOOLS_COLOR)automagik-tools$(FONT_RESET) services...)
	@pm2 stop automagik-tools-sse automagik-tools-http 2>/dev/null || true

stop-omni: ## 🛑 Stop automagik-omni service only
	$(call print_status,Stopping $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@pm2 stop automagik-omni 2>/dev/null || true

stop-ui: ## 🛑 Stop automagik-ui service only (PM2)
	$(call print_status,Stopping $(UI_COLOR)automagik-ui$(FONT_RESET) service...)
	@pm2 stop automagik-ui 2>/dev/null || true

# Individual Restart Commands
restart-agents: ## 🔄 Restart automagik service only
	$(call print_status,Restarting $(AGENTS_COLOR)automagik$(FONT_RESET) service...)
	@pm2 restart automagik 2>/dev/null || (cd $(AUTOMAGIK_DIR) && pm2 start ecosystem.config.js)

restart-spark: ## 🔄 Restart automagik-spark services (API + Worker)
	$(call print_status,Restarting $(SPARK_COLOR)automagik-spark$(FONT_RESET) services...)
	@pm2 restart automagik-spark-api automagik-spark-worker 2>/dev/null || (cd $(AUTOMAGIK_SPARK_DIR) && pm2 start ecosystem.config.js)

restart-tools: ## 🔄 Restart automagik-tools services (SSE + HTTP)
	$(call print_status,Restarting $(TOOLS_COLOR)automagik-tools$(FONT_RESET) services...)
	@pm2 restart automagik-tools-sse automagik-tools-http 2>/dev/null || (cd $(AUTOMAGIK_TOOLS_DIR) && pm2 start ecosystem.config.js)

restart-omni: ## 🔄 Restart automagik-omni service only
	$(call print_status,Restarting $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@pm2 restart automagik-omni 2>/dev/null || (cd $(AUTOMAGIK_OMNI_DIR) && pm2 start ecosystem.config.js)

restart-ui: ## 🔄 Restart automagik-ui service only (PM2)
	$(call print_status,Restarting $(UI_COLOR)automagik-ui$(FONT_RESET) service...)
	@pm2 restart automagik-ui 2>/dev/null || (cd $(AUTOMAGIK_UI_DIR) && pm2 start ecosystem.prod.config.js)

restart-ui-with-build: ## 🔄 Rebuild and restart automagik-ui service (PM2)
	$(call print_status,Rebuilding and restarting $(UI_COLOR)automagik-ui$(FONT_RESET) service...)
	@if [ -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		cd $(AUTOMAGIK_UI_DIR) && \
		echo -e "$(FONT_CYAN)📦 Installing dependencies...$(FONT_RESET)" && \
		pnpm install && \
		echo -e "$(FONT_CYAN)🔨 Building UI...$(FONT_RESET)" && \
		pnpm build && \
		echo -e "$(FONT_CYAN)🔄 Restarting UI service...$(FONT_RESET)" && \
		pm2 restart automagik-ui 2>/dev/null || pm2 start ecosystem.prod.config.js; \
		echo -e "$(FONT_GREEN)✅ UI rebuilt and restarted successfully!$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_RED)❌ automagik-ui directory not found at $(AUTOMAGIK_UI_DIR)$(FONT_RESET)"; \
		exit 1; \
	fi

# Individual Status Commands
status-agents: ## 📊 Check automagik status only
	$(call print_status,Checking $(AGENTS_COLOR)automagik$(FONT_RESET) status...)
	@pm2 show automagik 2>/dev/null || echo "Service not found"

status-spark: ## 📊 Check automagik-spark status (API + Worker)
	$(call print_status,Checking $(SPARK_COLOR)automagik-spark$(FONT_RESET) status...)
	@echo -e "$(FONT_CYAN)API Service:$(FONT_RESET)"
	@pm2 show automagik-spark-api 2>/dev/null || echo "API service not found"
	@echo ""
	@echo -e "$(FONT_CYAN)Worker Service:$(FONT_RESET)"
	@pm2 show automagik-spark-worker 2>/dev/null || echo "Worker service not found"

status-tools: ## 📊 Check automagik-tools status (SSE + HTTP)
	$(call print_status,Checking $(TOOLS_COLOR)automagik-tools$(FONT_RESET) status...)
	@echo -e "$(FONT_CYAN)SSE Service (port 8884):$(FONT_RESET)"
	@pm2 show automagik-tools-sse 2>/dev/null || echo "SSE service not found"
	@echo ""
	@echo -e "$(FONT_CYAN)HTTP Service (port 8885):$(FONT_RESET)"
	@pm2 show automagik-tools-http 2>/dev/null || echo "HTTP service not found"

status-omni: ## 📊 Check automagik-omni status only
	$(call print_status,Checking $(OMNI_COLOR)automagik-omni$(FONT_RESET) status...)
	@pm2 show automagik-omni 2>/dev/null || echo "Service not found"

status-ui: ## 📊 Check automagik-ui status only
	$(call print_status,Checking $(UI_COLOR)automagik-ui$(FONT_RESET) status...)
	@pm2 show automagik-ui 2>/dev/null || echo "Service not found"

# ===========================================
# 📋 Logging & Monitoring
# ===========================================
logs-all: logs ## 📋 Follow logs from all services (alias for logs)

logs-agents: ## 📋 Follow automagik logs
	$(call print_status,Following $(AGENTS_COLOR)automagik$(FONT_RESET) logs...)
	@pm2 logs automagik

logs-spark: ## 📋 Follow automagik-spark logs (API + Worker)
	$(call print_status,Following $(SPARK_COLOR)automagik-spark$(FONT_RESET) logs...)
	@pm2 logs automagik-spark-api automagik-spark-worker

logs-spark-api: ## 📋 Follow automagik-spark-api logs
	$(call print_status,Following $(SPARK_COLOR)automagik-spark-api$(FONT_RESET) logs...)
	@pm2 logs automagik-spark-api

logs-spark-worker: ## 📋 Follow automagik-spark-worker logs
	$(call print_status,Following $(SPARK_COLOR)automagik-spark-worker$(FONT_RESET) logs...)
	@pm2 logs automagik-spark-worker

logs-tools: ## 📋 Follow automagik-tools logs (SSE + HTTP)
	$(call print_status,Following $(TOOLS_COLOR)automagik-tools$(FONT_RESET) logs...)
	@pm2 logs automagik-tools-sse automagik-tools-http

logs-tools-sse: ## 📋 Follow automagik-tools-sse logs
	$(call print_status,Following $(TOOLS_COLOR)automagik-tools-sse$(FONT_RESET) logs...)
	@pm2 logs automagik-tools-sse

logs-tools-http: ## 📋 Follow automagik-tools-http logs
	$(call print_status,Following $(TOOLS_COLOR)automagik-tools-http$(FONT_RESET) logs...)
	@pm2 logs automagik-tools-http

logs-omni: ## 📋 Follow automagik-omni logs
	$(call print_status,Following $(OMNI_COLOR)automagik-omni$(FONT_RESET) logs...)
	@pm2 logs automagik-omni

logs-ui: ## 📋 Follow automagik-ui logs
	$(call print_status,Following $(UI_COLOR)automagik-ui$(FONT_RESET) logs...)
	@pm2 logs automagik-ui

logs-infrastructure: ## 📋 Follow Docker infrastructure logs
	$(call print_status,Following Docker infrastructure logs...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) logs -f

# ===========================================
# 🔧 Maintenance & Health
# ===========================================


clean-all: ## 🧹 Clean all service artifacts (parallel execution)
	$(call print_status,Cleaning all service artifacts...)
	@echo -e "$(FONT_CYAN)$(INFO) Cleaning services in parallel...$(FONT_RESET)"
	@for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR); do \
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
	@for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			(echo -e "Cleaning $$(basename $$service_dir)..."; cd $$service_dir && make clean 2>/dev/null || true) & \
		fi; \
	done
	@wait
	@$(call print_success,Essential services cleaned!)

clean-uv-cache: ## 🧹 Clean UV cache to resolve installation issues
	$(call print_status,Cleaning UV cache...)
	@if command -v uv >/dev/null 2>&1; then \
		uv cache clean; \
		$(call print_success,UV cache cleaned!); \
	elif [ -f "$$HOME/.local/bin/uv" ]; then \
		$$HOME/.local/bin/uv cache clean; \
		$(call print_success,UV cache cleaned!); \
	else \
		$(call print_warning,UV not found - cache cleaning skipped); \
	fi

git-status: ## 📋 Check uncommitted changes in all repositories
	$(call print_status,Checking git status across all repositories...)
	@echo -e "$(FONT_PURPLE)$(INFO) Repository Status Overview:$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)──────────────────────────────────────────────────────────────────────$(FONT_RESET)"
	@# Check main repository
	@repo_name="automagik-start"; \
	if [ -d ".git" ]; then \
		if git diff --quiet && git diff --cached --quiet; then \
			if [ -z "$$(git status --porcelain)" ]; then \
				echo -e "  $(FONT_GREEN)$(CHECKMARK) $$repo_name$(FONT_RESET) - Clean (no changes)"; \
			else \
				echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - Has untracked files"; \
			fi; \
		else \
			echo -e "  $(FONT_RED)$(ERROR) $$repo_name$(FONT_RESET) - Has uncommitted changes"; \
		fi; \
	else \
		echo -e "  $(FONT_GRAY)$(INFO) $$repo_name$(FONT_RESET) - Not a git repository"; \
	fi
	@# Check all service repositories
	@for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			repo_name=$$(basename $$service_dir); \
			if [ -d "$$service_dir/.git" ]; then \
				cd $$service_dir; \
				if git diff --quiet && git diff --cached --quiet; then \
					if [ -z "$$(git status --porcelain)" ]; then \
						echo -e "  $(FONT_GREEN)$(CHECKMARK) $$repo_name$(FONT_RESET) - Clean (no changes)"; \
					else \
						echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - Has untracked files"; \
					fi; \
				else \
					echo -e "  $(FONT_RED)$(ERROR) $$repo_name$(FONT_RESET) - Has uncommitted changes"; \
				fi; \
				cd - >/dev/null; \
			else \
				echo -e "  $(FONT_GRAY)$(INFO) $$repo_name$(FONT_RESET) - Not a git repository"; \
			fi; \
		else \
			repo_name=$$(basename $$service_dir); \
			echo -e "  $(FONT_GRAY)$(WARNING) $$repo_name$(FONT_RESET) - Directory not found"; \
		fi; \
	done
	@echo ""
	@$(call print_success,Git status check completed!)

check-updates: ## 🔄 Check if there are new pulls available from remote
	$(call print_status,Checking for available updates from remote repositories...)
	@echo -e "$(FONT_PURPLE)$(INFO) Remote Update Status:$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)──────────────────────────────────────────────────────────────────────$(FONT_RESET)"
	@# Check main repository
	@repo_name="automagik-start"; \
	if [ -d ".git" ]; then \
		echo -e "$(FONT_CYAN)$(INFO) Fetching latest from $$repo_name...$(FONT_RESET)"; \
		if git fetch origin >/dev/null 2>&1; then \
			current_branch=$$(git rev-parse --abbrev-ref HEAD); \
			if git rev-parse --verify origin/$$current_branch >/dev/null 2>&1; then \
				local_commit=$$(git rev-parse HEAD); \
				remote_commit=$$(git rev-parse origin/$$current_branch); \
				if [ "$$local_commit" = "$$remote_commit" ]; then \
					echo -e "  $(FONT_GREEN)$(CHECKMARK) $$repo_name$(FONT_RESET) - Up to date"; \
				else \
					behind_count=$$(git rev-list --count HEAD..origin/$$current_branch 2>/dev/null || echo "0"); \
					ahead_count=$$(git rev-list --count origin/$$current_branch..HEAD 2>/dev/null || echo "0"); \
					if [ "$$behind_count" -gt 0 ] && [ "$$ahead_count" -gt 0 ]; then \
						echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - $$behind_count commits behind, $$ahead_count commits ahead"; \
					elif [ "$$behind_count" -gt 0 ]; then \
						echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - $$behind_count commits behind remote"; \
					elif [ "$$ahead_count" -gt 0 ]; then \
						echo -e "  $(FONT_CYAN)$(INFO) $$repo_name$(FONT_RESET) - $$ahead_count commits ahead of remote"; \
					fi; \
				fi; \
			else \
				echo -e "  $(FONT_GRAY)$(WARNING) $$repo_name$(FONT_RESET) - No remote tracking branch"; \
			fi; \
		else \
			echo -e "  $(FONT_RED)$(ERROR) $$repo_name$(FONT_RESET) - Failed to fetch from remote"; \
		fi; \
	else \
		echo -e "  $(FONT_GRAY)$(INFO) $$repo_name$(FONT_RESET) - Not a git repository"; \
	fi
	@# Check all service repositories
	@for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			repo_name=$$(basename $$service_dir); \
			if [ -d "$$service_dir/.git" ]; then \
				cd $$service_dir; \
				echo -e "$(FONT_CYAN)$(INFO) Fetching latest from $$repo_name...$(FONT_RESET)"; \
				if git fetch origin >/dev/null 2>&1; then \
					current_branch=$$(git rev-parse --abbrev-ref HEAD); \
					if git rev-parse --verify origin/$$current_branch >/dev/null 2>&1; then \
						local_commit=$$(git rev-parse HEAD); \
						remote_commit=$$(git rev-parse origin/$$current_branch); \
						if [ "$$local_commit" = "$$remote_commit" ]; then \
							echo -e "  $(FONT_GREEN)$(CHECKMARK) $$repo_name$(FONT_RESET) - Up to date"; \
						else \
							behind_count=$$(git rev-list --count HEAD..origin/$$current_branch 2>/dev/null || echo "0"); \
							ahead_count=$$(git rev-list --count origin/$$current_branch..HEAD 2>/dev/null || echo "0"); \
							if [ "$$behind_count" -gt 0 ] && [ "$$ahead_count" -gt 0 ]; then \
								echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - $$behind_count commits behind, $$ahead_count commits ahead"; \
							elif [ "$$behind_count" -gt 0 ]; then \
								echo -e "  $(FONT_YELLOW)$(WARNING) $$repo_name$(FONT_RESET) - $$behind_count commits behind remote"; \
							elif [ "$$ahead_count" -gt 0 ]; then \
								echo -e "  $(FONT_CYAN)$(INFO) $$repo_name$(FONT_RESET) - $$ahead_count commits ahead of remote"; \
							fi; \
						fi; \
					else \
						echo -e "  $(FONT_GRAY)$(WARNING) $$repo_name$(FONT_RESET) - No remote tracking branch"; \
					fi; \
				else \
					echo -e "  $(FONT_RED)$(ERROR) $$repo_name$(FONT_RESET) - Failed to fetch from remote"; \
				fi; \
				cd - >/dev/null; \
			else \
				echo -e "  $(FONT_GRAY)$(INFO) $$repo_name$(FONT_RESET) - Not a git repository"; \
			fi; \
		else \
			repo_name=$$(basename $$service_dir); \
			echo -e "  $(FONT_GRAY)$(WARNING) $$repo_name$(FONT_RESET) - Directory not found"; \
		fi; \
	done
	@echo ""
	@$(call print_success,Update check completed!)

# ===========================================
# 📚 Docker Preservation (Legacy Support)
# ===========================================
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


install: ## 🚀 Install Automagik suite (infrastructure + services - no auto-start)
	$(call print_status,🚀 Installing Automagik suite...)
	@# Clone all repositories first
	@$(call ensure_repository,automagik,$(AUTOMAGIK_DIR),$(AUTOMAGIK_URL))
	@$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@$(call ensure_repository,automagik-ui,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@# Now setup environment files after all repos exist
	@$(MAKE) setup-env-files
	@# Start infrastructure automatically if not running
	@echo -e "$(FONT_CYAN)🔄 Ensuring infrastructure is running...$(FONT_RESET)"
	@if docker ps --filter "name=automagik-postgres" --filter "status=running" --format "{{.Names}}" | grep -q "automagik-postgres" && \
	   docker ps --filter "name=automagik-spark-postgres" --filter "status=running" --format "{{.Names}}" | grep -q "automagik-spark-postgres" && \
	   docker ps --filter "name=automagik-spark-redis" --filter "status=running" --format "{{.Names}}" | grep -q "automagik-spark-redis"; then \
		echo -e "$(FONT_GREEN)✓ Infrastructure containers are already running and ready$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_YELLOW)⚡ Infrastructure containers not running, starting them automatically...$(FONT_RESET)"; \
		$(MAKE) start-infrastructure; \
	fi
	@# Build step not needed for UV-based projects
	@echo ""
	@$(MAKE) install-all
	@# Sync port configuration from main .env to individual services AFTER installation
	@$(MAKE) sync-service-env-ports
	@# Sync all environment variables from master .env to all services (single source of truth)
	@$(MAKE) env
	@$(call print_success_with_logo,Installation completed!)
	@echo -e "$(FONT_CYAN)🎯 Next Steps:$(FONT_RESET)"
	@echo -e "  $(FONT_BOLD)$(FONT_GREEN)make start$(FONT_RESET)    - Start all services"
	@echo -e "  $(FONT_BOLD)$(FONT_YELLOW)make stop$(FONT_RESET)     - Stop all services"
	@echo -e "  $(FONT_BOLD)$(FONT_PURPLE)make restart$(FONT_RESET)  - Restart all services"
	@echo -e "  $(FONT_BOLD)$(FONT_CYAN)make status$(FONT_RESET)   - Check service status"
	@echo -e "  $(FONT_BOLD)$(FONT_BLUE)make logs$(FONT_RESET)     - View service logs"
	@echo -e "  $(FONT_BOLD)$(FONT_GRAY)make help$(FONT_RESET)     - See all available commands"
	@echo ""
	@echo -e "$(FONT_CYAN)🌐 Access URLs (after running 'make start'):$(FONT_RESET)"
	@echo -e "  $(FONT_BOLD)Frontend:$(FONT_RESET) $(FONT_CYAN)http://localhost:8888$(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_CYAN)📚 API Documentation:$(FONT_RESET)"
	@echo -e "  $(AGENTS_COLOR)Agents:$(FONT_RESET)  $(FONT_CYAN)http://localhost:8881/api/v1/docs$(FONT_RESET)"
	@echo -e "  $(OMNI_COLOR)Omni:$(FONT_RESET)    $(FONT_CYAN)http://localhost:8882/api/v1/docs$(FONT_RESET)"
	@echo -e "  $(SPARK_COLOR)Spark:$(FONT_RESET)   $(FONT_CYAN)http://localhost:8883/api/v1/docs$(FONT_RESET)"
	@echo -e "  $(TOOLS_COLOR)Tools:$(FONT_RESET)   $(FONT_CYAN)http://localhost:8884/sse$(FONT_RESET) | $(FONT_CYAN)http://localhost:8885/mcp$(FONT_RESET)"
	@echo ""
	@echo -e "$(FONT_YELLOW)💡 Services are installed but not started automatically$(FONT_RESET)"
	@echo -e "$(FONT_YELLOW)   Run '$(FONT_BOLD)make start$(FONT_RESET)$(FONT_YELLOW)' to begin using Automagik!$(FONT_RESET)"

install-full: ## 🚀 Complete installation (includes UI build - slower but fully ready)
	$(call print_status,🚀 Installing complete Automagik suite with UI build...)
	@# Clone all repositories first
	@$(call ensure_repository,automagik,$(AUTOMAGIK_DIR),$(AUTOMAGIK_URL))
	@$(call ensure_repository,automagik-spark,$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))
	@$(call ensure_repository,automagik-tools,$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))
	@$(call ensure_repository,automagik-omni,$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))
	@$(call ensure_repository,automagik-ui,$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))
	@# Now setup environment files after all repos exist
	@$(MAKE) setup-env-files
	@$(MAKE) start-infrastructure
	@# Build step not needed for UV-based projects
	@$(MAKE) install-all
	@$(MAKE) start-all
	@$(call print_success_with_logo,Complete installation finished!)
	@echo -e "$(FONT_CYAN)🌐 Frontend: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 API: http://localhost:8881$(FONT_RESET)"

start: ## 🚀 Start everything (infrastructure + optional services + PM2 services)
	$(call print_status,🚀 Starting complete Automagik stack...)
	@echo -e "$(FONT_CYAN)[1/3] Starting all Docker containers in parallel...$(FONT_RESET)"
	@# Start infrastructure and optional services in parallel
	@{ \
		$(MAKE) start-infrastructure > /tmp/automagik-infra.log 2>&1 & \
		INFRA_PID=$$!; \
		$(MAKE) start-langflow > /tmp/automagik-langflow.log 2>&1 & \
		LANG_PID=$$!; \
		$(MAKE) start-evolution > /tmp/automagik-evolution.log 2>&1 & \
		EVO_PID=$$!; \
		echo -e "  • Infrastructure starting (PID: $$INFRA_PID)"; \
		echo -e "  • LangFlow starting (PID: $$LANG_PID)"; \
		echo -e "  • Evolution API starting (PID: $$EVO_PID)"; \
		echo ""; \
		echo -n "Waiting for containers to start"; \
		wait $$INFRA_PID && echo -e "\n  $(FONT_GREEN)✓$(FONT_RESET) Infrastructure started" || echo -e "\n  $(FONT_YELLOW)⚠$(FONT_RESET) Infrastructure failed"; \
		wait $$LANG_PID && echo -e "  $(FONT_GREEN)✓$(FONT_RESET) LangFlow started" || echo -e "  $(FONT_YELLOW)⚠$(FONT_RESET) LangFlow not available"; \
		wait $$EVO_PID && echo -e "  $(FONT_GREEN)✓$(FONT_RESET) Evolution API started" || echo -e "  $(FONT_YELLOW)⚠$(FONT_RESET) Evolution API not available"; \
	}
	@echo ""
	@echo -e "$(FONT_CYAN)[2/3] Waiting for containers to be healthy...$(FONT_RESET)"
	@echo -n "Docker healthchecks"
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		echo -n "."; \
		sleep 2; \
	done
	@echo " ready!"
	@echo ""
	@echo -e "$(FONT_CYAN)[3/3] Starting PM2 services...$(FONT_RESET)"
	@$(MAKE) start-all
	@echo ""
	@$(call print_success,Complete Automagik stack started!)
	@echo ""
	@$(MAKE) status


stop: ## 🛑 Stop everything (PM2 services + optional services + infrastructure)
	$(call print_status,🛑 Stopping complete Automagik stack...)
	@echo -e "$(FONT_CYAN)[1/2] Stopping PM2 services...$(FONT_RESET)"
	@$(MAKE) stop-all
	@echo ""
	@echo -e "$(FONT_CYAN)[2/2] Stopping all Docker containers in parallel...$(FONT_RESET)"
	@# Stop all containers in parallel
	@{ \
		$(MAKE) stop-infrastructure > /tmp/automagik-stop-infra.log 2>&1 & \
		INFRA_PID=$$!; \
		if $(DOCKER_COMPOSE) -f $(LANGFLOW_COMPOSE) -p langflow ps -q 2>/dev/null | grep -q .; then \
			$(MAKE) stop-langflow > /tmp/automagik-stop-langflow.log 2>&1 & \
			LANG_PID=$$!; \
			echo -e "  • Stopping LangFlow (PID: $$LANG_PID)"; \
		else \
			LANG_PID=""; \
		fi; \
		if $(DOCKER_COMPOSE) -f $(EVOLUTION_COMPOSE) -p evolution_api ps -q 2>/dev/null | grep -q .; then \
			$(MAKE) stop-evolution > /tmp/automagik-stop-evolution.log 2>&1 & \
			EVO_PID=$$!; \
			echo -e "  • Stopping Evolution API (PID: $$EVO_PID)"; \
		else \
			EVO_PID=""; \
		fi; \
		echo -e "  • Stopping Infrastructure (PID: $$INFRA_PID)"; \
		echo ""; \
		echo -n "Waiting for containers to stop"; \
		wait $$INFRA_PID && echo -e "\n  $(FONT_GREEN)✓$(FONT_RESET) Infrastructure stopped" || echo -e "\n  $(FONT_RED)✗$(FONT_RESET) Infrastructure stop failed"; \
		[ -n "$$LANG_PID" ] && wait $$LANG_PID && echo -e "  $(FONT_GREEN)✓$(FONT_RESET) LangFlow stopped" || true; \
		[ -n "$$EVO_PID" ] && wait $$EVO_PID && echo -e "  $(FONT_GREEN)✓$(FONT_RESET) Evolution API stopped" || true; \
	}
	@echo ""
	@$(call print_success,Complete stack stopped!)

restart: ## 🔄 Restart all PM2 services
	$(call print_status,Restarting all Automagik services...)
	@# Restart all PM2 processes (more robust than hardcoded names)
	@if pm2 list 2>/dev/null | grep -q "online\|stopped\|errored"; then \
		echo -e "$(FONT_CYAN)$(INFO) Restarting all PM2 processes...$(FONT_RESET)"; \
		pm2 restart all 2>/dev/null || $(MAKE) start-all; \
	else \
		echo -e "$(FONT_GRAY)$(INFO) No PM2 processes found, starting services...$(FONT_RESET)"; \
		$(MAKE) start-all; \
	fi


update: ## 🔄 Git pull and restart only updated services
	$(call print_status,🔄 Checking for updates...)
	@updated_repos=""; \
	echo -e "$(FONT_CYAN)📌 Checking main repository...$(FONT_RESET)"; \
	git_output=$$(git pull 2>&1); \
	if echo "$$git_output" | grep -q "Already up to date"; then \
		echo "  $(FONT_GREEN)✓ Main repository already up to date$(FONT_RESET)"; \
	else \
		echo "  $(FONT_YELLOW)🔄 Main repository updated$(FONT_RESET)"; \
		updated_repos="$$updated_repos main"; \
	fi; \
	for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			echo -e "$(FONT_CYAN)📌 Checking $$(basename $$service_dir)...$(FONT_RESET)"; \
			cd $$service_dir; \
			if git rev-parse --git-dir > /dev/null 2>&1; then \
				git_output=$$(git pull 2>&1); \
				if echo "$$git_output" | grep -q "Already up to date"; then \
					echo "  $(FONT_GREEN)✓ $$(basename $$service_dir) already up to date$(FONT_RESET)"; \
				else \
					echo "  $(FONT_YELLOW)🔄 $$(basename $$service_dir) updated$(FONT_RESET)"; \
					updated_repos="$$updated_repos $$(basename $$service_dir)"; \
				fi; \
			else \
				echo "  $(FONT_YELLOW)⚠️ Not a git repository$(FONT_RESET)"; \
			fi; \
			cd - >/dev/null; \
		else \
			echo -e "$(FONT_RED)❌ $$(basename $$service_dir) directory not found - skipping$(FONT_RESET)"; \
		fi; \
	done; \
	if [ -z "$$updated_repos" ]; then \
		echo -e "$(FONT_GREEN)✅ No updates needed - all repositories are up to date!$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_YELLOW)🔄 Restarting services for updated repositories:$$updated_repos$(FONT_RESET)"; \
		for repo in $$updated_repos; do \
			case $$repo in \
				"main") \
					echo -e "$(FONT_CYAN)🔄 Main repository updated - restarting PM2 services...$(FONT_RESET)"; \
					$(MAKE) restart ;; \
				"automagik") $(MAKE) restart-agents ;; \
				"automagik-spark") $(MAKE) restart-spark ;; \
				"automagik-tools") $(MAKE) restart-tools ;; \
				"automagik-omni") $(MAKE) restart-omni ;; \
				"automagik-ui") $(MAKE) restart-ui-with-build ;; \
			esac; \
		done; \
		echo -e "$(FONT_GREEN)✅ Update complete - restarted updated services!$(FONT_RESET)"; \
	fi

clone-ui: ## 📥 Clone automagik-ui repository if missing
	@if [ ! -d "$(AUTOMAGIK_UI_DIR)" ]; then \
		echo -e "$(FONT_CYAN)📥 Cloning automagik-ui repository...$(FONT_RESET)"; \
		git clone $(AUTOMAGIK_UI_URL) $(AUTOMAGIK_UI_DIR); \
		echo -e "$(FONT_GREEN)✅ automagik-ui repository cloned successfully!$(FONT_RESET)"; \
	else \
		echo -e "$(FONT_YELLOW)⚠️ automagik-ui directory already exists$(FONT_RESET)"; \
	fi

pull: ## 🔄 Pull from all GitHub repos (main + all services)
	$(call print_status,🔄 Pulling from all GitHub repositories...)
	@echo -e "$(FONT_CYAN)📌 Pulling main repository...$(FONT_RESET)"
	@git pull
	@for service_dir in $(AUTOMAGIK_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			echo -e "$(FONT_CYAN)📌 Pulling $$(basename $$service_dir)...$(FONT_RESET)"; \
			cd $$service_dir && git pull 2>/dev/null || echo "  $(FONT_YELLOW)⚠️ Not a git repository or no remote$(FONT_RESET)"; \
			cd - >/dev/null; \
		fi; \
	done
	@$(call print_success,All repositories updated!)

pull-agents: ## 🔄 Pull automagik repository only
	$(call git_pull_service,automagik,$(AGENTS_COLOR),$(AUTOMAGIK_DIR),$(AUTOMAGIK_URL))

pull-spark: ## 🔄 Pull automagik-spark repository only
	$(call git_pull_service,automagik-spark,$(SPARK_COLOR),$(AUTOMAGIK_SPARK_DIR),$(AUTOMAGIK_SPARK_URL))

pull-tools: ## 🔄 Pull automagik-tools repository only
	$(call git_pull_service,automagik-tools,$(TOOLS_COLOR),$(AUTOMAGIK_TOOLS_DIR),$(AUTOMAGIK_TOOLS_URL))

pull-omni: ## 🔄 Pull automagik-omni repository only
	$(call git_pull_service,automagik-omni,$(OMNI_COLOR),$(AUTOMAGIK_OMNI_DIR),$(AUTOMAGIK_OMNI_URL))

pull-ui: ## 🔄 Pull automagik-ui repository only
	$(call git_pull_service,automagik-ui,$(UI_COLOR),$(AUTOMAGIK_UI_DIR),$(AUTOMAGIK_UI_URL))

logs: ## 📋 Show logs from all services (N=lines F=1 for follow mode)
	$(eval N := $(or $(N),30))
	@if [ "$(F)" = "1" ]; then \
		echo -e "$(FONT_PURPLE)$(SUITE) 📋 Following logs from all services (Press Ctrl+C to stop)...$(FONT_RESET)"; \
		echo -e "$(FONT_YELLOW)Press Ctrl+C to stop following logs$(FONT_RESET)"; \
		pm2 logs | sed -E \
			-e 's/(automagik)/$(AGENTS_COLOR)\1$(FONT_RESET)/g' \
			-e 's/(automagik-spark-api|automagik-spark-worker)/$(SPARK_COLOR)\1$(FONT_RESET)/g' \
			-e 's/(automagik-tools-sse|automagik-tools-http)/$(TOOLS_COLOR)\1$(FONT_RESET)/g' \
			-e 's/(automagik-omni)/$(OMNI_COLOR)\1$(FONT_RESET)/g' \
			-e 's/(automagik-ui)/$(UI_COLOR)\1$(FONT_RESET)/g'; \
	else \
		echo -e "$(FONT_PURPLE)$(SUITE) 📋 Showing last $(N) lines from all services...$(FONT_RESET)"; \
		echo -e "$(AGENTS_COLOR)[AGENTS] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik --lines $(N) --nostream 2>/dev/null | sed "s/^/$(AGENTS_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
		echo -e "$(SPARK_COLOR)[SPARK-API] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik-spark-api --lines $(N) --nostream 2>/dev/null | sed "s/^/$(SPARK_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
		echo -e "$(SPARK_COLOR)[SPARK-WORKER] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik-spark-worker --lines $(N) --nostream 2>/dev/null | sed "s/^/$(SPARK_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
		echo -e "$(TOOLS_COLOR)[TOOLS] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik-tools --lines $(N) --nostream 2>/dev/null | sed "s/^/$(TOOLS_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
		echo -e "$(OMNI_COLOR)[OMNI] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik-omni --lines $(N) --nostream 2>/dev/null | sed "s/^/$(OMNI_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
		echo -e "$(UI_COLOR)[UI] Last $(N) lines:$(FONT_RESET)"; \
		pm2 logs automagik-ui --lines $(N) --nostream 2>/dev/null | sed "s/^/$(UI_COLOR)  $(FONT_RESET)/" || echo -e "$(FONT_RED)  Service not found$(FONT_RESET)"; \
	fi

status: ## 📊 Check status of PM2 services
	@echo -e "$(FONT_PURPLE)$(CHART) Automagik Services Status:$(FONT_RESET)"
	@pm2 list | sed -E \
		-e 's/(automagik)/\x1b[94m\1\x1b[0m/g' \
		-e 's/(automagik-spark-api|automagik-spark-worker)/\x1b[33m\1\x1b[0m/g' \
		-e 's/(automagik-tools)/\x1b[34m\1\x1b[0m/g' \
		-e 's/(automagik-omni)/\x1b[35m\1\x1b[0m/g' \
		-e 's/(automagik-ui)/\x1b[32m\1\x1b[0m/g' \
		-e 's/online/\x1b[32monline\x1b[0m/g' \
		-e 's/stopped/\x1b[33mstopped\x1b[0m/g' \
		-e 's/errored/\x1b[31merrored\x1b[0m/g'

status-full: ## 📊 Check status of everything (PM2 + infrastructure)
	@$(MAKE) status-all

# Legacy aliases removed to prevent duplicate target warnings

# Ensure default goal shows help
.DEFAULT_GOAL := help
