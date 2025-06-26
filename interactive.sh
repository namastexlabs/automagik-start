#!/bin/bash

# ===================================================================
# 🎯 Automagik Start - Interactive Installer Wrapper
# ===================================================================
# This script downloads the installer and runs it in interactive mode
# Usage: curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh | bash

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

# Check if running as root (removed restriction for VPS compatibility)
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root user - some features may behave differently"
        log_info "Consider using a regular user with sudo privileges for better security"
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
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_warning "Missing required commands: ${missing_commands[*]}"
        log_info "Auto-installing missing requirements..."
        
        # Auto-install missing commands
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt >/dev/null 2>&1; then
                log_info "Updating package list..."
                sudo apt update -qq
                log_info "Installing: ${missing_commands[*]}"
                sudo apt install -y ${missing_commands[*]}
            elif command -v yum >/dev/null 2>&1; then
                log_info "Installing: ${missing_commands[*]}"
                sudo yum install -y ${missing_commands[*]}
            elif command -v dnf >/dev/null 2>&1; then
                log_info "Installing: ${missing_commands[*]}"
                sudo dnf install -y ${missing_commands[*]}
            else
                log_error "No supported package manager found"
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew >/dev/null 2>&1; then
                log_info "Installing: ${missing_commands[*]}"
                brew install ${missing_commands[*]}
            else
                log_error "Homebrew not found. Please install it first: https://brew.sh"
                exit 1
            fi
        else
            log_error "Unsupported operating system"
            exit 1
        fi
        
        # Verify installation
        local still_missing=()
        for cmd in "${missing_commands[@]}"; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                still_missing+=("$cmd")
            fi
        done
        
        if [ ${#still_missing[@]} -gt 0 ]; then
            log_error "Failed to install: ${still_missing[*]}"
            exit 1
        else
            log_success "All requirements installed successfully"
        fi
    fi
    
    log_success "All requirements met"
}

# Clean up function
cleanup() {
    # Don't clean up in interactive mode - user might want to explore
    echo ""
}

# Set up trap for cleanup
trap cleanup EXIT

# Download the installer
download_installer() {
    log_section "Downloading Automagik Start Interactive Installer"
    
    # Check if directory already exists
    if [ -d "$INSTALL_DIR" ]; then
        log_warning "Directory '$INSTALL_DIR' already exists"
        while true; do
            read -p "Remove existing directory and download fresh? [Y/n]: " remove_choice
            case $remove_choice in
                [Yy]|[Yy][Ee][Ss]|"")
                    rm -rf "$INSTALL_DIR"
                    log_info "Removed existing directory"
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Using existing directory"
                    cd "$INSTALL_DIR"
                    return 0
                    ;;
                *)
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    fi
    
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
run_interactive_installer() {
    log_section "Running Interactive Automagik Start Installer"
    
    # Make sure the main installer is executable
    chmod +x install.sh
    
    # Make all script files executable
    find scripts/ -name "*.sh" -exec chmod +x {} \;
    
    log_info "Starting interactive installation..."
    log_info "You'll be prompted for confirmation at each step"
    echo ""
    
    # Run the main installer in interactive mode
    ./install.sh --interactive
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
    echo -e "${BOLD}${GREEN}🎯 Automagik Start - Interactive Installer${NC}"
    echo ""
    echo "This will download and run the Automagik Suite installer with full interactivity:"
    echo "• Step-by-step confirmations before each phase"
    echo "• Choose which components to install"
    echo "• Branch selection for am-agents-labs"
    echo "• Interactive API key setup"
    echo "• Customization options at each step"
    echo ""
    echo -e "${YELLOW}📋 What you'll be asked:${NC}"
    echo "1. Confirm system detection and compatibility check"
    echo "2. Choose dependencies to install (Python, Node.js, Docker, etc.)"
    echo "3. Optionally install browser tools (for Genie Agent)"
    echo "4. Select branch for am-agents-labs repository"
    echo "5. Set up API keys interactively (or skip for later)"
    echo "6. Confirm service deployment and startup"
    echo ""
    echo -e "${CYAN}💡 One-line interactive command:${NC}"
    echo "curl -O https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh && chmod +x interactive.sh && ./interactive.sh"
    echo ""
}

# Main function
main() {
    show_welcome
    
    # Give user a chance to read and confirm
    while true; do
        read -p "Ready to start interactive installation? [Y/n]: " start_install
        case $start_install in
            [Yy]|[Yy][Ee][Ss]|"")
                break
                ;;
            [Nn]|[Nn][Oo])
                log_info "Installation cancelled by user"
                echo ""
                echo "Alternative installation methods:"
                echo "• Automated: curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash"
                echo "• Manual: git clone https://github.com/namastexlabs/automagik-start.git && cd automagik-start && ./install.sh"
                exit 0
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
    
    check_root
    check_requirements
    download_installer
    run_interactive_installer
    
    # Success message
    echo ""
    log_success "Interactive installation completed!"
    log_info "The installer files are available in the '$INSTALL_DIR' directory"
    log_info "You can re-run specific parts with: cd $INSTALL_DIR && ./install.sh [command]"
}

# Handle script arguments
if [ $# -gt 0 ] && [ "$1" = "--help" ]; then
    echo "Automagik Start Interactive Installer"
    echo ""
    echo "Usage:"
    echo "  curl -O https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh && chmod +x interactive.sh && ./interactive.sh"
    echo ""
    echo "Features:"
    echo "  • Downloads installer to local directory"
    echo "  • Runs in full interactive mode with step-by-step prompts"
    echo "  • Allows customization of all installation options"
    echo "  • Keeps installer files for future use"
    echo ""
    echo "Comparison:"
    echo "  • bootstrap.sh: Quick automated installation"
    echo "  • interactive.sh: Full interactive installation (this script)"
    echo "  • Manual: git clone + ./install.sh"
    echo ""
    exit 0
fi

# Check if we have a proper terminal for interaction
if [ ! -t 1 ]; then
    log_error "This script requires an interactive terminal"
    log_info "It looks like you're running this in a non-interactive environment"
    log_info "For automated installation, use:"
    echo "  curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/bootstrap.sh | bash"
    echo ""
    log_info "For true interactive installation, use this working command:"
    echo "  curl -O https://raw.githubusercontent.com/namastexlabs/automagik-start/main/interactive.sh && chmod +x interactive.sh && ./interactive.sh"
    exit 1
fi

# Run main function
main "$@"