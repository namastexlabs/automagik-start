#!/bin/bash

# ===================================================================
# 🍎 macOS Dependencies Installer
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Package lists
HOMEBREW_PACKAGES=(
    "curl"
    "wget"
    "git"
    "jq"
    "bc"
    "lsof"
)

# Version requirements
PYTHON_MIN_VERSION="3.12"
NODE_MIN_VERSION="22"

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

# Install Python via Homebrew
install_python() {
    log_section "Installing Python Environment"
    
    # Check current Python installation
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        local version_check=$(python3 -c "import sys; print(sys.version_info >= (3, 12))" 2>/dev/null)
        
        if [ "$version_check" = "True" ]; then
            log_success "Python $python_version meets requirements (>= $PYTHON_MIN_VERSION)"
        else
            log_warning "Python $python_version may be too old, installing newer version"
            install_python_homebrew
        fi
    else
        log_info "Python not found, installing via Homebrew..."
        install_python_homebrew
    fi
    
    # Install uv package manager
    install_uv
    
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

# Install Node.js and pnpm
install_nodejs() {
    log_section "Installing Node.js Environment"
    
    # Check if Node.js is already installed with correct version
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version 2>/dev/null | sed 's/^v//')
        local major_version=$(echo "$node_version" | cut -d'.' -f1)
        
        if [ "$major_version" -ge "$NODE_MIN_VERSION" ]; then
            log_success "Node.js $node_version meets requirements (>= $NODE_MIN_VERSION)"
        else
            log_warning "Node.js $node_version is too old, installing newer version"
            install_nodejs_homebrew
        fi
    else
        log_info "Node.js not found, installing via Homebrew..."
        install_nodejs_homebrew
    fi
    
    # Install pnpm
    install_pnpm
    
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

# Install additional development tools
install_dev_tools() {
    log_section "Installing Development Tools"
    
    local dev_packages=(
        "vim"
        "htop"
        "tree"
        "tmux"
        "sqlite"
        "rsync"
        "watch"
        "gh"
    )
    
    local failed_packages=()
    
    for package in "${dev_packages[@]}"; do
        if brew list "$package" >/dev/null 2>&1; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if brew install "$package"; then
                log_success "$package installed successfully"
            else
                log_warning "Failed to install $package (non-critical)"
                failed_packages+=("$package")
            fi
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_warning "Some development tools failed to install: ${failed_packages[*]}"
    else
        log_success "All development tools installed successfully"
    fi
    
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

# Install Claude Code CLI
install_claude_code() {
    log_section "Installing Claude Code CLI"
    
    if command -v claude >/dev/null 2>&1; then
        local claude_version=$(claude --version 2>/dev/null || echo "unknown")
        log_success "Claude Code is already installed: $claude_version"
        return 0
    fi
    
    log_info "Installing Claude Code CLI..."
    
    # Install via npm (requires Node.js) - only supported method
    if command -v npm >/dev/null 2>&1; then
        if npm install -g @anthropic-ai/claude-code; then
            local claude_version=$(claude --version 2>/dev/null || echo "installed")
            log_success "Claude Code CLI installed: $claude_version"
        else
            log_error "Failed to install Claude Code CLI via npm"
            return 1
        fi
    else
        log_error "NPM not available for Claude Code installation"
        return 1
    fi
    
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

# Install browser tools and automation dependencies (optional)
install_browser_tools() {
    log_section "Browser Tools and Automation (Optional)"
    
    echo -e "${YELLOW}Browser tools are optional and needed for:${NC}"
    echo "• Genie Agent - Browser automation for frontend debugging"
    echo "• Web scraping and automation tasks"
    echo "• Performance testing with Lighthouse"
    echo "• Headless browser testing"
    echo ""
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Install browser tools (Playwright, Lighthouse, Puppeteer)? [Y/n]: " install_browser
            case $install_browser in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Skipping browser tools installation"
                    log_info "You can install them later if needed for Genie Agent"
                    return 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    else
        log_info "Auto-installing browser tools in non-interactive mode"
    fi
    
    # Install Playwright via npm
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g playwright >/dev/null 2>&1; then
            log_success "Playwright is already installed globally"
        else
            log_info "Installing Playwright..."
            if npm install -g playwright; then
                log_success "Playwright installed successfully"
                
                # Install Playwright browsers
                log_info "Installing Playwright browsers (this may take a few minutes)..."
                if npx playwright install --with-deps; then
                    log_success "Playwright browsers installed successfully"
                else
                    log_warning "Failed to install Playwright browsers"
                fi
            else
                log_warning "Failed to install Playwright"
            fi
        fi
    else
        log_warning "NPM not available for Playwright installation"
    fi
    
    # Install Lighthouse
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g lighthouse >/dev/null 2>&1; then
            log_success "Lighthouse is already installed globally"
        else
            log_info "Installing Lighthouse..."
            if npm install -g lighthouse; then
                log_success "Lighthouse installed successfully"
            else
                log_warning "Failed to install Lighthouse"
            fi
        fi
    else
        log_warning "NPM not available for Lighthouse installation"
    fi
    
    # Install Puppeteer
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g puppeteer >/dev/null 2>&1; then
            log_success "Puppeteer is already installed globally"
        else
            log_info "Installing Puppeteer..."
            if npm install -g puppeteer; then
                log_success "Puppeteer installed successfully"
            else
                log_warning "Failed to install Puppeteer"
            fi
        fi
    else
        log_warning "NPM not available for Puppeteer installation"
    fi
    
    log_success "Browser tools installation completed"
    return 0
}

# Clean up Homebrew cache
cleanup_packages() {
    log_info "Cleaning up Homebrew cache..."
    
    brew cleanup --prune=all
    
    log_success "Homebrew cleanup completed"
}

# Verify all installations
verify_installations() {
    log_section "Installation Verification"
    
    local verification_failed=false
    
    # Check required commands
    local required_commands=(
        "curl:curl"
        "git:git"
        "python3:python"
        "uv:uv"
        "node:node"
        "pnpm:pnpm"
        "docker:docker"
        "brew:homebrew"
        "gh:gh"
        "claude:claude-cli"
    )
    
    for cmd_info in "${required_commands[@]}"; do
        local cmd="${cmd_info%:*}"
        local package="${cmd_info#*:}"
        
        if command -v "$cmd" >/dev/null 2>&1; then
            local version=""
            case "$cmd" in
                "python3") version=$(python3 --version 2>&1 | cut -d' ' -f2) ;;
                "uv") version=$(uv --version 2>/dev/null | cut -d' ' -f2) ;;
                "node") version=$(node --version 2>/dev/null | sed 's/^v//') ;;
                "pnpm") version=$(pnpm --version 2>/dev/null) ;;
                "docker") version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//') ;;
                "git") version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
                "brew") version=$(brew --version 2>/dev/null | head -1 | cut -d' ' -f2) ;;
                "gh") version=$(gh --version 2>/dev/null | head -1 | cut -d' ' -f3) ;;
                "claude") version=$(claude --version 2>/dev/null || echo "installed") ;;
                *) version="installed" ;;
            esac
            
            log_success "$cmd: $version"
        else
            log_error "$cmd not found ($package package)"
            verification_failed=true
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
        "install_xcode_tools"
        "install_homebrew"
        "install_system_packages" 
        "install_python"
        "install_nodejs"
        "install_docker"
        "install_browser_tools"
        "install_dev_tools"
        "install_claude_code"
        "setup_github_cli"
        "cleanup_packages"
        "verify_installations"
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
    
    echo -e "${CYAN}What was installed:${NC}"
    echo "• Xcode Command Line Tools (build tools)"
    echo "• Homebrew package manager"
    echo "• System packages: curl, git, jq, etc."
    echo "• Python 3.11+ with uv package manager"
    echo "• Node.js 20+ with pnpm package manager"  
    echo "• Docker Desktop for Mac"
    echo "• Development tools: vim, htop, sqlite, etc."
    echo ""
    
    echo -e "${CYAN}Next steps:${NC}"
    echo "• Restart your terminal"
    echo "• Start Docker Desktop"
    echo "• Run the Automagik installer"
    echo ""
}

# Main function when script is run directly
main() {
    case "${1:-install}" in
        "install"|"")
            install_dependencies
            ;;
        "verify")
            verify_installations
            ;;
        "xcode")
            install_xcode_tools
            ;;
        "homebrew")
            install_homebrew
            ;;
        "python")
            install_python
            ;;
        "nodejs")
            install_nodejs
            ;;
        "docker")
            install_docker
            ;;
        "dev-tools")
            install_dev_tools
            ;;
        *)
            echo "Usage: $0 {install|verify|xcode|homebrew|python|nodejs|docker|dev-tools}"
            echo "  install    - Install all dependencies (default)"
            echo "  verify     - Verify installations"
            echo "  xcode      - Install Xcode Command Line Tools only"
            echo "  homebrew   - Install Homebrew only"
            echo "  python     - Install Python environment only"
            echo "  nodejs     - Install Node.js environment only"
            echo "  docker     - Install Docker only"
            echo "  dev-tools  - Install development tools only"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi