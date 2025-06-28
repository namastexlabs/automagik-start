#!/bin/bash

# ===================================================================
# 🔌 Port Conflict Detection and Resolution
# ===================================================================

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Required ports for Automagik Suite
declare -A REQUIRED_PORTS=(
    # Core Automagik Services
    ["8888"]="automagik-ui (Main Interface)"
    ["8881"]="am-agents-labs (Main Orchestrator)"
    ["8882"]="automagik-omni (Multi-tenant Hub)"
    ["8883"]="automagik-spark (Workflow Engine)"
    ["8884"]="automagik-tools-sse (MCP Tools SSE)"
    ["8885"]="automagik-tools-http (MCP Tools HTTP)"
    ["8080"]="evolution-api (WhatsApp API)"
    
    # Infrastructure Services  
    ["5401"]="am-agents-labs-postgres"
    ["5402"]="automagik-spark-postgres"
    ["5403"]="evolution-postgres"
    ["5412"]="automagik-spark-redis"
    ["5413"]="evolution-redis"
    ["5431"]="evolution-rabbitmq"
    
    # Optional Services
    ["7860"]="langflow (Visual Flow Builder)"
)

# Check if a specific port is in use
check_port() {
    local port="$1"
    
    if command -v lsof >/dev/null 2>&1; then
        lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep -q ":$port "
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep -q ":$port "
    else
        log_warning "No port checking tool available (lsof, netstat, ss)"
        return 1
    fi
}

# Get process information for a port
get_port_process() {
    local port="$1"
    
    if command -v lsof >/dev/null 2>&1; then
        local pid=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null | head -1)
        if [ -n "$pid" ]; then
            local process_name=$(ps -p $pid -o comm= 2>/dev/null)
            local process_cmd=$(ps -p $pid -o args= 2>/dev/null)
            echo "PID: $pid, Name: $process_name, Command: $process_cmd"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | head -1
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep ":$port " | sed 's/.*pid=\([0-9]*\).*/\1/' | head -1
    fi
}

# Get PID for a port
get_port_pid() {
    local port="$1"
    
    if command -v lsof >/dev/null 2>&1; then
        lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null | head -1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep ":$port " | sed 's/.*pid=\([0-9]*\).*/\1/' | head -1
    fi
}

# Kill process on port
kill_port_process() {
    local port="$1"
    local force="${2:-false}"
    
    local pid=$(get_port_pid "$port")
    
    if [ -n "$pid" ] && [ "$pid" != "-" ]; then
        log_info "Attempting to stop process $pid on port $port"
        
        if [ "$force" = "true" ]; then
            if kill -9 "$pid" 2>/dev/null; then
                log_success "Force killed process $pid on port $port"
                return 0
            else
                log_error "Failed to force kill process $pid on port $port"
                return 1
            fi
        else
            if kill -TERM "$pid" 2>/dev/null; then
                sleep 2
                if ! kill -0 "$pid" 2>/dev/null; then
                    log_success "Gracefully stopped process $pid on port $port"
                    return 0
                else
                    log_warning "Process $pid still running, trying force kill"
                    kill -9 "$pid" 2>/dev/null
                    sleep 1
                    if ! kill -0 "$pid" 2>/dev/null; then
                        log_success "Force killed process $pid on port $port"
                        return 0
                    fi
                fi
            fi
        fi
        
        log_error "Failed to kill process $pid on port $port"
        return 1
    else
        log_warning "No process found on port $port"
        return 1
    fi
}

# Check all required ports
check_all_ports() {
    log_section "Port Availability Check"
    
    local conflicts=()
    local available_count=0
    local total_count=${#REQUIRED_PORTS[@]}
    
    for port in "${!REQUIRED_PORTS[@]}"; do
        local service="${REQUIRED_PORTS[$port]}"
        
        if check_port "$port"; then
            local process_info=$(get_port_process "$port")
            print_table_row "$service" "❌ IN USE" "$port" "-"
            log_warning "Port $port is in use: $process_info"
            conflicts+=("$port")
        else
            print_table_row "$service" "✅ Available" "$port" "-"
            ((available_count++))
        fi
    done
    
    echo ""
    log_info "Port check complete: $available_count/$total_count ports available"
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        handle_port_conflicts "${conflicts[@]}"
        return $?
    else
        log_success "All required ports are available!"
        return 0
    fi
}

# Handle port conflicts
handle_port_conflicts() {
    local conflicts=("$@")
    
    log_section "Port Conflict Resolution"
    
    print_error "Port conflicts detected on ports: ${conflicts[*]}"
    echo ""
    
    # Show detailed conflict information
    for port in "${conflicts[@]}"; do
        local service="${REQUIRED_PORTS[$port]}"
        local process_info=$(get_port_process "$port")
        echo -e "${RED}Port $port${NC} (${service}): $process_info"
    done
    
    echo ""
    echo "Resolution options:"
    echo "1) ${GREEN}Kill conflicting processes${NC} (recommended for development)"
    echo "2) ${YELLOW}Skip conflicting services${NC} (partial deployment)"
    echo "3) ${RED}Exit and resolve manually${NC} (recommended for production)"
    echo ""
    
    while true; do
        read -p "Choose option [1-3]: " choice
        
        case $choice in
            1)
                resolve_conflicts_kill "${conflicts[@]}"
                return $?
                ;;
            2)
                resolve_conflicts_skip "${conflicts[@]}"
                return $?
                ;;
            3)
                log_info "Exiting for manual resolution"
                log_info "Please stop the conflicting processes and run the installer again"
                exit 1
                ;;
            *)
                print_warning "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Resolve conflicts by killing processes
resolve_conflicts_kill() {
    local conflicts=("$@")
    
    log_info "Attempting to resolve conflicts by stopping processes..."
    
    local failed_kills=()
    
    for port in "${conflicts[@]}"; do
        local service="${REQUIRED_PORTS[$port]}"
        echo -ne "${YELLOW}Stopping process on port $port...${NC}"
        
        if kill_port_process "$port"; then
            echo -e "\r${GREEN}${CHECKMARK} Stopped process on port $port (${service})${NC}"
        else
            echo -e "\r${RED}${ERROR} Failed to stop process on port $port (${service})${NC}"
            failed_kills+=("$port")
        fi
    done
    
    if [ ${#failed_kills[@]} -gt 0 ]; then
        log_error "Failed to stop processes on ports: ${failed_kills[*]}"
        log_info "You may need to stop these manually or run with sudo"
        return 1
    else
        log_success "All conflicting processes stopped successfully!"
        
        # Verify ports are now free
        sleep 2
        local still_conflicted=()
        for port in "${conflicts[@]}"; do
            if check_port "$port"; then
                still_conflicted+=("$port")
            fi
        done
        
        if [ ${#still_conflicted[@]} -gt 0 ]; then
            log_warning "Some ports are still in use: ${still_conflicted[*]}"
            return 1
        else
            log_success "All ports are now available!"
            return 0
        fi
    fi
}

# Resolve conflicts by skipping services
resolve_conflicts_skip() {
    local conflicts=("$@")
    
    log_warning "Skipping services with port conflicts..."
    
    # Export conflicted ports for deployment script to handle
    export CONFLICTED_PORTS="${conflicts[*]}"
    
    for port in "${conflicts[@]}"; do
        local service="${REQUIRED_PORTS[$port]}"
        log_warning "Will skip: $service (port $port)"
    done
    
    log_info "Proceeding with partial deployment"
    return 0
}

# Wait for port to become available
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local interval="${3:-2}"
    
    log_info "Waiting for port $port to become available (timeout: ${timeout}s)"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if ! check_port "$port"; then
            log_success "Port $port is now available"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -ne "\r${YELLOW}Waiting for port $port... ${elapsed}s${NC}"
    done
    
    echo ""
    log_error "Timeout waiting for port $port to become available"
    return 1
}

# Check if port is responding to HTTP
check_http_port() {
    local host="${1:-localhost}"
    local port="$2"
    local path="${3:-/}"
    local timeout="${4:-5}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s --connect-timeout "$timeout" "http://$host:$port$path" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout="$timeout" --tries=1 "http://$host:$port$path" -O /dev/null 2>&1
    else
        # Fallback: try to connect with nc or telnet
        if command -v nc >/dev/null 2>&1; then
            echo "" | timeout "$timeout" nc "$host" "$port" >/dev/null 2>&1
        elif command -v telnet >/dev/null 2>&1; then
            echo "" | timeout "$timeout" telnet "$host" "$port" >/dev/null 2>&1
        else
            log_warning "No HTTP checking tool available (curl, wget, nc, telnet)"
            return 1
        fi
    fi
}

# Wait for HTTP service to be ready
wait_for_http() {
    local host="${1:-localhost}"
    local port="$2"
    local path="${3:-/}"
    local timeout="${4:-60}"
    local interval="${5:-2}"
    
    log_info "Waiting for HTTP service at $host:$port$path (timeout: ${timeout}s)"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if check_http_port "$host" "$port" "$path" 2; then
            log_success "HTTP service at $host:$port$path is responding"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -ne "\r${YELLOW}Waiting for HTTP service... ${elapsed}s${NC}"
    done
    
    echo ""
    log_error "Timeout waiting for HTTP service at $host:$port$path"
    return 1
}

# Main function when script is run directly
main() {
    case "${1:-check}" in
        "check")
            check_all_ports
            ;;
        "kill")
            if [ -z "$2" ]; then
                log_error "Usage: $0 kill <port>"
                exit 1
            fi
            kill_port_process "$2"
            ;;
        "wait")
            if [ -z "$2" ]; then
                log_error "Usage: $0 wait <port> [timeout]"
                exit 1
            fi
            wait_for_port "$2" "${3:-30}"
            ;;
        "http")
            if [ -z "$2" ]; then
                log_error "Usage: $0 http <port> [host] [path] [timeout]"
                exit 1
            fi
            wait_for_http "${3:-localhost}" "$2" "${4:-/}" "${5:-60}"
            ;;
        *)
            echo "Usage: $0 {check|kill|wait|http}"
            echo "  check           - Check all required ports"
            echo "  kill <port>     - Kill process on specific port"
            echo "  wait <port>     - Wait for port to become available"
            echo "  http <port>     - Wait for HTTP service on port"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi