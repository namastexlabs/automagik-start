#!/bin/bash

# ===================================================================
# 🧹 Automagik Suite - Complete Cleanup Script
# ===================================================================
# This script provides comprehensive cleanup of Docker containers,
# images, volumes, and networks related to the Automagik Suite.

set -e

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/scripts/utils/colors.sh" ]; then
    source "$SCRIPT_DIR/scripts/utils/colors.sh"
    source "$SCRIPT_DIR/scripts/utils/logging.sh"
else
    # Fallback colors if utilities not available
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    
    log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
    log_success() { echo -e "${GREEN}✅ $1${NC}"; }
    log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
    log_error() { echo -e "${RED}❌ $1${NC}"; }
    log_section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }
fi

# Cleanup options
CLEANUP_CONTAINERS=false
CLEANUP_IMAGES=false
CLEANUP_VOLUMES=false
CLEANUP_NETWORKS=false
CLEANUP_ALL=false
FORCE_CLEANUP=false

show_help() {
    echo -e "${CYAN}🧹 Automagik Suite Cleanup Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --containers     Stop and remove Automagik containers"
    echo "  --images         Remove Automagik Docker images"
    echo "  --volumes        Remove Automagik Docker volumes"
    echo "  --networks       Remove Automagik Docker networks"
    echo "  --all            Complete cleanup (containers + images + volumes + networks)"
    echo "  --force          Skip confirmation prompts"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --containers               # Remove only containers"
    echo "  $0 --all                      # Complete cleanup with confirmation"
    echo "  $0 --all --force              # Complete cleanup without confirmation"
    echo ""
}

cleanup_containers() {
    log_section "Cleaning Up Automagik Containers"
    
    # Stop and remove containers using docker-compose if available
    if [ -f "docker-compose.yml" ]; then
        log_info "Stopping containers via docker-compose..."
        docker compose down --remove-orphans 2>/dev/null || docker-compose down --remove-orphans 2>/dev/null || true
    fi
    
    # Find and stop Automagik containers
    local containers=$(docker ps -q --filter "name=am-agents-labs" --filter "name=automagik-" --filter "name=evolution-" 2>/dev/null || true)
    
    if [ -n "$containers" ]; then
        log_info "Stopping Automagik containers..."
        echo "$containers" | xargs docker stop 2>/dev/null || true
        
        log_info "Removing Automagik containers..."
        echo "$containers" | xargs docker rm 2>/dev/null || true
        log_success "Active containers cleaned up"
    fi
    
    # Remove any stopped Automagik containers
    local stopped_containers=$(docker ps -aq --filter "name=am-agents-labs" --filter "name=automagik-" --filter "name=evolution-" 2>/dev/null || true)
    
    if [ -n "$stopped_containers" ]; then
        log_info "Removing stopped Automagik containers..."
        echo "$stopped_containers" | xargs docker rm 2>/dev/null || true
        log_success "Stopped containers cleaned up"
    else
        log_info "No Automagik containers found"
    fi
}

cleanup_images() {
    log_section "Cleaning Up Automagik Images"
    
    # Find Automagik images
    local images=$(docker images -q --filter "reference=*automagik*" --filter "reference=*am-agents*" --filter "reference=prod_*" 2>/dev/null || true)
    
    if [ -n "$images" ]; then
        log_info "Removing Automagik Docker images..."
        echo "$images" | xargs docker rmi -f 2>/dev/null || true
        log_success "Automagik images cleaned up"
    else
        log_info "No Automagik images found"
    fi
    
    # Clean up dangling images
    local dangling_images=$(docker images -q --filter "dangling=true" 2>/dev/null || true)
    if [ -n "$dangling_images" ]; then
        log_info "Removing dangling images..."
        echo "$dangling_images" | xargs docker rmi 2>/dev/null || true
        log_success "Dangling images cleaned up"
    fi
}

cleanup_volumes() {
    log_section "Cleaning Up Automagik Volumes"
    
    # Find Automagik volumes
    local volumes=$(docker volume ls -q --filter "name=prod_" --filter "name=automagik" --filter "name=am-agents" --filter "name=evolution" 2>/dev/null || true)
    
    if [ -n "$volumes" ]; then
        log_warning "This will permanently delete all data in Automagik volumes!"
        echo "$volumes" | while read volume; do
            log_info "Volume to be removed: $volume"
        done
        
        if [ "$FORCE_CLEANUP" = "false" ]; then
            echo ""
            read -p "⚠️  Are you sure you want to delete these volumes? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log_info "Volume cleanup cancelled"
                return 0
            fi
        fi
        
        log_info "Removing Automagik volumes..."
        echo "$volumes" | xargs docker volume rm 2>/dev/null || true
        log_success "Automagik volumes cleaned up"
    else
        log_info "No Automagik volumes found"
    fi
}

cleanup_networks() {
    log_section "Cleaning Up Automagik Networks"
    
    # Find Automagik networks
    local networks=$(docker network ls -q --filter "name=prod_automagik" --filter "name=automagik" 2>/dev/null || true)
    
    if [ -n "$networks" ]; then
        log_info "Removing Automagik networks..."
        echo "$networks" | xargs docker network rm 2>/dev/null || true
        log_success "Automagik networks cleaned up"
    else
        log_info "No Automagik networks found"
    fi
}

docker_system_prune() {
    log_section "Docker System Cleanup"
    
    log_info "Running Docker system prune..."
    docker system prune -f --volumes 2>/dev/null || true
    log_success "Docker system cleanup completed"
}

show_status() {
    log_section "Current Docker Status"
    
    echo -e "${CYAN}📊 Containers:${NC}"
    docker ps -a --filter "name=automagik" --filter "name=am-agents" --filter "name=evolution" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No Automagik containers found"
    
    echo -e "\n${CYAN}📷 Images:${NC}"
    docker images --filter "reference=*automagik*" --filter "reference=*am-agents*" --filter "reference=prod_*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || echo "No Automagik images found"
    
    echo -e "\n${CYAN}💾 Volumes:${NC}"
    docker volume ls --filter "name=prod_" --filter "name=automagik" --filter "name=am-agents" --filter "name=evolution" --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null || echo "No Automagik volumes found"
    
    echo -e "\n${CYAN}🌐 Networks:${NC}"
    docker network ls --filter "name=automagik" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>/dev/null || echo "No Automagik networks found"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --containers)
                CLEANUP_CONTAINERS=true
                shift
                ;;
            --images)
                CLEANUP_IMAGES=true
                shift
                ;;
            --volumes)
                CLEANUP_VOLUMES=true
                shift
                ;;
            --networks)
                CLEANUP_NETWORKS=true
                shift
                ;;
            --all)
                CLEANUP_ALL=true
                shift
                ;;
            --force)
                FORCE_CLEANUP=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no specific cleanup options, show help
    if [ "$CLEANUP_ALL" = "false" ] && [ "$CLEANUP_CONTAINERS" = "false" ] && [ "$CLEANUP_IMAGES" = "false" ] && [ "$CLEANUP_VOLUMES" = "false" ] && [ "$CLEANUP_NETWORKS" = "false" ]; then
        show_help
        log_info "Current status:"
        show_status
        exit 0
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    log_section "🧹 Automagik Suite Cleanup"
    
    # Show current status before cleanup
    log_info "Status before cleanup:"
    show_status
    
    # Confirm cleanup if not forced
    if [ "$FORCE_CLEANUP" = "false" ]; then
        echo ""
        if [ "$CLEANUP_ALL" = "true" ]; then
            echo -e "${YELLOW}⚠️  This will perform COMPLETE cleanup of Automagik Docker resources!${NC}"
        fi
        read -p "🤔 Proceed with cleanup? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            exit 0
        fi
    fi
    
    # Perform cleanup based on options
    if [ "$CLEANUP_ALL" = "true" ] || [ "$CLEANUP_CONTAINERS" = "true" ]; then
        cleanup_containers
    fi
    
    if [ "$CLEANUP_ALL" = "true" ] || [ "$CLEANUP_IMAGES" = "true" ]; then
        cleanup_images
    fi
    
    if [ "$CLEANUP_ALL" = "true" ] || [ "$CLEANUP_VOLUMES" = "true" ]; then
        cleanup_volumes
    fi
    
    if [ "$CLEANUP_ALL" = "true" ] || [ "$CLEANUP_NETWORKS" = "true" ]; then
        cleanup_networks
    fi
    
    # Optional system prune for complete cleanup
    if [ "$CLEANUP_ALL" = "true" ]; then
        docker_system_prune
    fi
    
    log_section "✨ Cleanup Complete!"
    log_success "Automagik Suite cleanup finished successfully"
    
    # Show status after cleanup
    echo ""
    log_info "Status after cleanup:"
    show_status
}

# Run main function
main "$@"