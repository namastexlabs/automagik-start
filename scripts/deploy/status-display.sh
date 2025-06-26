#!/bin/bash

# ===================================================================
# 📊 Automagik Suite Status Dashboard
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/port-check.sh"

# Configuration
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_COMPOSE_FILE="$BASE_DIR/docker-compose.yml"
REFRESH_INTERVAL=5

# Service definitions
declare -A SERVICE_INFO=(
    ["am-agents-labs"]="Main Orchestrator|http://localhost:8881|8881"
    ["automagik-spark"]="Workflow Engine|http://localhost:8883|8883"
    ["automagik-tools"]="MCP Tools|http://localhost:8885|8885"
    ["automagik-evolution"]="WhatsApp API|http://localhost:9000|9000"
    ["automagik-omni"]="Multi-tenant Hub|http://localhost:8882|8882"
    ["automagik-ui-v2"]="Main Interface|http://localhost:8888|8888"
)

declare -A OPTIONAL_SERVICE_INFO=(
    ["langflow"]="Visual Flow Builder|http://localhost:7860|7860"
)

declare -A INFRASTRUCTURE_INFO=(
    ["am-agents-labs-postgres"]="PostgreSQL|5401"
    ["automagik-spark-postgres"]="PostgreSQL|5402"
    ["evolution-postgres"]="PostgreSQL|5403"
    ["automagik-spark-redis"]="Redis|5412"
    ["evolution-redis"]="Redis|5413"
    ["evolution-rabbitmq"]="RabbitMQ|5431"
)

# Get service status
get_service_status() {
    local service="$1"
    
    if command -v docker >/dev/null 2>&1; then
        local container_id=$(docker-compose -f "$DOCKER_COMPOSE_FILE" ps -q "$service" 2>/dev/null)
        
        if [ -n "$container_id" ]; then
            local status=$(docker inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null)
            local health=$(docker inspect --format '{{.State.Health.Status}}' "$container_id" 2>/dev/null)
            
            case "$status" in
                "running")
                    if [ "$health" = "healthy" ] || [ "$health" = "<no value>" ]; then
                        echo "✅ Running"
                    elif [ "$health" = "unhealthy" ]; then
                        echo "❌ Unhealthy"
                    elif [ "$health" = "starting" ]; then
                        echo "🔄 Starting"
                    else
                        echo "⚠️  Running"
                    fi
                    ;;
                "exited")
                    echo "🔴 Stopped"
                    ;;
                "paused")
                    echo "⏸️  Paused"
                    ;;
                "restarting")
                    echo "🔄 Restarting"
                    ;;
                *)
                    echo "❓ Unknown"
                    ;;
            esac
        else
            echo "⭕ Not Found"
        fi
    else
        echo "❌ Docker N/A"
    fi
}

# Get service uptime
get_service_uptime() {
    local service="$1"
    
    if command -v docker >/dev/null 2>&1; then
        local container_id=$(docker-compose -f "$DOCKER_COMPOSE_FILE" ps -q "$service" 2>/dev/null)
        
        if [ -n "$container_id" ]; then
            local started=$(docker inspect --format '{{.State.StartedAt}}' "$container_id" 2>/dev/null)
            if [ -n "$started" ] && [ "$started" != "0001-01-01T00:00:00Z" ]; then
                local uptime=$(docker inspect --format '{{.State.StartedAt}}' "$container_id" 2>/dev/null | xargs -I {} date -d {} +%s 2>/dev/null)
                local now=$(date +%s)
                local diff=$((now - uptime))
                
                if [ $diff -gt 0 ]; then
                    if [ $diff -lt 60 ]; then
                        echo "${diff}s"
                    elif [ $diff -lt 3600 ]; then
                        echo "$((diff / 60))m"
                    elif [ $diff -lt 86400 ]; then
                        echo "$((diff / 3600))h"
                    else
                        echo "$((diff / 86400))d"
                    fi
                else
                    echo "-"
                fi
            else
                echo "-"
            fi
        else
            echo "-"
        fi
    else
        echo "-"
    fi
}

# Get service resource usage
get_service_resources() {
    local service="$1"
    
    if command -v docker >/dev/null 2>&1; then
        local container_id=$(docker-compose -f "$DOCKER_COMPOSE_FILE" ps -q "$service" 2>/dev/null)
        
        if [ -n "$container_id" ]; then
            local stats=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" "$container_id" 2>/dev/null)
            if [ -n "$stats" ]; then
                local cpu=$(echo "$stats" | cut -d'|' -f1)
                local mem=$(echo "$stats" | cut -d'|' -f2 | cut -d'/' -f1)
                echo "$cpu|$mem"
            else
                echo "-|-"
            fi
        else
            echo "-|-"
        fi
    else
        echo "-|-"
    fi
}

# Check port availability
check_service_port() {
    local port="$1"
    
    if check_port "$port"; then
        echo "🟢 Open"
    else
        echo "🔴 Closed"
    fi
}

# Check HTTP endpoint
check_service_http() {
    local url="$1"
    
    if [ -n "$url" ]; then
        local host=$(echo "$url" | cut -d':' -f2 | tr -d '/')
        local port=$(echo "$url" | cut -d':' -f3 | cut -d'/' -f1)
        
        if check_http_port "$host" "$port" "/" 2; then
            echo "🟢 OK"
        else
            echo "🔴 Down"
        fi
    else
        echo "-"
    fi
}

# Display header
display_header() {
    clear
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                           🚀 AUTOMAGIK SUITE DASHBOARD                         ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GRAY}Last Updated: $(date)${NC}"
    echo -e "${GRAY}Refresh: ${REFRESH_INTERVAL}s | Press Ctrl+C to exit${NC}"
    echo ""
}

# Display application services
display_application_services() {
    echo -e "${BOLD}${CYAN}┌─ APPLICATION SERVICES ─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│${NC} Service               Status      Uptime  CPU     Memory     Port    HTTP   ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    for service in "${!SERVICE_INFO[@]}"; do
        local info="${SERVICE_INFO[$service]}"
        local description=$(echo "$info" | cut -d'|' -f1)
        local url=$(echo "$info" | cut -d'|' -f2)
        local port=$(echo "$info" | cut -d'|' -f3)
        
        local status=$(get_service_status "$service")
        local uptime=$(get_service_uptime "$service")
        local resources=$(get_service_resources "$service")
        local cpu=$(echo "$resources" | cut -d'|' -f1)
        local mem=$(echo "$resources" | cut -d'|' -f2)
        local port_status=$(check_service_port "$port")
        local http_status=$(check_service_http "$url")
        
        printf "${BOLD}${CYAN}│${NC} %-17s %-11s %-7s %-7s %-10s %-7s %-7s ${BOLD}${CYAN}│${NC}\n" \
            "$service" "$status" "$uptime" "$cpu" "$mem" "$port_status" "$http_status"
    done
    
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display infrastructure services
display_infrastructure_services() {
    echo -e "${BOLD}${YELLOW}┌─ INFRASTRUCTURE SERVICES ─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${YELLOW}│${NC} Service                    Type        Status      Uptime  CPU     Memory     ${BOLD}${YELLOW}│${NC}"
    echo -e "${BOLD}${YELLOW}├─────────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    for service in "${!INFRASTRUCTURE_INFO[@]}"; do
        local info="${INFRASTRUCTURE_INFO[$service]}"
        local type=$(echo "$info" | cut -d'|' -f1)
        local port=$(echo "$info" | cut -d'|' -f2)
        
        local status=$(get_service_status "$service")
        local uptime=$(get_service_uptime "$service")
        local resources=$(get_service_resources "$service")
        local cpu=$(echo "$resources" | cut -d'|' -f1)
        local mem=$(echo "$resources" | cut -d'|' -f2)
        
        printf "${BOLD}${YELLOW}│${NC} %-25s %-11s %-11s %-7s %-7s %-10s ${BOLD}${YELLOW}│${NC}\n" \
            "$service" "$type" "$status" "$uptime" "$cpu" "$mem"
    done
    
    echo -e "${BOLD}${YELLOW}└─────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display service URLs
display_service_urls() {
    echo -e "${BOLD}${GREEN}┌─ SERVICE URLS ─────────────────────────────────────────────────────────────────┐${NC}"
    
    for service in "${!SERVICE_INFO[@]}"; do
        local info="${SERVICE_INFO[$service]}"
        local description=$(echo "$info" | cut -d'|' -f1)
        local url=$(echo "$info" | cut -d'|' -f2)
        
        local status=$(check_service_http "$url")
        printf "${BOLD}${GREEN}│${NC} %-20s %-30s %s\n" "$description:" "$url" "$status"
    done
    
    echo -e "${BOLD}${GREEN}└─────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display system resources
display_system_resources() {
    echo -e "${BOLD}${PURPLE}┌─ SYSTEM RESOURCES ─────────────────────────────────────────────────────────────┐${NC}"
    
    # Docker info
    if command -v docker >/dev/null 2>&1; then
        local docker_info=$(docker system df --format "{{.Type}}\t{{.TotalCount}}\t{{.Size}}" 2>/dev/null)
        echo -e "${BOLD}${PURPLE}│${NC} Docker Images:    $(echo "$docker_info" | grep Images | cut -f2)"
        echo -e "${BOLD}${PURPLE}│${NC} Docker Containers: $(echo "$docker_info" | grep Containers | cut -f2)"
        echo -e "${BOLD}${PURPLE}│${NC} Docker Volumes:   $(echo "$docker_info" | grep Volumes | cut -f2)"
    fi
    
    # System load
    if [ -f /proc/loadavg ]; then
        local load=$(cat /proc/loadavg | cut -d' ' -f1-3)
        echo -e "${BOLD}${PURPLE}│${NC} System Load:      $load"
    fi
    
    # Memory usage
    if [ -f /proc/meminfo ]; then
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local mem_used=$((mem_total - mem_available))
        local mem_percent=$((mem_used * 100 / mem_total))
        echo -e "${BOLD}${PURPLE}│${NC} Memory Usage:     ${mem_percent}% ($(echo "scale=1; $mem_used/1024/1024" | bc 2>/dev/null || echo "?")GB used)"
    fi
    
    # Disk usage
    local disk_usage=$(df . | tail -1 | awk '{print $5}')
    echo -e "${BOLD}${PURPLE}│${NC} Disk Usage:       $disk_usage"
    
    echo -e "${BOLD}${PURPLE}└─────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display logs summary
display_logs_summary() {
    echo -e "${BOLD}${RED}┌─ RECENT LOGS (Errors/Warnings) ───────────────────────────────────────────────┐${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        # Get recent error logs from all services
        local error_count=0
        for service in "${!SERVICE_INFO[@]}" "${!INFRASTRUCTURE_INFO[@]}"; do
            local container_id=$(docker-compose -f "$DOCKER_COMPOSE_FILE" ps -q "$service" 2>/dev/null)
            if [ -n "$container_id" ]; then
                local errors=$(docker logs --since="5m" "$container_id" 2>&1 | grep -i "error\|warning\|exception" | wc -l)
                if [ "$errors" -gt 0 ]; then
                    echo -e "${BOLD}${RED}│${NC} $service: $errors errors/warnings in last 5 minutes"
                    ((error_count += errors))
                fi
            fi
        done
        
        if [ "$error_count" -eq 0 ]; then
            echo -e "${BOLD}${RED}│${NC} No recent errors or warnings detected"
        fi
    else
        echo -e "${BOLD}${RED}│${NC} Docker not available for log analysis"
    fi
    
    echo -e "${BOLD}${RED}└─────────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Display quick actions
display_quick_actions() {
    echo -e "${BOLD}${GRAY}Quick Actions:${NC}"
    echo -e "  ${CYAN}r${NC} - Refresh now    ${CYAN}l${NC} - View logs    ${CYAN}s${NC} - Start services    ${CYAN}t${NC} - Stop services"
    echo -e "  ${CYAN}h${NC} - Show help      ${CYAN}q${NC} - Quit"
    echo ""
}

# Full dashboard display
display_full_dashboard() {
    display_header
    display_application_services
    display_infrastructure_services
    display_service_urls
    display_system_resources
    display_logs_summary
    display_quick_actions
}

# Compact dashboard display
display_compact_dashboard() {
    display_header
    
    echo -e "${BOLD}${CYAN}APPLICATION SERVICES:${NC}"
    for service in "${!SERVICE_INFO[@]}"; do
        local status=$(get_service_status "$service")
        local info="${SERVICE_INFO[$service]}"
        local url=$(echo "$info" | cut -d'|' -f2)
        local http_status=$(check_service_http "$url")
        printf "  %-20s %s %s\n" "$service" "$status" "$http_status"
    done
    echo ""
    
    echo -e "${BOLD}${YELLOW}INFRASTRUCTURE:${NC}"
    for service in "${!INFRASTRUCTURE_INFO[@]}"; do
        local status=$(get_service_status "$service")
        printf "  %-25s %s\n" "$service" "$status"
    done
    echo ""
    
    display_quick_actions
}

# Interactive dashboard
interactive_dashboard() {
    local mode="${1:-full}"
    
    while true; do
        if [ "$mode" = "compact" ]; then
            display_compact_dashboard
        else
            display_full_dashboard
        fi
        
        # Non-blocking input with timeout
        if read -t "$REFRESH_INTERVAL" -n 1 key 2>/dev/null; then
            case "$key" in
                'r'|'R')
                    continue  # Refresh immediately
                    ;;
                'l'|'L')
                    show_logs_menu
                    ;;
                's'|'S')
                    start_services_quick
                    ;;
                't'|'T')
                    stop_services_quick
                    ;;
                'c'|'C')
                    mode="compact"
                    ;;
                'f'|'F')
                    mode="full"
                    ;;
                'h'|'H')
                    show_help
                    ;;
                'q'|'Q')
                    echo -e "\n${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
            esac
        fi
    done
}

# Show logs menu
show_logs_menu() {
    clear
    echo -e "${BOLD}${CYAN}Service Logs${NC}"
    echo ""
    
    local services=($(printf '%s\n' "${!SERVICE_INFO[@]}" "${!INFRASTRUCTURE_INFO[@]}" | sort))
    local i=1
    
    for service in "${services[@]}"; do
        echo "$i) $service"
        ((i++))
    done
    
    echo ""
    read -p "Select service (number) or press Enter to return: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#services[@]}" ]; then
        local selected_service="${services[$((choice-1))]}"
        clear
        echo -e "${BOLD}${CYAN}Logs for $selected_service (last 50 lines):${NC}"
        echo ""
        
        if command -v docker >/dev/null 2>&1; then
            docker-compose -f "$DOCKER_COMPOSE_FILE" logs --tail=50 "$selected_service" 2>/dev/null || {
                echo "No logs available for $selected_service"
            }
        else
            echo "Docker not available"
        fi
        
        echo ""
        read -p "Press Enter to return to dashboard..."
    fi
}

# Quick start services
start_services_quick() {
    clear
    echo -e "${BOLD}${GREEN}Starting Services...${NC}"
    "$SCRIPT_DIR/start-services.sh" start
    echo ""
    read -p "Press Enter to return to dashboard..."
}

# Quick stop services
stop_services_quick() {
    clear
    echo -e "${BOLD}${RED}Stopping Services...${NC}"
    "$SCRIPT_DIR/start-services.sh" stop
    echo ""
    read -p "Press Enter to return to dashboard..."
}

# Show help
show_help() {
    clear
    echo -e "${BOLD}${CYAN}Automagik Suite Dashboard Help${NC}"
    echo ""
    echo -e "${BOLD}Keyboard Shortcuts:${NC}"
    echo "  r - Refresh dashboard immediately"
    echo "  l - View service logs"
    echo "  s - Start all services"
    echo "  t - Stop all services"
    echo "  c - Switch to compact view"
    echo "  f - Switch to full view"
    echo "  h - Show this help"
    echo "  q - Quit dashboard"
    echo ""
    echo -e "${BOLD}Status Icons:${NC}"
    echo "  ✅ - Service is running and healthy"
    echo "  🔄 - Service is starting or restarting"
    echo "  ❌ - Service is unhealthy or has errors"
    echo "  🔴 - Service is stopped"
    echo "  ⭕ - Service not found"
    echo "  🟢 - Port is open or endpoint is responding"
    echo "  🔴 - Port is closed or endpoint is down"
    echo ""
    read -p "Press Enter to return to dashboard..."
}

# Simple status check (non-interactive)
simple_status() {
    echo -e "${BOLD}${BLUE}Automagik Suite Status${NC}"
    echo ""
    
    local all_healthy=true
    
    echo -e "${BOLD}Application Services:${NC}"
    for service in "${!SERVICE_INFO[@]}"; do
        local status=$(get_service_status "$service")
        local info="${SERVICE_INFO[$service]}"
        local url=$(echo "$info" | cut -d'|' -f2)
        local http_status=$(check_service_http "$url")
        
        printf "  %-20s %s %s\n" "$service" "$status" "$http_status"
        
        if [[ ! "$status" =~ "Running" ]] || [[ "$http_status" =~ "Down" ]]; then
            all_healthy=false
        fi
    done
    
    echo ""
    echo -e "${BOLD}Infrastructure Services:${NC}"
    for service in "${!INFRASTRUCTURE_INFO[@]}"; do
        local status=$(get_service_status "$service")
        printf "  %-25s %s\n" "$service" "$status"
        
        if [[ ! "$status" =~ "Running" ]]; then
            all_healthy=false
        fi
    done
    
    echo ""
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}✅ All services are healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ Some services need attention${NC}"
        return 1
    fi
}

# Main function when script is run directly
main() {
    case "${1:-dashboard}" in
        "dashboard"|"")
            interactive_dashboard "full"
            ;;
        "compact")
            interactive_dashboard "compact"
            ;;
        "status")
            simple_status
            ;;
        "once")
            display_full_dashboard
            ;;
        *)
            echo "Usage: $0 {dashboard|compact|status|once}"
            echo "  dashboard - Interactive dashboard (default)"
            echo "  compact   - Interactive compact dashboard"
            echo "  status    - Simple status check"
            echo "  once      - Display dashboard once and exit"
            exit 1
            ;;
    esac
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Dashboard stopped.${NC}"; exit 0' INT

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi