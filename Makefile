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

# Service names
SERVICES := am-agents-labs automagik-spark automagik-tools automagik-omni automagik-ui-v2

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

define print_service_status
	@service_name="$(1)"; \
	color="$(2)"; \
	if systemctl is-active --quiet $$service_name; then \
		status="RUNNING"; \
		status_color="$(FONT_GREEN)"; \
		pid=$$(systemctl show $$service_name --property=MainPID --value 2>/dev/null); \
		port=$$(ss -tlnp 2>/dev/null | grep $$pid | awk '{print $$4}' | cut -d: -f2 | head -1); \
		uptime=$$(systemctl show $$service_name --property=ActiveEnterTimestamp --value | cut -d' ' -f2-3); \
	elif systemctl is-enabled --quiet $$service_name; then \
		status="STOPPED"; \
		status_color="$(FONT_YELLOW)"; \
		pid="-"; \
		port="-"; \
		uptime="-"; \
	else \
		status="NOT INSTALLED"; \
		status_color="$(FONT_RED)"; \
		pid="-"; \
		port="-"; \
		uptime="-"; \
	fi; \
	printf "  %s%-20s%s %s%-12s%s %s%-8s%s %s%-8s%s %s%s%s\n" \
		"$$color" "$$service_name" "$(FONT_RESET)" \
		"$$status_color" "$$status" "$(FONT_RESET)" \
		"$(FONT_CYAN)" "$${port:-N/A}" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$${pid:-N/A}" "$(FONT_RESET)" \
		"$(FONT_GRAY)" "$$uptime" "$(FONT_RESET)"
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
# ⚙️ Service Installation
# ===========================================
.PHONY: install-all-services uninstall-all-services install-agents install-spark install-tools install-omni install-ui
install-all-services: ## ⚙️ Install all services as systemd services
	$(call print_status,Installing all Automagik services...)
	@$(MAKE) install-agents
	@$(MAKE) install-spark
	@$(MAKE) install-tools
	@$(MAKE) install-omni
	@$(MAKE) install-ui
	@$(call print_success_with_logo,All services installed successfully!)

install-agents: ## Install am-agents-labs service
	$(call print_status,Installing $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	@cd $(AM_AGENTS_LABS_DIR) && make install-service

install-spark: ## Install automagik-spark service
	$(call print_status,Installing $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_SPARK_DIR) && make install-service

install-tools: ## Install automagik-tools service
	$(call print_status,Installing $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_TOOLS_DIR) && make install-service

install-omni: ## Install automagik-omni service
	$(call print_status,Installing $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_OMNI_DIR) && make install-service

install-ui: ## Install automagik-ui-v2 service
	$(call print_status,Installing $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	@cd $(AUTOMAGIK_UI_DIR) && make install-service

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
	@echo -e "$(FONT_CYAN)Starting services in dependency order...$(FONT_RESET)"
	@echo -e "$(AGENTS_COLOR)[1/5] Starting am-agents-labs (core orchestrator)...$(FONT_RESET)"
	@sudo systemctl start am-agents-labs 2>/dev/null || echo "Service not installed"
	@sleep 2
	@echo -e "$(SPARK_COLOR)[2/5] Starting automagik-spark (workflow engine)...$(FONT_RESET)"
	@sudo systemctl start automagik-spark 2>/dev/null || echo "Service not installed"
	@sleep 2
	@echo -e "$(TOOLS_COLOR)[3/5] Starting automagik-tools (MCP tools)...$(FONT_RESET)"
	@sudo systemctl start automagik-tools 2>/dev/null || echo "Service not installed"
	@sleep 2
	@echo -e "$(OMNI_COLOR)[4/5] Starting automagik-omni (multi-tenant hub)...$(FONT_RESET)"
	@sudo systemctl start automagik-omni 2>/dev/null || echo "Service not installed"
	@sleep 2
	@echo -e "$(UI_COLOR)[5/5] Starting automagik-ui-v2 (frontend)...$(FONT_RESET)"
	@sudo systemctl start automagik-ui-v2 2>/dev/null || echo "Service not installed"
	@sleep 3
	@$(call print_success,All services started!)
	@$(MAKE) status-all-services

stop-all-services: ## 🛑 Stop all services
	$(call print_status,Stopping all Automagik services...)
	@for service in $(SERVICES); do \
		echo -e "Stopping $$service..."; \
		sudo systemctl stop $$service 2>/dev/null || echo "Service not running"; \
	done
	@$(call print_success,All services stopped!)

restart-all-services: ## 🔄 Restart all services
	$(call print_status,Restarting all Automagik services...)
	@$(MAKE) stop-all-services
	@sleep 2
	@$(MAKE) start-all-services

status-all-services: ## 📊 Check status of all services
	@echo -e "$(FONT_PURPLE)$(CHART) Automagik Services Status:$(FONT_RESET)"
	@echo -e "  $(FONT_BOLD)Service Name         Status       Port     PID      Uptime$(FONT_RESET)"
	@echo -e "  $(FONT_GRAY)─────────────────────────────────────────────────────────────────$(FONT_RESET)"
	@$(call print_service_status,automagik-agents,$(AGENTS_COLOR))
	@$(call print_service_status,automagik-spark,$(SPARK_COLOR))
	@$(call print_service_status,automagik-tools,$(TOOLS_COLOR))
	@$(call print_service_status,omni-hub,$(OMNI_COLOR))
	@$(call print_service_status,automagik-ui-v2,$(UI_COLOR))
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
	@sudo systemctl start am-agents-labs
	@$(call print_success,am-agents-labs started!)

start-spark: ## 🚀 Start automagik-spark service only
	$(call print_status,Starting $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@sudo systemctl start automagik-spark
	@$(call print_success,automagik-spark started!)

start-tools: ## 🚀 Start automagik-tools service only
	$(call print_status,Starting $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@sudo systemctl start automagik-tools
	@$(call print_success,automagik-tools started!)

start-omni: ## 🚀 Start automagik-omni service only
	$(call print_status,Starting $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@sudo systemctl start automagik-omni
	@$(call print_success,automagik-omni started!)

start-ui: ## 🚀 Start automagik-ui-v2 service only
	$(call print_status,Starting $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	@sudo systemctl start automagik-ui-v2
	@$(call print_success,automagik-ui-v2 started!)

# Individual Stop Commands
stop-agents: ## 🛑 Stop am-agents-labs service only
	$(call print_status,Stopping $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) service...)
	@sudo systemctl stop am-agents-labs
	@$(call print_success,am-agents-labs stopped!)

stop-spark: ## 🛑 Stop automagik-spark service only
	$(call print_status,Stopping $(SPARK_COLOR)automagik-spark$(FONT_RESET) service...)
	@sudo systemctl stop automagik-spark
	@$(call print_success,automagik-spark stopped!)

stop-tools: ## 🛑 Stop automagik-tools service only
	$(call print_status,Stopping $(TOOLS_COLOR)automagik-tools$(FONT_RESET) service...)
	@sudo systemctl stop automagik-tools
	@$(call print_success,automagik-tools stopped!)

stop-omni: ## 🛑 Stop automagik-omni service only
	$(call print_status,Stopping $(OMNI_COLOR)automagik-omni$(FONT_RESET) service...)
	@sudo systemctl stop automagik-omni
	@$(call print_success,automagik-omni stopped!)

stop-ui: ## 🛑 Stop automagik-ui-v2 service only
	$(call print_status,Stopping $(UI_COLOR)automagik-ui-v2$(FONT_RESET) service...)
	@sudo systemctl stop automagik-ui-v2
	@$(call print_success,automagik-ui-v2 stopped!)

# Individual Restart Commands
restart-agents: ## 🔄 Restart am-agents-labs service only
	@$(MAKE) stop-agents
	@sleep 2
	@$(MAKE) start-agents

restart-spark: ## 🔄 Restart automagik-spark service only
	@$(MAKE) stop-spark
	@sleep 2
	@$(MAKE) start-spark

restart-tools: ## 🔄 Restart automagik-tools service only
	@$(MAKE) stop-tools
	@sleep 2
	@$(MAKE) start-tools

restart-omni: ## 🔄 Restart automagik-omni service only
	@$(MAKE) stop-omni
	@sleep 2
	@$(MAKE) start-omni

restart-ui: ## 🔄 Restart automagik-ui-v2 service only
	@$(MAKE) stop-ui
	@sleep 2
	@$(MAKE) start-ui

# Individual Status Commands
status-agents: ## 📊 Check am-agents-labs status only
	@$(call print_service_status,automagik-agents,$(AGENTS_COLOR))

status-spark: ## 📊 Check automagik-spark status only
	@$(call print_service_status,automagik-spark,$(SPARK_COLOR))

status-tools: ## 📊 Check automagik-tools status only
	@$(call print_service_status,automagik-tools,$(TOOLS_COLOR))

status-omni: ## 📊 Check automagik-omni status only
	@$(call print_service_status,omni-hub,$(OMNI_COLOR))

status-ui: ## 📊 Check automagik-ui-v2 status only
	@$(call print_service_status,automagik-ui-v2,$(UI_COLOR))

# ===========================================
# 📋 Logging & Monitoring
# ===========================================
.PHONY: logs-all logs-agents logs-spark logs-tools logs-omni logs-ui logs-infrastructure
logs-all: ## 📋 Follow logs from all services (colorized)
	$(call print_status,Following logs from all services...)
	@echo -e "$(FONT_YELLOW)Press Ctrl+C to stop following logs$(FONT_RESET)"
	@(journalctl -u automagik-agents -f --no-pager 2>/dev/null | sed "s/^/$(AGENTS_COLOR)[AGENTS]$(FONT_RESET) /" &); \
	(journalctl -u automagik-spark -f --no-pager 2>/dev/null | sed "s/^/$(SPARK_COLOR)[SPARK]$(FONT_RESET)  /" &); \
	(journalctl -u automagik-tools -f --no-pager 2>/dev/null | sed "s/^/$(TOOLS_COLOR)[TOOLS]$(FONT_RESET)  /" &); \
	(journalctl -u omni-hub -f --no-pager 2>/dev/null | sed "s/^/$(OMNI_COLOR)[OMNI]$(FONT_RESET)   /" &); \
	(journalctl -u automagik-ui-v2 -f --no-pager 2>/dev/null | sed "s/^/$(UI_COLOR)[UI]$(FONT_RESET)     /" &); \
	wait

logs-agents: ## 📋 Follow am-agents-labs logs
	$(call print_status,Following $(AGENTS_COLOR)am-agents-labs$(FONT_RESET) logs...)
	@journalctl -u automagik-agents -f --no-pager

logs-spark: ## 📋 Follow automagik-spark logs
	$(call print_status,Following $(SPARK_COLOR)automagik-spark$(FONT_RESET) logs...)
	@journalctl -u automagik-spark -f --no-pager

logs-tools: ## 📋 Follow automagik-tools logs
	$(call print_status,Following $(TOOLS_COLOR)automagik-tools$(FONT_RESET) logs...)
	@journalctl -u automagik-tools -f --no-pager

logs-omni: ## 📋 Follow automagik-omni logs
	$(call print_status,Following $(OMNI_COLOR)automagik-omni$(FONT_RESET) logs...)
	@journalctl -u omni-hub -f --no-pager

logs-ui: ## 📋 Follow automagik-ui-v2 logs
	$(call print_status,Following $(UI_COLOR)automagik-ui-v2$(FONT_RESET) logs...)
	@journalctl -u automagik-ui-v2 -f --no-pager

logs-infrastructure: ## 📋 Follow Docker infrastructure logs
	$(call print_status,Following Docker infrastructure logs...)
	@$(DOCKER_COMPOSE) -f $(INFRASTRUCTURE_COMPOSE) logs -f

# ===========================================
# 🚀 Complete Installation
# ===========================================
.PHONY: install-local start-local stop-local status-local
install-local: ## 🚀 Complete local installation
	$(call print_status,Starting complete local installation...)
	@echo -e "$(FONT_CYAN)Step 1/3: Setting up Docker infrastructure...$(FONT_RESET)"
	@$(MAKE) start-infrastructure
	@echo -e "$(FONT_CYAN)Step 2/3: Installing all services...$(FONT_RESET)"
	@$(MAKE) install-all-services
	@echo -e "$(FONT_CYAN)Step 3/3: Starting all services...$(FONT_RESET)"
	@$(MAKE) start-all-services
	@$(call print_success_with_logo,Complete local installation finished!)
	@echo -e "$(FONT_CYAN)🌐 Frontend available at: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 API available at: http://localhost:8881$(FONT_RESET)"

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


clean-all: ## 🧹 Clean all service artifacts
	$(call print_status,Cleaning all service artifacts...)
	@for service_dir in $(AM_AGENTS_LABS_DIR) $(AUTOMAGIK_SPARK_DIR) $(AUTOMAGIK_TOOLS_DIR) $(AUTOMAGIK_OMNI_DIR) $(AUTOMAGIK_UI_DIR); do \
		if [ -d "$$service_dir" ]; then \
			echo -e "Cleaning $$(basename $$service_dir)..."; \
			cd $$service_dir && make clean 2>/dev/null || true; \
		fi; \
	done
	@$(call print_success,All artifacts cleaned!)

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
.PHONY: install start stop restart update uninstall pull pull-agents pull-spark pull-tools pull-omni pull-ui logs status
.PHONY: start-agents start-spark start-tools start-omni start-ui stop-agents stop-spark stop-tools stop-omni stop-ui
.PHONY: restart-agents restart-spark restart-tools restart-omni restart-ui status-agents status-spark status-tools status-omni status-ui

install: ## 🚀 Complete installation (infrastructure + services + env)
	$(call print_status,🚀 Installing complete Automagik suite...)
	@$(MAKE) start-infrastructure
	@$(MAKE) install-all-services
	@$(call print_success_with_logo,Complete installation finished!)
	@echo -e "$(FONT_CYAN)🌐 Frontend: http://localhost:8888$(FONT_RESET)"
	@echo -e "$(FONT_CYAN)🔧 API: http://localhost:8881$(FONT_RESET)"

start: ## 🚀 Start everything (infrastructure + all services)
	$(call print_status,🚀 Starting complete Automagik stack...)
	@$(MAKE) start-infrastructure
	@sleep 5
	@$(MAKE) start-all-services
	@$(call print_success,Complete stack started!)

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
	@cd $(AM_AGENTS_LABS_DIR) && git pull
	@$(call print_success,am-agents-labs updated!)

pull-spark: ## 🔄 Pull automagik-spark repository only
	$(call print_status,Pulling $(SPARK_COLOR)automagik-spark$(FONT_RESET)...)
	@cd $(AUTOMAGIK_SPARK_DIR) && git pull
	@$(call print_success,automagik-spark updated!)

pull-tools: ## 🔄 Pull automagik-tools repository only
	$(call print_status,Pulling $(TOOLS_COLOR)automagik-tools$(FONT_RESET)...)
	@cd $(AUTOMAGIK_TOOLS_DIR) && git pull
	@$(call print_success,automagik-tools updated!)

pull-omni: ## 🔄 Pull automagik-omni repository only
	$(call print_status,Pulling $(OMNI_COLOR)automagik-omni$(FONT_RESET)...)
	@cd $(AUTOMAGIK_OMNI_DIR) && git pull
	@$(call print_success,automagik-omni updated!)

pull-ui: ## 🔄 Pull automagik-ui-v2 repository only
	$(call print_status,Pulling $(UI_COLOR)automagik-ui-v2$(FONT_RESET)...)
	@cd $(AUTOMAGIK_UI_DIR) && git pull
	@$(call print_success,automagik-ui-v2 updated!)

logs: ## 📋 Show all colorized logs
	$(call print_status,📋 Following logs from all services...)
	@echo -e "$(FONT_YELLOW)Press Ctrl+C to stop following logs$(FONT_RESET)"
	@(journalctl -u automagik-agents -f --no-pager 2>/dev/null | sed "s/^/$(AGENTS_COLOR)[AGENTS]$(FONT_RESET) /" &); \
	(journalctl -u automagik-spark -f --no-pager 2>/dev/null | sed "s/^/$(SPARK_COLOR)[SPARK]$(FONT_RESET)  /" &); \
	(journalctl -u automagik-tools -f --no-pager 2>/dev/null | sed "s/^/$(TOOLS_COLOR)[TOOLS]$(FONT_RESET)  /" &); \
	(journalctl -u omni-hub -f --no-pager 2>/dev/null | sed "s/^/$(OMNI_COLOR)[OMNI]$(FONT_RESET)   /" &); \
	(journalctl -u automagik-ui-v2 -f --no-pager 2>/dev/null | sed "s/^/$(UI_COLOR)[UI]$(FONT_RESET)     /" &); \
	wait

status: ## 📊 Check status of everything
	@$(MAKE) status-all-services
	@$(MAKE) status-infrastructure

# Legacy aliases for compatibility
install-local: install
start-local: start
stop-local: stop
status-local: status
logs-all: logs

# Ensure default goal shows help
.DEFAULT_GOAL := help
