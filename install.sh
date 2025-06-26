#!/bin/bash

# ===================================================================
# 🚀 Automagik Suite - Main Installation Orchestrator
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils/colors.sh"
source "$SCRIPT_DIR/scripts/utils/logging.sh"

# Configuration
INSTALL_MODE="${INSTALL_MODE:-interactive}"
SKIP_DEPENDENCIES="${SKIP_DEPENDENCIES:-false}"
SKIP_BROWSER_TOOLS="${SKIP_BROWSER_TOOLS:-false}"
SKIP_CLONE="${SKIP_CLONE:-false}"
SKIP_ENV_SETUP="${SKIP_ENV_SETUP:-false}"
SKIP_DEPLOY="${SKIP_DEPLOY:-false}"

# Installation steps
INSTALLATION_STEPS=(
    "welcome"
    "system_detection"
    "dependency_installation"
    "repository_cloning"
    "api_key_collection"
    "environment_setup"
    "deployment"
    "verification"
    "completion"
)

# Show welcome message
show_welcome() {
    clear
    print_section "WELCOME TO AUTOMAGIK SUITE INSTALLER"
    
    echo -e "${CYAN}🚀 Welcome to the Automagik Suite Installation!${NC}"
    echo ""
    echo "This installer will set up the complete Automagik Suite on your system:"
    echo ""
    echo -e "${BOLD}Components to be installed:${NC}"
    echo "• ${GREEN}am-agents-labs${NC}     - Main Orchestrator (PostgreSQL)"
    echo "• ${GREEN}automagik-spark${NC}    - Workflow Engine (PostgreSQL + Redis)"
    echo "• ${GREEN}automagik-tools${NC}    - MCP Tools (SSE + HTTP)"
    echo "• ${GREEN}automagik-evolution${NC} - WhatsApp API (PostgreSQL + Redis + RabbitMQ)"
    echo "• ${GREEN}automagik-omni${NC}     - Multi-tenant Hub"
    echo "• ${GREEN}automagik-ui-v2${NC}    - Main Interface (Production Build)"
    echo ""
    echo -e "${BOLD}System Requirements:${NC}"
    echo "• Operating System: Ubuntu/Debian, macOS, or WSL"
    echo "• Memory: 4GB+ RAM recommended"
    echo "• Disk Space: 10GB+ available"
    echo "• Network: Internet connection required"
    echo ""
    echo -e "${BOLD}What this installer will do:${NC}"
    echo "1. 🔍 Detect your system and check compatibility"
    echo "2. 📦 Install required dependencies (Python 3.12, Node.js 22, Docker, etc.)"
    echo "3. 🌐 Optionally install browser tools (for Genie Agent frontend debugging)"
    echo "4. 📁 Clone all Automagik repositories with branch selection"
    echo "5. 🔑 Collect API keys interactively"
    echo "6. ⚙️  Generate environment configurations"
    echo "7. 🐳 Deploy services with Docker Compose"
    echo "8. ✅ Verify installation and show status"
    echo ""
    echo -e "${YELLOW}Estimated installation time: 15-30 minutes${NC}"
    echo ""
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Ready to begin installation? [Y/n]: " confirm
            case $confirm in
                [Yy]|[Yy][Ee][Ss]|"")
                    log_success "Starting Automagik Suite installation"
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Installation cancelled by user"
                    exit 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    else
        log_info "Running in automated mode"
    fi
    
    return 0
}

# Run system detection
run_system_detection() {
    log_section "System Detection"
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        echo "This will analyze your system (OS, RAM, CPU, disk space) and check compatibility."
        while true; do
            read -p "Proceed with system detection? [Y/n]: " proceed
            case $proceed in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "System detection skipped by user"
                    return 1
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    if "$SCRIPT_DIR/scripts/system/detect-system.sh" detect; then
        log_success "System detection completed successfully"
        
        # Source the generated system info
        if [ -f "system-info.env" ]; then
            source "system-info.env"
            log_info "System information loaded"
        fi
        
        if [ "$INSTALL_MODE" = "interactive" ]; then
            echo ""
            read -p "Press Enter to continue to dependency installation..."
        fi
        
        return 0
    else
        log_error "System detection failed"
        
        if [ "$INSTALL_MODE" = "interactive" ]; then
            while true; do
                read -p "Continue anyway? [y/N]: " continue_choice
                case $continue_choice in
                    [Yy]|[Yy][Ee][Ss])
                        log_warning "Continuing with potentially incompatible system"
                        return 0
                        ;;
                    [Nn]|[Nn][Oo]|"")
                        log_info "Installation stopped due to system incompatibility"
                        exit 1
                        ;;
                    *)
                        print_warning "Please answer yes or no."
                        ;;
                esac
            done
        else
            log_error "Automated installation stopped due to system incompatibility"
            return 1
        fi
    fi
}

# Install dependencies
install_dependencies() {
    if [ "$SKIP_DEPENDENCIES" = "true" ]; then
        log_info "Skipping dependency installation (SKIP_DEPENDENCIES=true)"
        return 0
    fi
    
    log_section "Dependency Installation"
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        echo "This will install required dependencies:"
        echo "• Python 3.12+"
        echo "• Node.js 22+"
        echo "• Docker & Docker Compose"
        echo "• uv (Python package manager)"
        echo "• pnpm (Node.js package manager)"
        echo "• GitHub CLI"
        echo "• Claude Code CLI"
        echo ""
        while true; do
            read -p "Proceed with dependency installation? [Y/n]: " proceed
            case $proceed in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Dependency installation skipped by user"
                    return 1
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    # Determine which installer to use based on detected OS
    local installer_script=""
    
    case "${OS_TYPE:-unknown}" in
        "linux"|"wsl")
            installer_script="$SCRIPT_DIR/scripts/system/install-deps-ubuntu.sh"
            ;;
        "macos")
            installer_script="$SCRIPT_DIR/scripts/system/install-deps-macos.sh"
            ;;
        *)
            log_error "Unsupported operating system: ${OS_TYPE:-unknown}"
            return 1
            ;;
    esac
    
    if [ ! -f "$installer_script" ]; then
        log_error "Installer script not found: $installer_script"
        return 1
    fi
    
    log_info "Running dependency installer for ${OS_TYPE:-unknown}..."
    
    if "$installer_script" install; then
        log_success "Dependencies installed successfully"
        return 0
    else
        log_error "Dependency installation failed"
        
        if [ "$INSTALL_MODE" = "interactive" ]; then
            while true; do
                read -p "Continue without all dependencies? [y/N]: " continue_choice
                case $continue_choice in
                    [Yy]|[Yy][Ee][Ss])
                        log_warning "Continuing with missing dependencies - some features may not work"
                        return 0
                        ;;
                    [Nn]|[Nn][Oo]|"")
                        log_info "Installation stopped due to dependency failures"
                        exit 1
                        ;;
                    *)
                        print_warning "Please answer yes or no."
                        ;;
                esac
            done
        else
            return 1
        fi
    fi
}

# Clone repositories
clone_repositories() {
    if [ "$SKIP_CLONE" = "true" ]; then
        log_info "Skipping repository cloning (SKIP_CLONE=true)"
        return 0
    fi
    
    log_section "Repository Cloning"
    
    if "$SCRIPT_DIR/scripts/setup/clone-repos.sh" clone; then
        log_success "Repositories cloned successfully"
        return 0
    else
        log_error "Repository cloning failed"
        return 1
    fi
}

# Collect API keys
collect_api_keys() {
    log_section "API Key Collection"
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        echo "API keys enable AI functionality but are all optional for initial setup."
        echo "You can configure them later by editing the .env files in each service directory."
        echo ""
        while true; do
            read -p "Set up API keys now? [Y/n]: " setup_keys
            case $setup_keys in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Skipping API key setup - you can configure them later"
                    return 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    if "$SCRIPT_DIR/scripts/setup/collect-keys.sh" collect; then
        log_success "API keys collected successfully"
        
        if [ "$INSTALL_MODE" = "interactive" ]; then
            echo ""
            read -p "Press Enter to continue to environment setup..."
        fi
        
        return 0
    else
        log_warning "API key collection completed with some keys skipped"
        
        if [ "$INSTALL_MODE" = "interactive" ]; then
            echo "Note: You can always add API keys later by editing the .env files"
            echo ""
            read -p "Press Enter to continue..."
        fi
        
        return 0  # Don't fail the installation for missing API keys
    fi
}

# Setup environments
setup_environments() {
    if [ "$SKIP_ENV_SETUP" = "true" ]; then
        log_info "Skipping environment setup (SKIP_ENV_SETUP=true)"
        return 0
    fi
    
    log_section "Environment Setup"
    
    if "$SCRIPT_DIR/scripts/setup/setup-envs.sh" setup; then
        log_success "Environment files generated successfully"
        return 0
    else
        log_error "Environment setup failed"
        return 1
    fi
}

# Deploy services
deploy_services() {
    if [ "$SKIP_DEPLOY" = "true" ]; then
        log_info "Skipping service deployment (SKIP_DEPLOY=true)"
        return 0
    fi
    
    log_section "Service Deployment"
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        echo "This will start all Automagik services using Docker Compose:"
        echo "• PostgreSQL databases (3 instances)"
        echo "• Redis instances (2 instances)"
        echo "• RabbitMQ message broker"
        echo "• All Automagik applications"
        echo ""
        echo "Services will be accessible at:"
        echo "• Main Interface: http://localhost:8888"
        echo "• AM Agents Labs: http://localhost:8881"
        echo "• Automagik Spark: http://localhost:8883"
        echo ""
        while true; do
            read -p "Start all services now? [Y/n]: " start_services
            case $start_services in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Service deployment skipped - you can start them later with: ./scripts/deploy/start-services.sh start"
                    return 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    if "$SCRIPT_DIR/scripts/deploy/start-services.sh" deploy; then
        log_success "Services deployed successfully"
        return 0
    else
        log_error "Service deployment failed"
        return 1
    fi
}

# Verify installation
verify_installation() {
    log_section "Installation Verification"
    
    # Wait a moment for services to stabilize
    log_info "Waiting for services to stabilize..."
    sleep 15
    
    # Run status check
    if "$SCRIPT_DIR/scripts/deploy/status-display.sh" status; then
        log_success "All services are running and healthy"
        return 0
    else
        log_warning "Some services may need attention"
        return 1
    fi
}

# Show completion message
show_completion() {
    log_section "Installation Complete"
    
    echo -e "${GREEN}🎉 Automagik Suite installation completed successfully!${NC}"
    echo ""
    echo -e "${BOLD}Access your Automagik Suite:${NC}"
    echo -e "• ${CYAN}Main Interface:${NC}     http://localhost:8888"
    echo -e "• ${CYAN}AM Agents Labs:${NC}     http://localhost:8881"
    echo -e "• ${CYAN}Automagik Spark:${NC}    http://localhost:8883"
    echo -e "• ${CYAN}Automagik Omni:${NC}     http://localhost:8882"
    echo -e "• ${CYAN}MCP Tools SSE:${NC}      http://localhost:8884"
    echo -e "• ${CYAN}MCP Tools HTTP:${NC}     http://localhost:8885"
    echo -e "• ${CYAN}Evolution API:${NC}      http://localhost:9000"
    echo ""
    echo -e "${BOLD}Optional Services:${NC}"
    echo -e "• ${CYAN}Langflow:${NC}           http://localhost:7860"
    echo ""
    echo -e "${BOLD}Useful Commands:${NC}"
    echo -e "• ${YELLOW}./scripts/deploy/status-display.sh${NC}     - Interactive dashboard"
    echo -e "• ${YELLOW}./scripts/deploy/start-services.sh status${NC} - Quick status check"
    echo -e "• ${YELLOW}./scripts/deploy/start-services.sh stop${NC}   - Stop all services"
    echo -e "• ${YELLOW}./scripts/deploy/start-services.sh start${NC}  - Start all services"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "1. Open your browser and go to http://localhost:8888"
    echo "2. Configure your agents and workflows"
    echo "3. Start building with the Automagik Suite!"
    echo ""
    echo -e "${BOLD}Support:${NC}"
    echo "• Documentation: Visit the repository README files"
    echo "• Logs: Check ./automagik-install.log for installation details"
    echo "• Issues: Report problems in the respective GitHub repositories"
    echo ""
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Would you like to open the dashboard now? [Y/n]: " dashboard_choice
            case $dashboard_choice in
                [Yy]|[Yy][Ee][Ss]|"")
                    log_info "Opening Automagik Suite dashboard..."
                    "$SCRIPT_DIR/scripts/deploy/status-display.sh" dashboard
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "You can open the dashboard later with: ./scripts/deploy/status-display.sh"
                    break
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    return 0
}

# Run installation step
run_installation_step() {
    local step="$1"
    
    case "$step" in
        "welcome")
            show_welcome
            ;;
        "system_detection")
            run_system_detection
            ;;
        "dependency_installation")
            install_dependencies
            ;;
        "repository_cloning")
            clone_repositories
            ;;
        "api_key_collection")
            collect_api_keys
            ;;
        "environment_setup")
            setup_environments
            ;;
        "deployment")
            deploy_services
            ;;
        "verification")
            verify_installation
            ;;
        "completion")
            show_completion
            ;;
        *)
            log_error "Unknown installation step: $step"
            return 1
            ;;
    esac
}

# Main installation function
main_installation() {
    local start_time=$(date +%s)
    
    # Show progress
    local total_steps=${#INSTALLATION_STEPS[@]}
    local current_step=0
    
    for step in "${INSTALLATION_STEPS[@]}"; do
        ((current_step++))
        
        print_progress "$current_step" "$total_steps" "Running $step..."
        
        if ! run_installation_step "$step"; then
            log_error "Installation failed at step: $step"
            return 1
        fi
        
        # Brief pause between steps
        sleep 1
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    log_success "Installation completed in ${minutes}m ${seconds}s"
    
    return 0
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install          Full installation (default)"
    echo "  dependencies     Install dependencies only"
    echo "  clone            Clone repositories only"
    echo "  keys             Collect API keys only"
    echo "  envs             Setup environments only"
    echo "  deploy           Deploy services only"
    echo "  verify           Verify installation"
    echo "  status           Show system status"
    echo "  uninstall        Remove all components"
    echo ""
    echo "Options:"
    echo "  --interactive        Run in interactive mode (default)"
    echo "  --non-interactive    Run in automated mode"
    echo "  --skip-deps          Skip dependency installation"
    echo "  --skip-browser       Skip browser tools installation"
    echo "  --skip-clone         Skip repository cloning"
    echo "  --skip-envs          Skip environment setup"
    echo "  --skip-deploy        Skip service deployment"
    echo "  --help               Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  INSTALL_MODE=interactive|automated"
    echo "  SKIP_DEPENDENCIES=true|false"
    echo "  SKIP_BROWSER_TOOLS=true|false"
    echo "  SKIP_CLONE=true|false"
    echo "  SKIP_ENV_SETUP=true|false"
    echo "  SKIP_DEPLOY=true|false"
    echo ""
}

# Uninstall function
uninstall_automagik() {
    log_section "Automagik Suite Uninstallation"
    
    log_warning "This will remove all Automagik components and data"
    log_warning "This action cannot be undone!"
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Are you sure you want to uninstall everything? [y/N]: " confirm
            case $confirm in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                [Nn]|[Nn][Oo]|"")
                    log_info "Uninstallation cancelled"
                    return 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
    # Stop and remove Docker services
    log_info "Stopping and removing Docker services..."
    "$SCRIPT_DIR/scripts/deploy/start-services.sh" cleanup
    
    # Clean repositories
    log_info "Cleaning repositories..."
    "$SCRIPT_DIR/scripts/setup/clone-repos.sh" clean
    
    # Clean environment files
    log_info "Cleaning environment files..."
    "$SCRIPT_DIR/scripts/setup/setup-envs.sh" clean
    
    # Remove log files
    log_info "Cleaning log files..."
    rm -f "$SCRIPT_DIR"/*.log
    rm -f "$SCRIPT_DIR"/system-info.env
    
    log_success "Automagik Suite uninstalled successfully"
    
    return 0
}


# Main function when script is run directly
main() {
    # Parse arguments and get remaining args
    local remaining_args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                export INSTALL_MODE="interactive"
                shift
                ;;
            --non-interactive)
                export INSTALL_MODE="automated"
                shift
                ;;
            --skip-deps)
                export SKIP_DEPENDENCIES="true"
                shift
                ;;
            --skip-clone)
                export SKIP_CLONE="true"
                shift
                ;;
            --skip-browser)
                export SKIP_BROWSER_TOOLS="true"
                shift
                ;;
            --skip-envs)
                export SKIP_ENV_SETUP="true"
                shift
                ;;
            --skip-deploy)
                export SKIP_DEPLOY="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                remaining_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Determine command from remaining args
    local command="${remaining_args[0]:-install}"
    
    case "$command" in
        "install"|"")
            main_installation
            ;;
        "dependencies")
            install_dependencies
            ;;
        "clone")
            clone_repositories
            ;;
        "keys")
            collect_api_keys
            ;;
        "envs")
            setup_environments
            ;;
        "deploy")
            deploy_services
            ;;
        "verify")
            verify_installation
            ;;
        "status")
            "$SCRIPT_DIR/scripts/deploy/status-display.sh" status
            ;;
        "uninstall")
            uninstall_automagik
            ;;
        *)
            echo "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Make sure we're in the right directory
cd "$SCRIPT_DIR"

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi