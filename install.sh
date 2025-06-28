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
    export PATH="$HOME/.local/bin:$PATH"
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

# Install Docker
if ! command -v docker &> /dev/null; then
    echo -e "${CYAN}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}⚠️  You'll need to log out and back in for Docker permissions${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Check if we're running interactively
if [[ -t 0 ]] && [[ -t 1 ]]; then
    INTERACTIVE_MODE=true
    echo ""
    echo -e "${YELLOW}=== Optional Services Configuration ===${NC}"
else
    INTERACTIVE_MODE=false
    echo ""
    echo -e "${YELLOW}Non-interactive mode detected - using defaults for optional services${NC}"
fi

# Langflow option
if [ "$INTERACTIVE_MODE" = true ]; then
    echo ""
    echo -e "${CYAN}🌊 LangFlow is a visual flow builder for creating AI workflows${NC}"
    echo -e "${CYAN}   • Visual interface for building AI pipelines${NC}"
    echo -e "${CYAN}   • Available at: http://localhost:7860${NC}"
    read -p "Install LangFlow service? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Installing LangFlow...${NC}"
        if [ -f "$SCRIPT_DIR/docker-langflow.yml" ]; then
            docker compose -f "$SCRIPT_DIR/docker-langflow.yml" -p langflow up -d
            echo -e "${GREEN}✓ LangFlow installed successfully!${NC}"
            echo -e "${CYAN}   Access at: http://localhost:7860${NC}"
            echo -e "${CYAN}   Username: admin${NC}"
            echo -e "${CYAN}   Password: automagik123${NC}"
        else
            echo -e "${RED}❌ docker-langflow.yml not found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping LangFlow installation${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping LangFlow (non-interactive mode)${NC}"
fi

# Evolution API option
if [ "$INTERACTIVE_MODE" = true ]; then
    echo ""
    echo -e "${CYAN}📱 Evolution API provides WhatsApp integration capabilities${NC}"
    echo -e "${CYAN}   • WhatsApp bot integration${NC}"
    echo -e "${CYAN}   • Available at: http://localhost:9000${NC}"
    read -p "Install Evolution API service? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Installing Evolution API...${NC}"
        if [ -f "$SCRIPT_DIR/docker-evolution.yml" ]; then
            docker compose -f "$SCRIPT_DIR/docker-evolution.yml" -p evolution_api up -d
            echo -e "${GREEN}✓ Evolution API installed successfully!${NC}"
            echo -e "${CYAN}   Access at: http://localhost:9000${NC}"
            echo -e "${CYAN}   API Key: namastex888${NC}"
        else
            echo -e "${RED}❌ docker-evolution.yml not found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping Evolution API installation${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Evolution API (non-interactive mode)${NC}"
fi

# Optional browser tools
if [ "$INTERACTIVE_MODE" = true ]; then
    echo ""
    echo -e "${CYAN}🌐 Optional: Browser Tools (for Agent web automation)${NC}"
    echo -e "${CYAN}   • Playwright/Puppeteer browser automation${NC}"
    echo -e "${CYAN}   • Required for web scraping & browser control${NC}"
    read -p "Install browser tools? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Browser tools will be installed${NC}"
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
                libasound2t64 2>/dev/null || \
            sudo apt-get install -y \
                libnss3 \
                libatk-bridge2.0-0 \
                libdrm2 \
                libxkbcommon0 \
                libxcomposite1 \
                libxdamage1 \
                libxrandr2 \
                libgbm1 \
                libasound2
        elif [ "$OS_TYPE" = "macos" ]; then
            echo -e "${YELLOW}Browser tools are included with browser installations on macOS${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping browser tools installation${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping browser tools (non-interactive mode)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Pre-dependencies installed successfully!${NC}"
echo -e "${PURPLE}Running main installation...${NC}"
echo ""

# Call the main Makefile for core services installation
make install

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
if ! groups $USER | grep -q docker; then
    echo -e "  1. Log out and back in for Docker permissions"
    echo -e "  2. Run: ${CYAN}make start${NC}"
else
    echo -e "  1. Run: ${CYAN}make start${NC}"
fi
echo -e "  2. Access UI at ${CYAN}http://localhost:8888${NC}"
echo ""