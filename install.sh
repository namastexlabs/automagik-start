#!/bin/bash
# ===================================================================
# 🚀 Automagik Suite - Minimal Pre-dependency Installer
# ===================================================================
# This script installs only the essential pre-dependencies
# then calls the main Makefile for the rest of the installation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Docker Compose Detection Function
detect_docker_compose() {
    if command -v docker >/dev/null 2>&1; then
        # Test docker compose (modern plugin)
        if docker compose version >/dev/null 2>&1; then
            echo "docker compose"
            return 0
        # Test docker-compose (legacy standalone)
        elif command -v docker-compose >/dev/null 2>&1; then
            echo "docker-compose"
            return 0
        else
            echo -e "${RED}❌ Neither 'docker compose' nor 'docker-compose' is available${NC}" >&2
            echo -e "${YELLOW}Please install Docker Compose: https://docs.docker.com/compose/install/${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}❌ Docker is not installed${NC}" >&2
        return 1
    fi
}

# Set Docker Compose command
DOCKER_COMPOSE_CMD=$(detect_docker_compose)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Cannot proceed without Docker Compose${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Using Docker Compose command: ${DOCKER_COMPOSE_CMD}${NC}"

echo -e "${PURPLE}🚀 Automagik Suite - Pre-dependency Installer${NC}"
echo -e "${CYAN}Installing minimal dependencies before main installation...${NC}"
echo ""

# Detect OS
OS_TYPE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
    elif [ -f /etc/redhat-release ]; then
        OS_TYPE="redhat"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
fi

# Check for WSL
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

echo -e "${CYAN}Detected OS: $OS_TYPE${NC}"
[ "$IS_WSL" = true ] && echo -e "${CYAN}Running in WSL${NC}"
echo ""

# Install essential packages
echo -e "${CYAN}Installing essential packages...${NC}"
if [ "$OS_TYPE" = "debian" ]; then
    # Check if essential packages are already installed
    MISSING_PACKAGES=()
    for pkg in curl git make build-essential ca-certificates gnupg; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    else
        echo -e "${GREEN}✓ All essential packages already installed${NC}"
    fi
elif [ "$OS_TYPE" = "macos" ]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Check if essential packages are already installed
    MISSING_PACKAGES=()
    for pkg in curl git make; do
        if ! brew list "$pkg" &> /dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        brew install "${MISSING_PACKAGES[@]}"
    else
        echo -e "${GREEN}✓ All essential packages already installed${NC}"
    fi
fi

# Install Python 3.12 if not present
if ! command -v python3.12 &> /dev/null; then
    echo -e "${CYAN}Installing Python 3.12...${NC}"
    if [ "$OS_TYPE" = "debian" ]; then
        sudo add-apt-repository ppa:deadsnakes/ppa -y 2>/dev/null || true
        sudo apt-get update
        sudo apt-get install -y python3.12 python3.12-venv python3.12-dev
    elif [ "$OS_TYPE" = "macos" ]; then
        brew install python@3.12
    fi
else
    echo -e "${GREEN}✓ Python 3.12 already installed${NC}"
fi

# Install UV package manager
if ! command -v uv &> /dev/null; then
    echo -e "${CYAN}Installing UV package manager...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add UV to PATH for current session and verify it works
    export PATH="$HOME/.local/bin:$PATH"
    
    # Source the UV env file if it exists
    if [ -f "$HOME/.local/bin/env" ]; then
        source "$HOME/.local/bin/env"
    fi
    
    # Verify UV is now available
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}UV installed but not immediately available in PATH.${NC}"
        echo -e "${YELLOW}Trying direct path...${NC}"
        # Create an alias for this session
        alias uv="$HOME/.local/bin/uv"
        # Also update PATH more explicitly
        if [ -d "$HOME/.cargo/bin" ]; then
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
    fi
    
    # Final check with full path
    if [ -x "$HOME/.local/bin/uv" ] || [ -x "$HOME/.cargo/bin/uv" ]; then
        echo -e "${GREEN}✓ UV installed successfully${NC}"
        UV_BIN=$(which uv 2>/dev/null || echo "$HOME/.local/bin/uv")
        echo -e "${CYAN}UV location: $UV_BIN${NC}"
    else
        echo -e "${RED}UV installation failed. Please run: source ~/.bashrc and re-run this script${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ UV already installed${NC}"
fi

# Install Node.js 22 LTS if not present
if ! command -v node &> /dev/null; then
    echo -e "${CYAN}Installing Node.js 22 LTS...${NC}"
    if [ "$OS_TYPE" = "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "$OS_TYPE" = "macos" ]; then
        brew install node@22
    fi
else
    echo -e "${GREEN}✓ Node.js already installed: $(node --version)${NC}"
fi

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${CYAN}Installing Claude Code...${NC}"
    npm install -g @anthropic-ai/claude-code
else
    echo -e "${GREEN}✓ Claude Code already installed${NC}"
fi

# Install OpenAI Codex
if ! command -v codex &> /dev/null; then
    echo -e "${CYAN}Installing OpenAI Codex...${NC}"
    npm install -g @openai/codex
else
    echo -e "${GREEN}✓ OpenAI Codex already installed${NC}"
fi

# Install Google Gemini CLI
if ! command -v gemini &> /dev/null; then
    echo -e "${CYAN}Installing Google Gemini CLI...${NC}"
    npm install -g @google/gemini-cli
else
    echo -e "${GREEN}✓ Google Gemini CLI already installed${NC}"
fi

# Install pnpm
if ! command -v pnpm &> /dev/null; then
    echo -e "${CYAN}Installing pnpm...${NC}"
    npm install -g pnpm
else
    echo -e "${GREEN}✓ pnpm already installed${NC}"
fi

# Install PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${CYAN}Installing PM2...${NC}"
    npm install -g pm2
else
    echo -e "${GREEN}✓ PM2 already installed${NC}"
fi

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${CYAN}Installing GitHub CLI...${NC}"
    if [ "$OS_TYPE" = "debian" ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh
    elif [ "$OS_TYPE" = "macos" ]; then
        brew install gh
    fi
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

# Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${CYAN}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}⚠️  You'll need to log out and back in for Docker permissions${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

echo ""
echo -e "${CYAN}=== Core Infrastructure Setup ===${NC}"
echo -e "${CYAN}Starting core infrastructure containers (PostgreSQL, Redis)...${NC}"

# Function to check infrastructure health
check_infrastructure_health() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${CYAN}⏳ Waiting for infrastructure to be healthy...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        local all_healthy=true
        
        # Check PostgreSQL containers
        if ! docker exec am-agents-labs-postgres pg_isready -U postgres -d automagik_agents -p 5401 >/dev/null 2>&1; then
            all_healthy=false
        fi
        
        if ! docker exec automagik-spark-postgres pg_isready -U postgres -d automagik_spark -p 5402 >/dev/null 2>&1; then
            all_healthy=false
        fi
        
        # Check Redis container
        if ! docker exec automagik-spark-redis redis-cli -p 5412 ping >/dev/null 2>&1; then
            all_healthy=false
        fi
        
        if [ "$all_healthy" = true ]; then
            echo -e "${GREEN}✓ All infrastructure containers are healthy!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Infrastructure failed to become healthy after $max_attempts attempts${NC}"
    return 1
}

# Start infrastructure containers
if [ -f "$SCRIPT_DIR/docker-infrastructure.yml" ]; then
    echo -e "${CYAN}Starting core infrastructure...${NC}"
    $DOCKER_COMPOSE_CMD -f "$SCRIPT_DIR/docker-infrastructure.yml" -p automagik up -d
    
    # Wait for infrastructure health
    if check_infrastructure_health; then
        echo -e "${GREEN}✓ Core infrastructure ready${NC}"
    else
        echo -e "${RED}❌ Failed to start core infrastructure. Services may not work properly.${NC}"
        echo -e "${YELLOW}⚠️  Continuing with installation...${NC}"
    fi
else
    echo -e "${RED}❌ docker-infrastructure.yml not found${NC}"
    echo -e "${YELLOW}⚠️  Core infrastructure setup skipped${NC}"
fi

echo ""
echo -e "${YELLOW}=== Optional Services Configuration ===${NC}"

# Arrays to track parallel installations
declare -a PARALLEL_PIDS=()
declare -a PARALLEL_NAMES=()
declare -a PARALLEL_MESSAGES=()

# Function to install LangFlow in background
install_langflow() {
    {
        if [ -f "$SCRIPT_DIR/docker-langflow.yml" ]; then
            $DOCKER_COMPOSE_CMD -f "$SCRIPT_DIR/docker-langflow.yml" -p langflow up -d >/dev/null 2>&1
        else
            exit 1
        fi
    } &
    local pid=$!
    PARALLEL_PIDS+=($pid)
    PARALLEL_NAMES+=("LangFlow")
    PARALLEL_MESSAGES+=("Access at: http://localhost:7860 | Username: admin | Password: automagik123")
}

# Function to install Evolution API in background
install_evolution() {
    {
        if [ -f "$SCRIPT_DIR/docker-evolution.yml" ]; then
            $DOCKER_COMPOSE_CMD -f "$SCRIPT_DIR/docker-evolution.yml" -p evolution_api up -d >/dev/null 2>&1
        else
            exit 1
        fi
    } &
    local pid=$!
    PARALLEL_PIDS+=($pid)
    PARALLEL_NAMES+=("Evolution API")
    PARALLEL_MESSAGES+=("Access at: http://localhost:8080 | API Key: namastex888")
}

# Function to install browser tools (foreground due to sudo requirement)
install_browser_tools_foreground() {
    if [ "$OS_TYPE" = "debian" ]; then
        echo -e "${CYAN}Installing browser automation dependencies...${NC}"
        sudo apt-get install -y \
            libnss3 \
            libatk-bridge2.0-0 \
            libdrm2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxdamage1 \
            libxrandr2 \
            libgbm1 \
            libasound2t64 >/dev/null 2>&1 || \
        sudo apt-get install -y \
            libnss3 \
            libatk-bridge2.0-0 \
            libdrm2 \
            libxkbcommon0 \
            libxcomposite1 \
            libxdamage1 \
            libxrandr2 \
            libgbm1 \
            libasound2 >/dev/null 2>&1
        echo -e "${GREEN}✓ Browser tools installed successfully!${NC}"
        echo -e "${CYAN}   Browser automation dependencies installed${NC}"
    elif [ "$OS_TYPE" = "macos" ]; then
        echo -e "${GREEN}✓ Browser tools configured successfully!${NC}"
        echo -e "${CYAN}   Browser automation dependencies included with macOS${NC}"
    fi
}

# LangFlow option
echo ""
echo -e "${CYAN}🌊 LangFlow is a visual flow builder for creating AI workflows${NC}"
echo -e "${CYAN}   • Visual interface for building AI pipelines${NC}"
echo -e "${CYAN}   • Available at: http://localhost:7860${NC}"
read -p "Install LangFlow service? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✓ Starting LangFlow installation in background...${NC}"
    install_langflow
else
    echo -e "${YELLOW}⚠️  Skipping LangFlow installation${NC}"
fi

# Evolution API option
echo ""
echo -e "${CYAN}📱 Evolution API provides WhatsApp integration capabilities${NC}"
echo -e "${CYAN}   • WhatsApp bot integration${NC}"
echo -e "${CYAN}   • Available at: http://localhost:8080${NC}"
read -p "Install Evolution API service? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✓ Starting Evolution API installation in background...${NC}"
    install_evolution
else
    echo -e "${YELLOW}⚠️  Skipping Evolution API installation${NC}"
fi

# Browser tools option
echo ""
echo -e "${CYAN}🌐 Optional: Browser Tools (for Agent web automation)${NC}"
echo -e "${CYAN}   • Playwright/Puppeteer browser automation${NC}"
echo -e "${CYAN}   • Required for web scraping & browser control${NC}"
read -p "Install browser tools? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_browser_tools_foreground
else
    echo -e "${YELLOW}⚠️  Skipping browser tools installation${NC}"
fi

# Don't wait for optional services - they can finish in background
if [ ${#PARALLEL_PIDS[@]} -gt 0 ]; then
    echo ""
    echo -e "${CYAN}Optional services are installing in background...${NC}"
    echo -e "${YELLOW}💡 Check their status later with: make status${NC}"
    echo ""
fi

echo ""
echo -e "${GREEN}✅ Pre-dependencies installed successfully!${NC}"

# Final verification of UV before proceeding
echo -e "${CYAN}Verifying UV is available...${NC}"
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓ UV is available at: $(which uv)${NC}"
elif [ -x "$HOME/.local/bin/uv" ]; then
    echo -e "${GREEN}✓ UV found at: $HOME/.local/bin/uv${NC}"
    export PATH="$HOME/.local/bin:$PATH"
else
    echo -e "${RED}⚠️  UV not found in PATH. Adding to PATH and updating shell config...${NC}"
    export PATH="$HOME/.local/bin:$PATH"
    
    # Add to bashrc if not already there
    if ! grep -q "/.local/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo -e "${YELLOW}Added UV to ~/.bashrc. You may need to run: source ~/.bashrc${NC}"
    fi
fi

echo ""
echo -e "${PURPLE}Running main installation...${NC}"
echo ""

# Export UV path for make install to use
export UV_BIN="${UV_BIN:-$(which uv 2>/dev/null || echo $HOME/.local/bin/uv)}"

# Call the main Makefile for core services installation
make install