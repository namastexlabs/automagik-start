#!/bin/bash

# ===================================================================
# 🍎 macOS Dependencies Installer (Optimized for Docker Deployment)
# ===================================================================
# 
# This optimized version installs only essential tools for Docker-based
# deployment. All application services run in containers, so local
# Python, Node.js, and development tools are skipped to minimize
# installation time and disk usage.
#
# What's installed:
# ✅ Xcode Command Line Tools (for git)
# ✅ Homebrew (package manager) 
# ✅ Git, curl, jq (essential tools)
# ✅ Docker Desktop (to run containers)
# ✅ GitHub CLI (optional, for repo access)
#
# What's skipped:
# ⏭️  Python/uv (runs in containers)
# ⏭️  Node.js/pnpm (runs in containers)  
# ⏭️  Browser tools (runs in containers)
# ⏭️  Development tools (vim, htop, etc.)
# ⏭️  Claude Code CLI (not needed for deployment)
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Minimal package list for Docker-based deployment
HOMEBREW_PACKAGES=(
    "git"      # Required for repository cloning
    "curl"     # Required for downloading scripts and health checks
    "jq"       # Optional: for JSON parsing in status checks
)

# Docker-only deployment doesn't need Python/Node locally
# All services run in containers

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is for macOS systems only"
        return 1
    fi
    
    local macos_version=$(sw_vers -productVersion)
    log_info "macOS version: $macos_version"
    
    # Check minimum macOS version (10.15 Catalina)
    local major_version=$(echo "$macos_version" | cut -d'.' -f1)
    local minor_version=$(echo "$macos_version" | cut -d'.' -f2)
    
    if [ "$major_version" -gt 10 ] || ([ "$major_version" -eq 10 ] && [ "$minor_version" -ge 15 ]); then
        log_success "macOS version is supported"
        return 0
    else
        log_warning "macOS version may be too old (10.15+ recommended)"
        return 0
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    log_info "Checking Xcode Command Line Tools..."
    
    if xcode-select -p >/dev/null 2>&1; then
        log_success "Xcode Command Line Tools are already installed"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    log_warning "This may take several minutes and will open a GUI installer"
    
    # Trigger the installation
    xcode-select --install
    
    # Wait for installation to complete
    log_info "Waiting for Xcode Command Line Tools installation to complete..."
    while ! xcode-select -p >/dev/null 2>&1; do
        echo -ne "\r${YELLOW}Waiting for Xcode tools installation...${NC}"
        sleep 5
    done
    
    echo ""
    log_success "Xcode Command Line Tools installed successfully"
    return 0
}

# Install Homebrew
install_homebrew() {
    log_info "Checking Homebrew installation..."
    
    if command -v brew >/dev/null 2>&1; then
        log_success "Homebrew is already installed"
        
        # Update Homebrew
        log_info "Updating Homebrew..."
        if brew update; then
            log_success "Homebrew updated successfully"
        else
            log_warning "Homebrew update failed (continuing anyway)"
        fi
        
        return 0
    fi
    
    log_info "Installing Homebrew..."
    log_info "This may require your password and take several minutes"
    
    # Install Homebrew using official installation script
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_success "Homebrew installed successfully"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Macs
            eval "$(/opt/homebrew/bin/brew shellenv)"
            add_to_shell_profile 'eval "$(/opt/homebrew/bin/brew shellenv)"'
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Macs
            eval "$(/usr/local/bin/brew shellenv)"
            add_to_shell_profile 'eval "$(/usr/local/bin/brew shellenv)"'
        fi
        
        # Verify installation
        if command -v brew >/dev/null 2>&1; then
            local brew_version=$(brew --version | head -1 | cut -d' ' -f2)
            log_success "Homebrew $brew_version is now available"
            return 0
        else
            log_error "Homebrew installation verification failed"
            return 1
        fi
    else
        log_error "Homebrew installation failed"
        return 1
    fi
}

# Install system packages via Homebrew
install_system_packages() {
    log_section "Installing System Packages"
    
    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew not available"
        return 1
    fi
    
    local failed_packages=()
    
    for package in "${HOMEBREW_PACKAGES[@]}"; do
        if brew list "$package" >/dev/null 2>&1; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if brew install "$package"; then
                log_success "$package installed successfully"
            else
                log_error "Failed to install $package"
                failed_packages+=("$package")
            fi
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "Failed to install packages: ${failed_packages[*]}"
        return 1
    else
        log_success "All system packages installed successfully"
        return 0
    fi
}

# Skip Python installation - runs in Docker containers
skip_python_install() {
    log_info "Skipping Python installation - services run in Docker containers"
    log_info "Python/uv will be available inside the containers as needed"
    
    # Check if system Python exists (for any helper scripts)
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_info "System Python $python_version detected (not required for Docker deployment)"
    fi
    
    return 0
}

# Install Python via Homebrew
install_python_homebrew() {
    log_info "Installing Python via Homebrew..."
    
    if brew list python@3.11 >/dev/null 2>&1 || brew list python@3.12 >/dev/null 2>&1; then
        log_success "Modern Python is already installed via Homebrew"
    else
        if brew install python@3.11; then
            log_success "Python installed via Homebrew"
            
            # Link python3 command
            brew link --overwrite python@3.11 2>/dev/null || true
        else
            log_error "Failed to install Python via Homebrew"
            return 1
        fi
    fi
    
    # Verify installation
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_success "Python $python_version is now available"
        return 0
    else
        log_error "Python installation verification failed"
        return 1
    fi
}

# Install uv package manager
install_uv() {
    log_info "Installing uv (Python package manager)..."
    
    if command -v uv >/dev/null 2>&1; then
        log_success "uv is already installed"
        return 0
    fi
    
    # Install uv using the official installer
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Verify installation
        if command -v uv >/dev/null 2>&1; then
            local uv_version=$(uv --version 2>/dev/null | cut -d' ' -f2)
            log_success "uv $uv_version installed successfully"
            
            # Add to shell profile
            add_to_shell_profile 'export PATH="$HOME/.local/bin:$PATH"'
            
            return 0
        else
            log_error "uv installation verification failed"
            return 1
        fi
    else
        log_error "Failed to install uv"
        return 1
    fi
}

# Skip Node.js installation - runs in Docker containers
skip_nodejs_install() {
    log_info "Skipping Node.js installation - frontend services run in Docker containers"
    log_info "Node.js/pnpm will be available inside the containers as needed"
    
    # Check if system Node.js exists (not required)
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version 2>/dev/null | sed 's/^v//')
        log_info "System Node.js $node_version detected (not required for Docker deployment)"
    fi
    
    return 0
}

# Install Node.js via Homebrew
install_nodejs_homebrew() {
    log_info "Installing Node.js via Homebrew..."
    
    if brew list node >/dev/null 2>&1; then
        log_info "Upgrading existing Node.js installation..."
        brew upgrade node || brew install node
    else
        if brew install node; then
            log_success "Node.js installed via Homebrew"
        else
            log_error "Failed to install Node.js via Homebrew"
            return 1
        fi
    fi
    
    # Verify installation
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version 2>/dev/null | sed 's/^v//')
        log_success "Node.js $node_version is now available"
        return 0
    else
        log_error "Node.js installation verification failed"
        return 1
    fi
}

# Install pnpm package manager
install_pnpm() {
    log_info "Installing pnpm package manager..."
    
    if command -v pnpm >/dev/null 2>&1; then
        log_success "pnpm is already installed"
        return 0
    fi
    
    # Try installing via Homebrew first
    if brew install pnpm; then
        local pnpm_version=$(pnpm --version 2>/dev/null)
        log_success "pnpm $pnpm_version installed via Homebrew"
        return 0
    elif command -v npm >/dev/null 2>&1; then
        # Fallback to npm installation
        log_info "Installing pnpm via npm..."
        if npm install -g pnpm; then
            local pnpm_version=$(pnpm --version 2>/dev/null)
            log_success "pnpm $pnpm_version installed via npm"
            return 0
        else
            log_error "Failed to install pnpm"
            return 1
        fi
    else
        log_error "Neither Homebrew nor npm available for pnpm installation"
        return 1
    fi
}

# Install Docker Desktop for Mac
install_docker() {
    log_section "Installing Docker"
    
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
        log_success "Docker $docker_version is already installed"
        
        # Check if Docker is running
        if ! docker info >/dev/null 2>&1; then
            log_warning "Docker Desktop is not running"
            log_info "Please start Docker Desktop from Applications"
        else
            log_success "Docker is running and accessible"
        fi
        
        return 0
    fi
    
    log_info "Installing Docker via Homebrew..."
    
    # Install Docker Desktop via Homebrew Cask
    if brew install --cask docker; then
        log_success "Docker Desktop installed successfully"
        
        log_warning "Please start Docker Desktop from Applications folder"
        log_warning "Docker commands will be available after Docker Desktop starts"
        
        # Wait for user to start Docker Desktop
        log_info "Waiting for Docker Desktop to start..."
        local timeout=120
        local elapsed=0
        
        while [ $elapsed -lt $timeout ]; do
            if docker info >/dev/null 2>&1; then
                log_success "Docker Desktop is now running"
                break
            fi
            
            echo -ne "\r${YELLOW}Waiting for Docker Desktop... ${elapsed}s${NC}"
            sleep 5
            elapsed=$((elapsed + 5))
        done
        
        if [ $elapsed -ge $timeout ]; then
            echo ""
            log_warning "Docker Desktop startup timeout"
            log_info "Please start Docker Desktop manually from Applications"
        fi
        
        return 0
    else
        log_error "Failed to install Docker Desktop"
        log_warning "You can manually download Docker Desktop from: https://docs.docker.com/desktop/mac/install/"
        return 1
    fi
}

# Skip extra development tools for minimal installation
skip_extra_dev_tools() {
    log_info "Skipping extra development tools for minimal Docker deployment"
    log_info "Only essential tools (git, curl, docker) are installed"
    log_info "You can install additional tools later if needed: brew install vim htop tree"
    
    return 0
}

# Add line to shell profile if not already present
add_to_shell_profile() {
    local line="$1"
    local shell_profile=""
    
    # Determine shell profile file
    case "$SHELL" in
        */bash)
            shell_profile="$HOME/.bash_profile"
            ;;
        */zsh)
            shell_profile="$HOME/.zshrc"
            ;;
        */fish)
            shell_profile="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_profile="$HOME/.profile"
            ;;
    esac
    
    # Create profile file if it doesn't exist
    if [ ! -f "$shell_profile" ]; then
        touch "$shell_profile"
    fi
    
    # Add line if not already present
    if ! grep -q "$line" "$shell_profile"; then
        echo "$line" >> "$shell_profile"
        log_info "Added to $shell_profile: $line"
    fi
}

# Skip Claude Code CLI for minimal installation
skip_claude_cli_install() {
    log_info "Skipping Claude Code CLI - not required for Docker deployment"
    log_info "Claude Code can be installed later if needed for development"
    
    return 0
}

# Setup GitHub CLI and authentication
setup_github_cli() {
    log_section "Setting up GitHub CLI"
    
    # Check if gh is installed
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) not found"
        log_info "Installing GitHub CLI via Homebrew..."
        
        if command -v brew >/dev/null 2>&1; then
            if brew install gh; then
                log_success "GitHub CLI installed successfully"
            else
                log_error "Failed to install GitHub CLI"
                return 1
            fi
        else
            log_error "Homebrew not available for GitHub CLI installation"
            return 1
        fi
    else
        local gh_version=$(gh --version 2>/dev/null | head -1 | cut -d' ' -f3)
        log_success "GitHub CLI is already installed: $gh_version"
    fi
    
    # Check authentication status
    if gh auth status >/dev/null 2>&1; then
        local gh_user=$(gh api user --jq .login 2>/dev/null || echo "authenticated")
        log_success "GitHub CLI already authenticated as: $gh_user"
    else
        log_info "GitHub CLI authentication required"
        log_info "This will open your browser for GitHub authentication..."
        
        # Start authentication flow
        if gh auth login --web --git-protocol https --hostname github.com; then
            local gh_user=$(gh api user --jq .login 2>/dev/null || echo "authenticated")
            log_success "GitHub CLI authenticated successfully as: $gh_user"
        else
            log_warning "GitHub CLI authentication failed or was cancelled"
            log_info "You can run 'gh auth login' later to authenticate"
        fi
    fi
    
    return 0
}

# Skip browser tools for minimal installation
skip_browser_tools() {
    log_info "Skipping browser tools - services run in Docker containers"
    log_info "Browser automation tools can be installed later if needed for development"
    
    return 0
}

# Clean up Homebrew cache
cleanup_packages() {
    log_info "Cleaning up Homebrew cache..."
    
    brew cleanup --prune=all
    
    log_success "Homebrew cleanup completed"
}

# Verify minimal installations for Docker deployment
verify_minimal_setup() {
    log_section "Minimal Setup Verification"
    
    local verification_failed=false
    
    # Check only essential commands for Docker deployment
    local required_commands=(
        "curl:curl"
        "git:git"
        "docker:docker"
        "brew:homebrew"
    )
    
    # Optional commands (warn if missing but don't fail)
    local optional_commands=(
        "gh:github-cli"
        "jq:jq"
    )
    
    # Check required commands (fail if missing)
    for cmd_info in "${required_commands[@]}"; do
        local cmd="${cmd_info%:*}"
        local package="${cmd_info#*:}"
        
        if command -v "$cmd" >/dev/null 2>&1; then
            local version=""
            case "$cmd" in
                "docker") version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//') ;;
                "git") version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
                "brew") version=$(brew --version 2>/dev/null | head -1 | cut -d' ' -f2) ;;
                "curl") version=$(curl --version 2>/dev/null | head -1 | cut -d' ' -f2) ;;
                *) version="installed" ;;
            esac
            
            log_success "$cmd: $version"
        else
            log_error "$cmd not found ($package package)"
            verification_failed=true
        fi
    done
    
    # Check optional commands (warn if missing but don't fail)
    for cmd_info in "${optional_commands[@]}"; do
        local cmd="${cmd_info%:*}"
        local package="${cmd_info#*:}"
        
        if command -v "$cmd" >/dev/null 2>&1; then
            local version=""
            case "$cmd" in
                "gh") version=$(gh --version 2>/dev/null | head -1 | cut -d' ' -f3) ;;
                "jq") version=$(jq --version 2>/dev/null | sed 's/^jq-//') ;;
                *) version="installed" ;;
            esac
            
            log_success "$cmd: $version (optional)"
        else
            log_warning "$cmd not found ($package package) - optional"
        fi
    done
    
    # Test Docker functionality
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            log_success "Docker Desktop is running and accessible"
        else
            log_warning "Docker Desktop is not running (start from Applications)"
        fi
        
        # Test Docker Compose (prefer v2 plugin over v1 standalone)
        if docker compose version >/dev/null 2>&1; then
            local compose_version=$(docker compose version --short 2>/dev/null || echo "v2")
            log_success "docker compose: $compose_version"
        elif command -v docker-compose >/dev/null 2>&1; then
            local compose_version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
            log_success "docker-compose (standalone): $compose_version"
        else
            log_error "Docker Compose not available (neither 'docker compose' nor 'docker-compose')"
            verification_failed=true
        fi
    fi
    
    if [ "$verification_failed" = true ]; then
        log_error "Some installations failed verification"
        return 1
    else
        log_success "All installations verified successfully"
        return 0
    fi
}

# Main installation function
install_dependencies() {
    log_section "macOS Dependencies Installation"
    
    # Check if running on macOS
    if ! check_macos; then
        return 1
    fi
    
    local install_steps=(
        "install_xcode_tools"     # Needed for git and build tools
        "install_homebrew"       # Package manager for macOS
        "install_system_packages" # Minimal: git, curl, jq
        "install_docker"         # Required for running containers
        "setup_github_cli"       # Optional: for repository access
        "cleanup_packages"       # Clean up to save space
        "verify_minimal_setup"   # Verify only essential tools
    )
    
    local total_steps=${#install_steps[@]}
    local current_step=0
    
    for step in "${install_steps[@]}"; do
        ((current_step++))
        print_progress "$current_step" "$total_steps" "Running $step..."
        
        if ! $step; then
            echo ""
            log_error "Installation step failed: $step"
            return 1
        fi
        
        sleep 1  # Brief pause between steps
    done
    
    echo ""
    log_success "All dependencies installed successfully!"
    
    # Show post-installation notes
    show_post_install_notes
    
    return 0
}

# Show post-installation notes
show_post_install_notes() {
    log_section "Post-Installation Notes"
    
    echo -e "${YELLOW}Important:${NC}"
    echo "• Restart your terminal or run 'source ~/.zshrc' to update PATH"
    echo "• Start Docker Desktop from Applications folder"
    echo "• Verify installations with: 'automagik-installer.sh verify'"
    echo ""
    
    echo -e "${CYAN}What was installed (minimal Docker setup):${NC}"
    echo "• Xcode Command Line Tools (for git)"
    echo "• Homebrew package manager"
    echo "• Essential packages: git, curl, jq"
    echo "• Docker Desktop for Mac"
    echo "• GitHub CLI (optional)"
    echo ""
    echo -e "${GREEN}✅ All services will run in Docker containers${NC}"
    echo "• No local Python/Node.js installation needed"
    echo "• No browser tools or development packages installed"
    echo "• Minimal disk space usage"
    echo ""
    
    echo -e "${CYAN}Next steps:${NC}"
    echo "• Start Docker Desktop from Applications"
    echo "• Run the Automagik installer"
    echo "• Everything else runs in containers!"
    echo ""
}

# Main function when script is run directly
main() {
    case "${1:-install}" in
        "install"|"")
            install_dependencies
            ;;
        "verify")
            verify_minimal_setup
            ;;
        "xcode")
            install_xcode_tools
            ;;
        "homebrew")
            install_homebrew
            ;;
        "docker")
            install_docker
            ;;
        *)
            echo "Usage: $0 {install|verify|xcode|homebrew|docker}"
            echo "  install    - Install minimal dependencies for Docker deployment (default)"
            echo "  verify     - Verify essential installations" 
            echo "  xcode      - Install Xcode Command Line Tools only"
            echo "  homebrew   - Install Homebrew only"
            echo "  docker     - Install Docker only"
            echo ""
            echo "Optimized for Docker deployment - skips Python/Node.js/dev tools"
            echo "All services run in containers, minimal host requirements"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi