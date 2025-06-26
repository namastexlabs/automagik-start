#!/bin/bash

# ===================================================================
# 🚀 Automagik Suite Deployment with Health Checks
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/port-check.sh"

# Deployment configuration
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_COMPOSE_FILE="$BASE_DIR/docker-compose.yml"

# Service startup order (infrastructure first, then applications)
INFRASTRUCTURE_SERVICES=(
    "am-agents-labs-postgres"
    "automagik-spark-postgres"
    "automagik-spark-redis"
    "evolution-postgres"
    "evolution-redis"
    "evolution-rabbitmq"
)

APPLICATION_SERVICES=(
    "am-agents-labs"
    "automagik-spark-api"
    "automagik-spark-worker"
    "automagik-tools"
    # Note: Services below are commented out as they don't have Dockerfiles yet
    # "automagik-evolution"
    # "automagik-omni"
    # "automagik-ui-v2"
)

OPTIONAL_SERVICES=(
    "langflow"
)

ALL_SERVICES=("${INFRASTRUCTURE_SERVICES[@]}" "${APPLICATION_SERVICES[@]}")

# Health check configuration
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
HEALTH_CHECK_INTERVAL=10  # 10 seconds
SERVICE_START_DELAY=5     # 5 seconds between service starts

# Check Docker and Docker Compose availability
check_docker_requirements() {
    log_section "Docker Requirements Check"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        log_info "Please start Docker and try again"
        return 1
    fi
    
    local docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,$//')
    log_success "Docker $docker_version is available and running"
    
    # Check Docker Compose
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short)
        log_success "Docker Compose $compose_version is available"
    elif command -v docker-compose >/dev/null 2>&1; then
        local compose_version=$(docker-compose --version | cut -d' ' -f3 | sed 's/,$//')
        log_success "Docker Compose (standalone) $compose_version is available"
        export DOCKER_COMPOSE_CMD="docker-compose"
    else
        log_error "Docker Compose is not available"
        return 1
    fi
    
    export DOCKER_COMPOSE_CMD="${DOCKER_COMPOSE_CMD:-docker compose}"
    
    return 0
}

# Check if docker-compose.yml exists and is valid
check_compose_file() {
    log_info "Checking Docker Compose configuration..."
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        return 1
    fi
    
    # Validate compose file
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" config >/dev/null 2>&1; then
        log_success "Docker Compose file is valid"
    else
        log_error "Docker Compose file validation failed"
        log_info "Run '$DOCKER_COMPOSE_CMD -f $DOCKER_COMPOSE_FILE config' to see errors"
        return 1
    fi
    
    return 0
}

# Check for conflicting services
check_service_conflicts() {
    log_info "Checking for running conflicting services..."
    
    # Check if any services are already running
    local running_services=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --services --filter "status=running" 2>/dev/null | wc -l)
    
    if [ "$running_services" -gt 0 ]; then
        log_warning "Some Automagik services are already running"
        
        echo ""
        echo -e "${YELLOW}Running services:${NC}"
        $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --format "table"
        echo ""
        
        while true; do
            echo "Options:"
            echo "1) Stop existing services and restart"
            echo "2) Continue with current services"
            echo "3) Exit"
            
            read -p "Choose option [1-3]: " choice
            case $choice in
                1)
                    log_info "Stopping existing services..."
                    stop_all_services
                    break
                    ;;
                2)
                    log_info "Continuing with existing services"
                    return 0
                    ;;
                3)
                    log_info "Exiting at user request"
                    exit 0
                    ;;
                *)
                    print_warning "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    fi
    
    return 0
}

# Pull or build Docker images
prepare_images() {
    log_section "Image Preparation"
    
    log_info "Building/pulling required Docker images..."
    
    # Build application images
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" build --parallel 2>&1 | tee -a "$LOG_FILE"; then
        log_success "All images built successfully"
    else
        log_error "Failed to build some images"
        return 1
    fi
    
    return 0
}

# Start infrastructure services
start_infrastructure() {
    log_section "Infrastructure Services Startup"
    
    log_info "Starting infrastructure services..."
    
    for service in "${INFRASTRUCTURE_SERVICES[@]}"; do
        start_service "$service"
        
        if ! wait_for_service_health "$service"; then
            log_error "Infrastructure service $service failed to start properly"
            return 1
        fi
        
        sleep "$SERVICE_START_DELAY"
    done
    
    log_success "All infrastructure services started successfully"
    return 0
}

# Start application services
start_applications() {
    log_section "Application Services Startup"
    
    log_info "Starting application services..."
    
    for service in "${APPLICATION_SERVICES[@]}"; do
        start_service "$service"
        
        if ! wait_for_service_health "$service"; then
            log_warning "Application service $service may not be fully ready"
        fi
        
        sleep "$SERVICE_START_DELAY"
    done
    
    log_success "All application services started"
    return 0
}

# Start optional services
start_optional_services() {
    log_section "Optional Services"
    
    echo -e "${YELLOW}Optional services available:${NC}"
    for service in "${OPTIONAL_SERVICES[@]}"; do
        case "$service" in
            "langflow")
                echo "• Langflow - Visual Flow Builder (http://localhost:7860)"
                ;;
        esac
    done
    echo ""
    
    if [ "$INSTALL_MODE" = "interactive" ]; then
        while true; do
            read -p "Would you like to start optional services? [Y/n]: " start_optional
            case $start_optional in
                [Yy]|[Yy][Ee][Ss]|"")
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    log_info "Skipping optional services"
                    return 0
                    ;;
                *)
                    print_warning "Please answer yes or no."
                    ;;
            esac
        done
    else
        log_info "Auto-starting optional services in non-interactive mode"
    fi
    
    log_info "Starting optional services with profiles..."
    
    # Start with langflow profile
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" --profile langflow up -d 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Optional services started"
        
        # Wait for optional services to be ready
        for service in "${OPTIONAL_SERVICES[@]}"; do
            if ! wait_for_service_health "$service"; then
                log_warning "Optional service $service may not be fully ready"
            fi
        done
    else
        log_warning "Some optional services failed to start"
    fi
    
    return 0
}

# Start a single service
start_service() {
    local service="$1"
    
    log_info "Starting $service..."
    
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d "$service" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "$service started"
        return 0
    else
        log_error "Failed to start $service"
        return 1
    fi
}

# Wait for service health check
wait_for_service_health() {
    local service="$1"
    local timeout="$HEALTH_CHECK_TIMEOUT"
    local interval="$HEALTH_CHECK_INTERVAL"
    
    log_info "Waiting for $service to become healthy..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        # Check container status
        local container_status=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format '{{.State.Status}}' 2>/dev/null)
        
        if [ "$container_status" = "running" ]; then
            # Check health status if available
            local health_status=$($DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format '{{.State.Health.Status}}' 2>/dev/null)
            
            if [ "$health_status" = "healthy" ] || [ "$health_status" = "" ]; then
                log_success "$service is healthy"
                return 0
            elif [ "$health_status" = "unhealthy" ]; then
                log_error "$service is unhealthy"
                show_service_logs "$service" 20
                return 1
            fi
            # Continue waiting if starting
        elif [ "$container_status" = "exited" ]; then
            log_error "$service exited unexpectedly"
            show_service_logs "$service" 20
            return 1
        fi
        
        echo -ne "\\r${YELLOW}Waiting for $service... ${elapsed}s${NC}"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo ""
    log_warning "$service health check timeout after ${timeout}s"
    return 1
}

# Show service logs
show_service_logs() {
    local service="$1"
    local lines="${2:-50}"
    
    echo ""
    echo -e "${CYAN}Last $lines lines from $service logs:${NC}"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" logs --tail="$lines" "$service" 2>/dev/null || true
    echo ""
}

# Check service connectivity
check_service_connectivity() {
    log_section "Service Connectivity Check"
    
    local connectivity_failed=false
    
    # Define service endpoints for health checks
    declare -A SERVICE_ENDPOINTS=(
        ["am-agents-labs"]="http://localhost:8881/health"
        ["automagik-spark-api"]="http://localhost:8883/health"
        ["automagik-tools"]="http://localhost:8885/health"
        # Note: Worker service doesn't have HTTP endpoint for health checks
        # ["automagik-evolution"]="http://localhost:9000/health"
        # ["automagik-omni"]="http://localhost:8882/health"
        # ["automagik-ui-v2"]="http://localhost:8888"
        ["langflow"]="http://localhost:7860/health"
    )
    
    for service in "${!SERVICE_ENDPOINTS[@]}"; do
        local endpoint="${SERVICE_ENDPOINTS[$service]}"
        local url_host=$(echo "$endpoint" | cut -d':' -f2 | tr -d '/')
        local url_port=$(echo "$endpoint" | cut -d':' -f3 | cut -d'/' -f1)
        
        log_info "Checking $service connectivity..."
        
        if check_http_port "$url_host" "$url_port" "/" 5; then
            log_success "$service is responding at $endpoint"
        else
            log_warning "$service not responding at $endpoint"
            connectivity_failed=true
        fi
    done
    
    if [ "$connectivity_failed" = true ]; then
        log_warning "Some services are not responding - they may still be starting up"
    else
        log_success "All services are responding to health checks"
    fi
    
    return 0
}

# Display service status
show_services_status() {
    log_section "Services Status"
    
    echo -e "${CYAN}Docker Compose Services:${NC}"
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --format "table"
    
    echo ""
    echo -e "${CYAN}Service URLs:${NC}"
    echo "• Main Interface:     http://localhost:8888"
    echo "• AM Agents Labs:     http://localhost:8881" 
    echo "• Automagik Spark:    http://localhost:8883"
    echo "• Automagik Omni:     http://localhost:8882"
    echo "• MCP Tools SSE:      http://localhost:8884"
    echo "• MCP Tools HTTP:     http://localhost:8885"
    echo "• Evolution API:      http://localhost:9000"
    echo ""
    echo -e "${CYAN}Optional Services:${NC}"
    echo "• Langflow:           http://localhost:7860"
    echo ""
}

# Stop all services
stop_all_services() {
    log_section "Stopping Services"
    
    log_info "Stopping all Automagik services..."
    
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down 2>&1 | tee -a "$LOG_FILE"; then
        log_success "All services stopped"
    else
        log_warning "Some services may not have stopped cleanly"
    fi
    
    return 0
}

# Clean up services and volumes
cleanup_services() {
    log_section "Service Cleanup"
    
    log_warning "This will remove all containers, networks, and volumes"
    log_warning "All data will be lost!"
    
    while true; do
        read -p "Are you sure you want to continue? [y/N]: " confirm
        case $confirm in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                log_info "Cleanup cancelled"
                return 0
                ;;
            *)
                print_warning "Please answer yes or no."
                ;;
        esac
    done
    
    log_info "Removing all services, networks, and volumes..."
    
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down -v --remove-orphans 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Cleanup completed"
    else
        log_warning "Cleanup may not have completed fully"
    fi
    
    return 0
}

# Deploy all services
deploy_all_services() {
    log_section "Automagik Suite Deployment"
    
    # Pre-deployment checks
    if ! check_docker_requirements; then
        return 1
    fi
    
    if ! check_compose_file; then
        return 1
    fi
    
    # Port conflict check
    log_info "Checking for port conflicts..."
    if ! check_all_ports; then
        log_warning "Port conflicts detected - some services may not start"
    fi
    
    # Service conflict check
    check_service_conflicts
    
    # Prepare images
    if ! prepare_images; then
        return 1
    fi
    
    # Start services in order
    if ! start_infrastructure; then
        log_error "Failed to start infrastructure services"
        return 1
    fi
    
    if ! start_applications; then
        log_error "Failed to start application services"
        return 1
    fi
    
    # Start optional services
    start_optional_services
    
    # Post-deployment checks
    sleep 10  # Give services time to fully initialize
    check_service_connectivity
    show_services_status
    
    log_success "Automagik Suite deployment completed!"
    log_info "Access the main interface at: http://localhost:8888"
    
    return 0
}

# Monitor services (continuous)
monitor_services() {
    log_section "Service Monitoring"
    
    log_info "Starting continuous service monitoring..."
    log_info "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        echo -e "${BOLD}${BLUE}Automagik Suite - Service Monitor${NC}"
        echo -e "${GRAY}$(date)${NC}"
        echo ""
        
        # Show service status
        $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" ps --format "table" 2>/dev/null || {
            echo -e "${RED}Error: Cannot connect to Docker${NC}"
            sleep 5
            continue
        }
        
        echo ""
        echo -e "${CYAN}Resource Usage:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker ps -q) 2>/dev/null | head -10
        
        sleep 5
    done
}

# Main function when script is run directly
main() {
    case "${1:-deploy}" in
        "deploy")
            deploy_all_services
            ;;
        "start")
            if ! check_docker_requirements || ! check_compose_file; then
                exit 1
            fi
            start_infrastructure
            start_applications
            show_services_status
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            stop_all_services
            sleep 5
            deploy_all_services
            ;;
        "status")
            show_services_status
            ;;
        "logs")
            if [ -n "$2" ]; then
                show_service_logs "$2" "${3:-50}"
            else
                echo "Usage: $0 logs <service_name> [lines]"
                exit 1
            fi
            ;;
        "monitor")
            monitor_services
            ;;
        "cleanup")
            cleanup_services
            ;;
        *)
            echo "Usage: $0 {deploy|start|stop|restart|status|logs|monitor|cleanup}"
            echo "  deploy   - Full deployment with health checks (default)"
            echo "  start    - Start all services"
            echo "  stop     - Stop all services"
            echo "  restart  - Stop and deploy services"
            echo "  status   - Show services status"
            echo "  logs     - Show service logs"
            echo "  monitor  - Continuous service monitoring"
            echo "  cleanup  - Remove all containers and volumes"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi