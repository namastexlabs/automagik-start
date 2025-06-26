#!/bin/bash

# ===================================================================
# 🐧 Ubuntu/Debian Dependencies Installer
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Package lists
SYSTEM_PACKAGES=(
    "curl"
    "wget"
    "git"
    "build-essential"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "unzip"
    "jq"
    "bc"
    "lsof"
    "net-tools"
)

PYTHON_PACKAGES=(
    "python3"
    "python3-pip"
    "python3-venv"
    "python3-dev"
    "python3-setuptools"
)

# Version requirements
PYTHON_MIN_VERSION="3.12"
NODE_MIN_VERSION="22"

# Update package list
update_package_list() {
    log_info "Updating package list..."
    
    if sudo apt update -qq; then
        log_success "Package list updated"
        return 0
    else
        log_error "Failed to update package list"
        return 1
    fi
}

# Install system packages
install_system_packages() {
    log_section "Installing System Packages"
    
    local failed_packages=()
    
    for package in "${SYSTEM_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if sudo apt install -y -qq "$package"; then
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

# Install Python and related tools
install_python() {
    log_section "Installing Python Environment"
    
    # Install Python packages
    local failed_packages=()
    
    for package in "${PYTHON_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if sudo apt install -y -qq "$package"; then
                log_success "$package installed successfully"
            else
                log_error "Failed to install $package"
                failed_packages+=("$package")
            fi
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "Failed to install Python packages: ${failed_packages[*]}"
        return 1
    fi
    
    # Verify Python version
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        local version_check=$(python3 -c "import sys; print(sys.version_info >= (3, 12))")
        
        if [ "$version_check" = "True" ]; then
            log_success "Python $python_version meets requirements (>= $PYTHON_MIN_VERSION)"
        else
            log_warning "Python $python_version may be too old (recommended >= $PYTHON_MIN_VERSION)"
        fi
    else
        log_error "Python installation verification failed"
        return 1
    fi
    
    # Install uv (modern Python package manager)
    install_uv
    
    return 0
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
            install_nodejs_repo
        fi
    else
        log_info "Node.js not found, installing..."
        install_nodejs_repo
    fi
    
    # Install pnpm
    install_pnpm
    
    return 0
}

# Install Node.js from NodeSource repository
install_nodejs_repo() {
    log_info "Adding NodeSource repository for Node.js $NODE_MIN_VERSION..."
    
    # Download and install the NodeSource signing key
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    
    # Create NodeSource repository
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MIN_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    
    # Update package list
    sudo apt update -qq
    
    # Install Node.js
    if sudo apt install -y -qq nodejs; then
        local node_version=$(node --version 2>/dev/null | sed 's/^v//')
        log_success "Node.js $node_version installed successfully"
        return 0
    else
        log_error "Failed to install Node.js"
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
    
    # Install pnpm using npm
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed globally
        if npm list -g pnpm >/dev/null 2>&1; then
            local pnpm_version=$(pnpm --version 2>/dev/null)
            log_success "pnpm $pnpm_version is already installed"
            return 0
        else
            if sudo npm install -g pnpm; then
                local pnpm_version=$(pnpm --version 2>/dev/null)
                log_success "pnpm $pnpm_version installed successfully"
                return 0
            else
                log_error "Failed to install pnpm via npm"
                return 1
            fi
        fi
    else
        log_error "npm not available for pnpm installation"
        return 1
    fi
}

# Install Docker
install_docker() {
    log_section "Installing Docker"
    
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
        log_success "Docker $docker_version is already installed"
        
        # Check if Docker is running
        if ! docker info >/dev/null 2>&1; then
            log_info "Starting Docker service..."
            sudo systemctl start docker
            sudo systemctl enable docker
        fi
        
        # Check if user is in docker group
        if ! groups "$USER" | grep -q docker; then
            log_info "Adding user to docker group..."
            sudo usermod -aG docker "$USER"
            log_warning "You need to log out and back in for docker group changes to take effect"
        fi
        
        return 0
    fi
    
    log_info "Installing Docker from official repository..."
    
    # Remove old versions
    sudo apt remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install dependencies
    sudo apt install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list
    sudo apt update -qq
    
    # Install Docker Engine
    if sudo apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
        log_success "Docker $docker_version installed successfully"
        
        # Start and enable Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add user to docker group
        sudo usermod -aG docker "$USER"
        log_warning "You need to log out and back in for docker group changes to take effect"
        
        # Test Docker installation
        if sudo docker run hello-world >/dev/null 2>&1; then
            log_success "Docker installation verified"
        else
            log_warning "Docker installation test failed"
        fi
        
        return 0
    else
        log_error "Failed to install Docker"
        return 1
    fi
}

# Install browser tools and automation dependencies (optional)
install_browser_tools() {
    log_section "Browser Tools and Automation (Optional)"
    
    # Check if browser tools should be skipped
    if [ "$SKIP_BROWSER_TOOLS" = "true" ]; then
        log_info "Skipping browser tools installation (SKIP_BROWSER_TOOLS=true)"
        return 0
    fi
    
    echo -e "${YELLOW}Browser tools are optional and needed for:${NC}"
    echo "• Genie Agent - Browser automation for frontend debugging"
    echo "• Web scraping and automation tasks"
    echo "• Performance testing with Lighthouse"
    echo "• Headless browser testing"
    echo ""
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Install browser tools (Playwright, Lighthouse, Puppeteer)? [y/N]: " install_browser
            case $install_browser in
                [Yy]|[Yy][Ee][Ss])
                    log_info "Proceeding with browser tools installation"
                    break
                    ;;
                [Nn]|[Nn][Oo]|"")
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
        log_info "Non-interactive mode: skipping browser tools by default"
        log_info "Use SKIP_BROWSER_TOOLS=false to force installation in non-interactive mode"
        return 0
    fi
    
    # Install browser dependencies for headless operation
    local browser_packages=(
        "chromium-browser"
        "xvfb"
        "libgtk-3-0"
        "libgbm-dev"
        "libasound2"
        "libxrandr2"
        "libxcomposite1"
        "libxdamage1"
        "libxtst6"
        "libxss1"
        "libnss3"
        "libatk-bridge2.0-0"
        "libdrm2"
        "libxkbcommon0"
        "libatspi2.0-0"
        "libxfixes3"
    )
    
    log_info "Installing browser dependencies for headless operation..."
    
    local failed_packages=()
    
    for package in "${browser_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if sudo apt install -y -qq "$package"; then
                log_success "$package installed successfully"
            else
                log_warning "Failed to install $package (non-critical)"
                failed_packages+=("$package")
            fi
        fi
    done
    
    # Install Playwright via npm with timeout
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g playwright >/dev/null 2>&1; then
            log_success "Playwright is already installed globally"
        else
            log_info "Installing Playwright..."
            if timeout 300 sudo npm install -g playwright 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Playwright installed successfully"
                
                # Install Playwright browsers with timeout
                log_info "Installing Playwright browsers (this may take a few minutes)..."
                if timeout 600 sudo npx playwright install --with-deps 2>&1 | tee -a "$LOG_FILE"; then
                    log_success "Playwright browsers installed successfully"
                else
                    log_warning "Failed to install Playwright browsers (timeout or error)"
                fi
            else
                log_warning "Failed to install Playwright (timeout or error)"
            fi
        fi
    else
        log_warning "NPM not available for Playwright installation"
    fi
    
    # Install Lighthouse with timeout
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g lighthouse >/dev/null 2>&1; then
            log_success "Lighthouse is already installed globally"
        else
            log_info "Installing Lighthouse..."
            if timeout 300 sudo npm install -g lighthouse 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Lighthouse installed successfully"
            else
                log_warning "Failed to install Lighthouse (timeout or error)"
            fi
        fi
    else
        log_warning "NPM not available for Lighthouse installation"
    fi
    
    # Install Puppeteer with timeout
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed
        if npm list -g puppeteer >/dev/null 2>&1; then
            log_success "Puppeteer is already installed globally"
        else
            log_info "Installing Puppeteer..."
            if timeout 300 sudo npm install -g puppeteer 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Puppeteer installed successfully"
            else
                log_warning "Failed to install Puppeteer (timeout or error)"
            fi
        fi
    else
        log_warning "NPM not available for Puppeteer installation"
    fi
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_warning "Some browser packages failed to install: ${failed_packages[*]}"
        log_info "Browser tools installation completed with warnings"
    else
        log_success "All browser tools installed successfully"
    fi
    
    # Ensure we don't loop by explicitly returning
    log_info "Browser tools installation step completed"
    return 0
}

# Install additional development tools
install_dev_tools() {
    log_section "Installing Development Tools"
    
    local dev_packages=(
        "vim"
        "nano"
        "htop"
        "tree"
        "tmux"
        "screen"
        "rsync"
        "zip"
        "unzip"
        "sqlite3"
        "gh"
    )
    
    local failed_packages=()
    
    for package in "${dev_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            if sudo apt install -y -qq "$package"; then
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
            if [ -f "$HOME/.bashrc" ]; then
                shell_profile="$HOME/.bashrc"
            else
                shell_profile="$HOME/.bash_profile"
            fi
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
    
    # Add line if not already present
    if [ -f "$shell_profile" ] && ! grep -q "$line" "$shell_profile"; then
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
    
    # Install via npm (requires Node.js)
    if command -v npm >/dev/null 2>&1; then
        # Check if already installed globally
        if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
            local claude_version=$(claude --version 2>/dev/null || echo "installed")
            log_success "Claude Code CLI is already installed: $claude_version"
        else
            if sudo npm install -g @anthropic-ai/claude-code; then
                local claude_version=$(claude --version 2>/dev/null || echo "installed")
                log_success "Claude Code CLI installed: $claude_version"
            else
                log_error "Failed to install Claude Code CLI via npm"
                return 1
            fi
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
        log_info "Installing GitHub CLI..."
        
        # Add GitHub CLI repository
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        
        sudo apt update -qq
        if sudo apt install -y -qq gh; then
            log_success "GitHub CLI installed successfully"
        else
            log_error "Failed to install GitHub CLI"
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

# Clean up package cache
cleanup_packages() {
    log_info "Cleaning up package cache..."
    
    sudo apt autoremove -y -qq
    sudo apt autoclean -qq
    
    log_success "Package cleanup completed"
}

# Verify all installations
verify_installations() {
    log_section "Installation Verification"
    
    local verification_failed=false
    
    # Check required commands
    local required_commands=(
        "curl:curl"
        "git:git"
        "python3:python3"
        "uv:uv"
        "node:nodejs"
        "pnpm:pnpm"
        "docker:docker"
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
    
    # Test Docker functionality (without sudo if user is in docker group)
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon is running and accessible"
        elif sudo docker info >/dev/null 2>&1; then
            log_warning "Docker requires sudo (user not in docker group or needs re-login)"
        else
            log_error "Docker daemon is not running"
            verification_failed=true
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
    log_section "Ubuntu/Debian Dependencies Installation"
    
    # Check if running on Ubuntu/Debian
    if [ ! -f /etc/debian_version ]; then
        log_error "This script is for Ubuntu/Debian systems only"
        return 1
    fi
    
    # Check for sudo privileges
    if ! sudo -v >/dev/null 2>&1; then
        log_error "This script requires sudo privileges"
        return 1
    fi
    
    local install_steps=(
        "update_package_list"
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
    echo "• You may need to log out and back in for docker group changes to take effect"
    echo "• Run 'source ~/.bashrc' or restart your terminal to update PATH"
    echo "• Verify installations with: 'automagik-installer.sh verify'"
    echo ""
    
    echo -e "${CYAN}What was installed:${NC}"
    echo "• System packages: build tools, curl, git, etc."
    echo "• Python 3.12+ with uv package manager"
    echo "• Node.js 22+ with pnpm package manager"  
    echo "• Docker with Compose v2 plugin"
    echo "• GitHub CLI with authentication"
    echo "• Claude Code CLI"
    echo "• Development tools: vim, htop, sqlite3, etc."
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
            echo "Usage: $0 {install|verify|python|nodejs|docker|dev-tools}"
            echo "  install    - Install all dependencies (default)"
            echo "  verify     - Verify installations"
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