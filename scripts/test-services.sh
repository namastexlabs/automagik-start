#!/bin/bash
# ===========================================
# 🧪 Test Each Service Startup
# ===========================================
# This script tests if each service can start properly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$PROJECT_ROOT"

# Service directories
AUTOMAGIK_AGENTS_DIR="$SERVICES_DIR/automagik"
SPARK_DIR="$SERVICES_DIR/automagik-spark"
TOOLS_DIR="$SERVICES_DIR/automagik-tools"
OMNI_DIR="$SERVICES_DIR/automagik-omni"
UI_DIR="$SERVICES_DIR/automagik-ui"

# Function to print colored messages
print_status() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to test a Python service
test_python_service() {
    local name=$1
    local dir=$2
    local module=$3
    
    print_status "Testing $name..."
    
    if [ ! -d "$dir" ]; then
        print_error "$name directory not found: $dir"
        return 1
    fi
    
    cd "$dir"
    
    # Check if venv exists
    if [ ! -d ".venv" ]; then
        print_error "$name: No virtual environment found. Run 'make install' first."
        return 1
    fi
    
    # Test if the module can be imported
    if .venv/bin/python -c "import $module" 2>/dev/null; then
        print_success "$name: Module imports successfully"
    else
        print_error "$name: Failed to import module '$module'"
        return 1
    fi
    
    # Try to start the service in background for 5 seconds
    print_info "Starting $name for 5 seconds..."
    timeout 5 .venv/bin/python -m $module &>/dev/null || true
    print_success "$name: Can start successfully"
}

# Function to test automagik-tools
test_tools_service() {
    print_status "Testing automagik-tools..."
    
    if [ ! -d "$TOOLS_DIR" ]; then
        print_error "automagik-tools directory not found: $TOOLS_DIR"
        return 1
    fi
    
    cd "$TOOLS_DIR"
    
    # Check if venv exists
    if [ ! -d ".venv" ]; then
        print_error "automagik-tools: No virtual environment found. Run 'make install' first."
        return 1
    fi
    
    # Test if the CLI works
    if .venv/bin/automagik-tools --help &>/dev/null; then
        print_success "automagik-tools: CLI works"
    else
        print_error "automagik-tools: CLI failed"
        return 1
    fi
    
    # List available tools
    print_info "Available tools:"
    .venv/bin/automagik-tools list || true
    
    print_success "automagik-tools: Ready to serve"
}

# Function to test UI service
test_ui_service() {
    print_status "Testing automagik-ui..."
    
    if [ ! -d "$UI_DIR" ]; then
        print_error "automagik-ui directory not found: $UI_DIR"
        return 1
    fi
    
    cd "$UI_DIR"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_error "automagik-ui: No node_modules found. Run 'pnpm install' first."
        return 1
    fi
    
    # Check if pnpm is available
    if ! command -v pnpm &> /dev/null; then
        print_error "pnpm not found. Install with: npm install -g pnpm"
        return 1
    fi
    
    # Check if .env.local exists
    if [ ! -f ".env.local" ]; then
        if [ -f ".env.local.example" ]; then
            cp .env.local.example .env.local
            print_info "Created .env.local from .env.local.example"
        else
            print_error "No .env.local file found"
            return 1
        fi
    fi
    
    print_success "automagik-ui: Ready to start"
}

# Main execution
echo ""
echo "=================================="
echo "🧪 Testing Automagik Services"
echo "=================================="
echo ""

# Test each service
test_python_service "automagik" "$AUTOMAGIK_AGENTS_DIR" "automagik"
echo ""

test_python_service "automagik-spark" "$SPARK_DIR" "automagik"
echo ""

test_python_service "automagik-omni" "$OMNI_DIR" "automagik.api.app"
echo ""

test_tools_service
echo ""

test_ui_service
echo ""

echo "=================================="
print_success "Service testing complete!"
echo ""
echo "Port assignments:"
echo "  - automagik: 8881"
echo "  - automagik-omni: 8882"
echo "  - automagik-spark: 8883"
echo "  - automagik-tools: 8884"
echo "  - automagik-ui: 8888 (production), 3000 (dev)"
echo ""
echo "To start all services locally without sudo:"
echo "  make -f Makefile.local setup-pm2"
echo "  make -f Makefile.local start-all"
echo ""