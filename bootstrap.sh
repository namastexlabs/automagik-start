#!/bin/bash

# ===================================================================
# 🚀 Automagik Start - Bootstrap Installer
# ===================================================================
# This script downloads and runs the complete Automagik Start installer
# Usage: curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Symbols
CHECKMARK="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"

# Configuration
REPO_URL="https://github.com/namastexlabs/automagik-start.git"
INSTALL_DIR="automagik-start"
BRANCH="main"

# Logging functions
log_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

log_success() {
    echo -e "${GREEN}${CHECKMARK} $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

log_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this installer as root"
        log_info "Run as a regular user with sudo privileges instead"
        exit 1
    fi
}

# Check for required commands
check_requirements() {
    log_info "Checking requirements..."
    
    local missing_commands=()
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        missing_commands+=("git")
    fi
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_commands+=("curl")
    fi
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Please install them first using your package manager:"
        
        # Detect OS and suggest installation commands
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt >/dev/null 2>&1; then
                echo "  sudo apt update && sudo apt install -y ${missing_commands[*]}"
            elif command -v yum >/dev/null 2>&1; then
                echo "  sudo yum install -y ${missing_commands[*]}"
            elif command -v dnf >/dev/null 2>&1; then
                echo "  sudo dnf install -y ${missing_commands[*]}"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install ${missing_commands[*]}"
        fi
        
        exit 1
    fi
    
    log_success "All requirements met"
}

# Clean up function
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Download and extract the installer
download_installer() {
    log_section "Downloading Automagik Start Installer"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    log_info "Cloning installer from $REPO_URL..."
    
    # Clone the repository
    if git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"; then
        log_success "Installer downloaded successfully"
    else
        log_error "Failed to download installer"
        log_info "Please check your internet connection and try again"
        exit 1
    fi
    
    cd "$INSTALL_DIR"
}

# Run the installer
run_installer() {
    log_section "Running Automagik Start Installer"
    
    # Make sure the main installer is executable
    chmod +x install.sh
    
    # Make all script files executable
    find scripts/ -name "*.sh" -exec chmod +x {} \;
    
    log_info "Starting installation..."
    echo ""
    
    # Ensure interactive mode unless explicitly set to non-interactive
    local install_args=("$@")
    local has_mode_flag=false
    
    for arg in "$@"; do
        if [[ "$arg" == "--non-interactive" ]] || [[ "$arg" == "--interactive" ]]; then
            has_mode_flag=true
            break
        fi
    done
    
    # If no mode flag specified, check if we can actually be interactive
    if [ "$has_mode_flag" = false ]; then
        # Check if we have proper interactive terminal
        if [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
            install_args+=("--interactive")
            log_info "Running in interactive mode (use --non-interactive to disable prompts)"
            echo ""
        else
            install_args+=("--non-interactive")
            log_warning "Piped input detected - running in non-interactive mode"
            log_info "For interactive installation, download and run locally:"
            echo "  git clone https://github.com/namastexlabs/automagik-start.git"
            echo "  cd automagik-start"
            echo "  ./install.sh"
            echo ""
        fi
    fi
    
    # Run the main installer with arguments
    ./install.sh "${install_args[@]}"
}

# Show welcome message
show_welcome() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "   ___         __                             _ _      "
    echo "  / _ \\       / _|                           (_) |     "
    echo " / /_\\ \\_   _| |_ ___  _ __ ___   __ _  __ _ _  _| | __  "
    echo " |  _  | | | |  _/ _ \\| '_ \` _ \\ / _\` |/ _\` | | | |/ /  "
    echo " | | | | |_| | || (_) | | | | | | (_| | (_| | | |   <   "
    echo " \\_| |_/\\__,_|_| \\___/|_| |_| |_|\\__,_|\\__, |_|_|_|\\_\\  "
    echo "                                       __/ |          "
    echo "                                      |___/           "
    echo -e "${NC}"
    echo -e "${BOLD}${GREEN}🚀 Automagik Start - Bootstrap Installer${NC}"
    echo ""
    echo "This will download and install the complete Automagik Suite:"
    echo "• am-agents-labs (Main Orchestrator)"
    echo "• automagik-spark (Workflow Engine)"
    echo "• automagik-tools (MCP Tools)"
    echo "• automagik-evolution (WhatsApp API)"
    echo "• automagik-omni (Multi-tenant Hub)"
    echo "• automagik-ui-v2 (Main Interface)"
    echo ""
    echo -e "${YELLOW}⚡ One-line install command:${NC}"
    echo "curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash"
    echo ""
}

# Main function
main() {
    show_welcome
    check_root
    check_requirements
    download_installer
    run_installer "$@"
    
    # Success message
    echo ""
    log_success "Bootstrap completed successfully!"
    log_info "Your Automagik Suite should now be running at http://localhost:8888"
}

# Handle script arguments
if [ $# -gt 0 ] && [ "$1" = "--help" ]; then
    echo "Automagik Start Bootstrap Installer"
    echo ""
    echo "Usage:"
    echo "  curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash"
    echo ""
    echo "Options (pass after the pipe):"
    echo "  --non-interactive    Run in automated mode"
    echo "  --skip-deps          Skip dependency installation"
    echo "  --skip-browser       Skip browser tools installation"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Quick automated installation (recommended for most users)"
    echo "  curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash"
    echo ""
    echo "  # For interactive step-by-step installation:"
    echo "  curl -O https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh && chmod +x interactive.sh && ./interactive.sh"
    echo ""
    exit 0
fi

# Run main function with all arguments
main "$@"