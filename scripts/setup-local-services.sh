#!/bin/bash
# ===========================================
# 🚀 Automagik Local Services Setup
# ===========================================
# This script sets up all services to run without sudo
# using user-space alternatives like PM2, screen, or nohup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK="✅"
WARNING="⚠️"
ERROR="❌"
ROCKET="🚀"
INFO="ℹ️"

# Base directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$PROJECT_ROOT"

# Service directories
AM_AGENTS_DIR="$SERVICES_DIR/am-agents-labs"
SPARK_DIR="$SERVICES_DIR/automagik-spark"
TOOLS_DIR="$SERVICES_DIR/automagik-tools"
OMNI_DIR="$SERVICES_DIR/automagik-omni"
UI_DIR="$SERVICES_DIR/automagik-ui"

# Runtime directory for non-sudo services
RUNTIME_DIR="$HOME/.local/share/automagik"
LOG_DIR="$RUNTIME_DIR/logs"
PID_DIR="$RUNTIME_DIR/pids"

# Create runtime directories
mkdir -p "$RUNTIME_DIR" "$LOG_DIR" "$PID_DIR"

# Function to print colored messages
print_status() {
    echo -e "${PURPLE}${ROCKET} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

# Check if PM2 is installed
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_warning "PM2 not found. Installing PM2 globally..."
        npm install -g pm2
    fi
}

# Check if screen is installed
check_screen() {
    if ! command -v screen &> /dev/null; then
        print_warning "Screen not found. Please install screen: apt-get install screen"
        return 1
    fi
    return 0
}

# Function to create PM2 ecosystem file
create_pm2_ecosystem() {
    cat > "$RUNTIME_DIR/ecosystem.config.js" << 'EOF'
module.exports = {
  apps: [
    {
      name: 'automagik-ui',
      cwd: '${UI_DIR}',
      script: 'pnpm',
      args: 'start',
      env: {
        NODE_ENV: 'production',
        PORT: 8888
      },
      error_file: '${LOG_DIR}/ui-error.log',
      out_file: '${LOG_DIR}/ui-out.log',
      merge_logs: true,
      time: true
    },
    {
      name: 'am-agents-labs',
      cwd: '${AM_AGENTS_DIR}',
      script: '.venv/bin/python',
      args: '-m src',
      env: {
        PYTHONPATH: '${AM_AGENTS_DIR}',
        AM_PORT: '8881'
      },
      error_file: '${LOG_DIR}/agents-error.log',
      out_file: '${LOG_DIR}/agents-out.log',
      merge_logs: true,
      time: true
    },
    {
      name: 'automagik-spark',
      cwd: '${SPARK_DIR}',
      script: '.venv/bin/python',
      args: '-m src',
      env: {
        PYTHONPATH: '${SPARK_DIR}',
        SPARK_API_PORT: '8883'
      },
      error_file: '${LOG_DIR}/spark-error.log',
      out_file: '${LOG_DIR}/spark-out.log',
      merge_logs: true,
      time: true
    },
    {
      name: 'automagik-omni',
      cwd: '${OMNI_DIR}',
      script: '.venv/bin/uvicorn',
      args: 'src.api.app:app --host 0.0.0.0 --port 8882',
      env: {
        PYTHONPATH: '${OMNI_DIR}',
        OMNI_API_PORT: '8882'
      },
      error_file: '${LOG_DIR}/omni-error.log',
      out_file: '${LOG_DIR}/omni-out.log',
      merge_logs: true,
      time: true
    },
    {
      name: 'automagik-tools',
      cwd: '${TOOLS_DIR}',
      script: '.venv/bin/automagik-tools',
      args: 'serve-all --host 0.0.0.0 --port 8884',
      env: {
        PYTHONPATH: '${TOOLS_DIR}'
      },
      error_file: '${LOG_DIR}/tools-error.log',
      out_file: '${LOG_DIR}/tools-out.log',
      merge_logs: true,
      time: true
    }
  ]
};
EOF

    # Replace variables in the ecosystem file
    sed -i "s|\${UI_DIR}|$UI_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
    sed -i "s|\${AM_AGENTS_DIR}|$AM_AGENTS_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
    sed -i "s|\${SPARK_DIR}|$SPARK_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
    sed -i "s|\${OMNI_DIR}|$OMNI_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
    sed -i "s|\${TOOLS_DIR}|$TOOLS_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
    sed -i "s|\${LOG_DIR}|$LOG_DIR|g" "$RUNTIME_DIR/ecosystem.config.js"
}

# Function to start service with nohup
start_with_nohup() {
    local name=$1
    local dir=$2
    local cmd=$3
    local pidfile="$PID_DIR/$name.pid"
    local logfile="$LOG_DIR/$name.log"
    
    if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile") 2>/dev/null; then
        print_warning "$name is already running (PID: $(cat $pidfile))"
        return
    fi
    
    print_status "Starting $name with nohup..."
    cd "$dir"
    nohup $cmd > "$logfile" 2>&1 &
    echo $! > "$pidfile"
    print_success "$name started (PID: $!)"
}

# Function to stop service with nohup
stop_with_nohup() {
    local name=$1
    local pidfile="$PID_DIR/$name.pid"
    
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping $name (PID: $pid)..."
            kill "$pid"
            rm -f "$pidfile"
            print_success "$name stopped"
        else
            print_warning "$name not running (stale PID file)"
            rm -f "$pidfile"
        fi
    else
        print_warning "$name is not running"
    fi
}

# Function to start service with screen
start_with_screen() {
    local name=$1
    local dir=$2
    local cmd=$3
    
    if screen -list | grep -q "$name"; then
        print_warning "$name screen session already exists"
        return
    fi
    
    print_status "Starting $name in screen session..."
    cd "$dir"
    screen -dmS "$name" bash -c "$cmd"
    print_success "$name started in screen session"
}

# Function to stop service with screen
stop_with_screen() {
    local name=$1
    
    if screen -list | grep -q "$name"; then
        print_status "Stopping $name screen session..."
        screen -X -S "$name" quit
        print_success "$name screen session stopped"
    else
        print_warning "$name screen session not found"
    fi
}

# Setup UI service (already uses PM2)
setup_ui_service() {
    print_status "Setting up UI service..."
    cd "$UI_DIR"
    
    # Copy .env.local.example to .env.local if it doesn't exist
    if [ ! -f ".env.local" ] && [ -f ".env.local.example" ]; then
        cp .env.local.example .env.local
        print_info "Created .env.local from .env.local.example"
    fi
    
    # The UI already has PM2 commands, just use them
    print_info "UI service uses PM2 (already configured in Makefile)"
}

# Main menu
show_menu() {
    echo ""
    echo "==================================="
    echo "🚀 Automagik Local Services Manager"
    echo "==================================="
    echo "1. Setup PM2 for all services"
    echo "2. Setup nohup for all services"
    echo "3. Setup screen for all services"
    echo "4. Start all services (PM2)"
    echo "5. Stop all services (PM2)"
    echo "6. Show service status"
    echo "7. Show logs location"
    echo "8. Exit"
    echo ""
}

# Setup PM2 for all services
setup_pm2_all() {
    print_status "Setting up PM2 for all services..."
    check_pm2
    create_pm2_ecosystem
    print_success "PM2 ecosystem file created at: $RUNTIME_DIR/ecosystem.config.js"
    print_info "Start all services with: pm2 start $RUNTIME_DIR/ecosystem.config.js"
    print_info "Save PM2 config with: pm2 save"
    print_info "Setup auto-start with: pm2 startup"
}

# Start all services with PM2
start_all_pm2() {
    print_status "Starting all services with PM2..."
    pm2 start "$RUNTIME_DIR/ecosystem.config.js"
    pm2 save
}

# Stop all services with PM2
stop_all_pm2() {
    print_status "Stopping all services with PM2..."
    pm2 stop all
    pm2 delete all
}

# Show status
show_status() {
    print_status "Service Status:"
    echo ""
    
    # Check PM2 services
    if command -v pm2 &> /dev/null; then
        echo "PM2 Services:"
        pm2 list
    fi
    
    echo ""
    echo "Nohup Services:"
    for service in am-agents-labs automagik-spark automagik-omni automagik-tools; do
        pidfile="$PID_DIR/$service.pid"
        if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile") 2>/dev/null; then
            echo "  $service: Running (PID: $(cat $pidfile))"
        else
            echo "  $service: Stopped"
        fi
    done
    
    echo ""
    echo "Screen Sessions:"
    screen -list 2>/dev/null | grep -E "(am-agents-labs|automagik-spark|automagik-omni|automagik-tools|automagik-ui)" || echo "  No screen sessions found"
}

# Show logs location
show_logs() {
    print_status "Log Locations:"
    echo ""
    echo "PM2 logs: pm2 logs"
    echo "Nohup logs: $LOG_DIR/"
    echo "Screen logs: Use 'screen -r <service-name>' to attach to session"
    echo ""
    echo "Log files:"
    ls -la "$LOG_DIR" 2>/dev/null || echo "No log files yet"
}

# Interactive menu
while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
        1) setup_pm2_all ;;
        2) print_info "Use start/stop commands for individual nohup services" ;;
        3) print_info "Use start/stop commands for individual screen services" ;;
        4) start_all_pm2 ;;
        5) stop_all_pm2 ;;
        6) show_status ;;
        7) show_logs ;;
        8) exit 0 ;;
        *) print_error "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done