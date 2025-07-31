#!/bin/bash
# ===================================================================
# 🔄 Automagik Suite - Environment Value Sync with Variable Mapping
# ===================================================================
# Updates values in service .env files from master .env
# Only updates existing variables, doesn't add new ones
# Supports variable name mapping based on ENV_VARIABLE_MAPPING.md
# 
# Key Mappings:
# - AUTOMAGIK_AGENTS_* → AUTOMAGIK_*
# - AGENT_API_* → AUTOMAGIK_API_*
# - DATABASE_PATH → AUTOMAGIK_UI_DATABASE_PATH
# - PORT/HOST → AUTOMAGIK_TOOLS_SSE_PORT/AUTOMAGIK_TOOLS_HOST

set -e

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/colors.sh" 2>/dev/null || {
    # Fallback colors if utils/colors.sh doesn't exist
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
}

# Project paths
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAIN_ENV_FILE="$PROJECT_ROOT/.env"
EXAMPLE_ENV_FILE="$PROJECT_ROOT/.env.example"

# Service directories
declare -a SERVICES=(
    "automagik"
    "automagik-spark"
    "automagik-tools"
    "automagik-omni"
    "automagik-ui"
)

# Symbols
CHECKMARK="✅"
WARNING="⚠️"
ERROR="❌"
ROCKET="🚀"
GEAR="⚙️"
INFO="ℹ️"

print_status() {
    echo -e "${PURPLE}${GEAR} $1${RESET}"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK} $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${RESET}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${RESET}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${RESET}"
}

# Check if main .env exists
check_main_env() {
    if [[ ! -f "$MAIN_ENV_FILE" ]]; then
        print_error "Main .env file not found: $MAIN_ENV_FILE"
        print_info "Create one from template: cp $EXAMPLE_ENV_FILE $MAIN_ENV_FILE"
        return 1
    fi
    return 0
}

# Load environment variables into an associative array
load_env_to_map() {
    local env_file="$1"
    declare -gA env_map
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Handle lines with = (environment variables)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            env_map["$var_name"]="$var_value"
        fi
    done < "$env_file"
}

# Define variable mappings for services
declare -gA VARIABLE_MAPPINGS

# Initialize variable mappings based on ENV_VARIABLE_MAPPING.md
init_variable_mappings() {
    # Core Automagik Service mappings (automagik)
    VARIABLE_MAPPINGS["automagik:AUTOMAGIK_AGENTS_API_PORT"]="AUTOMAGIK_API_PORT"
    VARIABLE_MAPPINGS["automagik:AUTOMAGIK_AGENTS_API_HOST"]="AUTOMAGIK_API_HOST"
    VARIABLE_MAPPINGS["automagik:AUTOMAGIK_AGENTS_URL"]="AUTOMAGIK_API_URL"
    
    # Automagik Spark Service mappings
    # Note: Spark uses AUTOMAGIK_SPARK_* variables directly - no mappings needed for most variables
    # Only map integration variables that reference external services
    
    # Automagik Omni Service mappings
    # Note: Omni uses AUTOMAGIK_OMNI_* prefixed variables directly - no mappings needed
    
    # Automagik Tools Service mappings
    VARIABLE_MAPPINGS["automagik-tools:PORT"]="AUTOMAGIK_TOOLS_SSE_PORT"
    VARIABLE_MAPPINGS["automagik-tools:HOST"]="AUTOMAGIK_TOOLS_HOST"
    VARIABLE_MAPPINGS["automagik-tools:AUTOMAGIK_TOOLS_PORT"]="AUTOMAGIK_TOOLS_HTTP_PORT"
    
    # Automagik UI Service mappings
    VARIABLE_MAPPINGS["automagik-ui:AUTOMAGIK_DEV_PORT"]="AUTOMAGIK_UI_DEV_PORT"
    VARIABLE_MAPPINGS["automagik-ui:AUTOMAGIK_PROD_PORT"]="AUTOMAGIK_UI_PROD_PORT"
    VARIABLE_MAPPINGS["automagik-ui:DATABASE_PATH"]="AUTOMAGIK_UI_DATABASE_PATH"
    VARIABLE_MAPPINGS["automagik-ui:DB_PATH"]="AUTOMAGIK_UI_DATABASE_PATH"
    
    # Global mappings for all services
    # These apply to all services unless overridden by service-specific mapping
    VARIABLE_MAPPINGS["*:AGENT_API_URL"]="AUTOMAGIK_API_URL"
    VARIABLE_MAPPINGS["*:AGENT_API_KEY"]="AUTOMAGIK_API_KEY"
}

# Get mapped variable name for a service
get_mapped_var() {
    local service="$1"
    local service_var="$2"
    
    # Check service-specific mapping first
    if [[ -n "${VARIABLE_MAPPINGS[$service:$service_var]+exists}" ]]; then
        echo "${VARIABLE_MAPPINGS[$service:$service_var]}"
    # Check global mapping
    elif [[ -n "${VARIABLE_MAPPINGS[*:$service_var]+exists}" ]]; then
        echo "${VARIABLE_MAPPINGS[*:$service_var]}"
    # Return original if no mapping
    else
        echo "$service_var"
    fi
}

# Update values in service .env file
update_service_env() {
    local service="$1"
    local service_dir="$PROJECT_ROOT/$service"
    # Use .env.local for automagik-ui, .env for others
    if [[ "$service" == "automagik-ui" ]]; then
        local service_env_file="$service_dir/.env.local"
    else
        local service_env_file="$service_dir/.env"
    fi
    
    if [[ ! -d "$service_dir" ]]; then
        print_warning "Service directory not found: $service_dir"
        return 1
    fi
    
    if [[ ! -f "$service_env_file" ]]; then
        print_warning "$service: .env file not found"
        return 1
    fi
    
    # Load master env variables
    declare -A master_env
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            master_env["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi
    done < "$MAIN_ENV_FILE"
    
    # Create temp file for updated content
    local temp_file=$(mktemp)
    local updates_made=0
    
    # Process service env file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if line is a commented variable
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local commented_value="${BASH_REMATCH[2]}"
            
            # Get mapped variable name from master env
            local master_var_name=$(get_mapped_var "$service" "$var_name")
            
            # If mapped variable exists in master, uncomment and use master's value
            if [[ -n "${master_env[$master_var_name]+exists}" ]]; then
                local new_value="${master_env[$master_var_name]}"
                echo "$var_name=$new_value" >> "$temp_file"
                updates_made=$((updates_made + 1))
                print_info "  Uncommented and updated: $var_name"
            # If variable exists in master with same name, uncomment and use it
            elif [[ -n "${master_env[$var_name]+exists}" ]]; then
                local new_value="${master_env[$var_name]}"
                echo "$var_name=$new_value" >> "$temp_file"
                updates_made=$((updates_made + 1))
                print_info "  Uncommented and updated: $var_name"
            else
                # Keep original commented line if not in master
                echo "$line" >> "$temp_file"
            fi
        # Check if line is an uncommented variable
        elif [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local current_value="${BASH_REMATCH[2]}"
            
            # Get mapped variable name from master env
            local master_var_name=$(get_mapped_var "$service" "$var_name")
            
            # If mapped variable exists in master, use master's value
            if [[ -n "${master_env[$master_var_name]+exists}" ]]; then
                local new_value="${master_env[$master_var_name]}"
                if [[ "$current_value" != "$new_value" ]]; then
                    echo "$var_name=$new_value" >> "$temp_file"
                    updates_made=$((updates_made + 1))
                else
                    echo "$line" >> "$temp_file"
                fi
            # If variable exists in master with same name, use it
            elif [[ -n "${master_env[$var_name]+exists}" ]]; then
                local new_value="${master_env[$var_name]}"
                if [[ "$current_value" != "$new_value" ]]; then
                    echo "$var_name=$new_value" >> "$temp_file"
                    updates_made=$((updates_made + 1))
                else
                    echo "$line" >> "$temp_file"
                fi
            else
                # If strict mode and variable not in master, comment it out
                if [[ "${STRICT_SYNC:-false}" == "true" ]]; then
                    echo "# $line" >> "$temp_file"
                    updates_made=$((updates_made + 1))
                    print_info "  Commented out: $var_name (not in master)"
                else
                    # Keep original line if not in master
                    echo "$line" >> "$temp_file"
                fi
            fi
        else
            # Keep non-variable lines as-is (comments, blank lines)
            echo "$line" >> "$temp_file"
        fi
    done < "$service_env_file"
    
    # Replace original file with updated one
    mv "$temp_file" "$service_env_file"
    
    if [[ $updates_made -gt 0 ]]; then
        print_success "$service: Updated $updates_made values"
    else
        print_info "$service: Already in sync"
    fi
    
    return 0
}

# Sync all services
sync_all_services() {
    print_status "Syncing environment values to services..."
    
    local success_count=0
    local total_count=${#SERVICES[@]}
    
    for service in "${SERVICES[@]}"; do
        if update_service_env "$service"; then
            success_count=$((success_count + 1))
        else
            print_error "Failed to update $service"
        fi
    done
    
    echo ""
    if [[ "$success_count" == "$total_count" ]]; then
        print_success "Synced values to all $total_count services"
        return 0
    else
        print_error "Synced $success_count out of $total_count services"
        return 1
    fi
}

# Check environment differences
check_env_status() {
    print_status "Checking environment differences..."
    
    if ! check_main_env; then
        return 1
    fi
    
    # Load master env
    declare -A master_env
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            master_env["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi
    done < "$MAIN_ENV_FILE"
    
    local differences_found=false
    
    echo ""
    for service in "${SERVICES[@]}"; do
        local service_dir="$PROJECT_ROOT/$service"
        # Use .env.local for automagik-ui, .env for others
        if [[ "$service" == "automagik-ui" ]]; then
            local service_env_file="$service_dir/.env.local"
        else
            local service_env_file="$service_dir/.env"
        fi
        
        if [[ ! -f "$service_env_file" ]]; then
            print_warning "$service: .env file missing"
            differences_found=true
            continue
        fi
        
        local service_has_diff=false
        local diff_count=0
        
        # Check each variable in service env
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Check for commented variables that exist in master
            if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
                local var_name="${BASH_REMATCH[1]}"
                local commented_value="${BASH_REMATCH[2]}"
                
                # Get mapped variable name from master env
                local master_var_name=$(get_mapped_var "$service" "$var_name")
                
                # Check if this commented variable exists in master
                if [[ -n "${master_env[$master_var_name]+exists}" ]] || [[ -n "${master_env[$var_name]+exists}" ]]; then
                    if [[ "$service_has_diff" == "false" ]]; then
                        print_warning "$service: Variables to uncomment from master:"
                        service_has_diff=true
                        differences_found=true
                    fi
                    echo "  - $var_name (currently commented out)"
                    diff_count=$((diff_count + 1))
                fi
            # Check for uncommented variables
            elif [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
                local var_name="${BASH_REMATCH[1]}"
                local service_value="${BASH_REMATCH[2]}"
                
                # Get mapped variable name from master env
                local master_var_name=$(get_mapped_var "$service" "$var_name")
                
                # Check if mapped variable exists in master and values differ
                if [[ -n "${master_env[$master_var_name]+exists}" ]]; then
                    local master_value="${master_env[$master_var_name]}"
                    if [[ "$service_value" != "$master_value" ]]; then
                        if [[ "$service_has_diff" == "false" ]]; then
                            print_warning "$service: Different values from master:"
                            service_has_diff=true
                            differences_found=true
                        fi
                        echo "  - $var_name (mapped from $master_var_name)"
                        diff_count=$((diff_count + 1))
                    fi
                # Also check if variable exists in master with same name
                elif [[ -n "${master_env[$var_name]+exists}" ]]; then
                    local master_value="${master_env[$var_name]}"
                    if [[ "$service_value" != "$master_value" ]]; then
                        if [[ "$service_has_diff" == "false" ]]; then
                            print_warning "$service: Different values from master:"
                            service_has_diff=true
                            differences_found=true
                        fi
                        echo "  - $var_name"
                        diff_count=$((diff_count + 1))
                    fi
                fi
            fi
        done < "$service_env_file"
        
        if [[ "$service_has_diff" == "false" ]]; then
            print_success "$service: In sync with master"
        else
            echo "    Total: $diff_count differences"
        fi
    done
    
    echo ""
    if [[ "$differences_found" == "true" ]]; then
        print_info "Run 'make env' to sync values from master .env"
        return 1
    else
        print_success "All service .env files are in sync"
        return 0
    fi
}

# Show environment status summary
show_env_status() {
    print_status "Environment Status Report"
    echo ""
    
    # Main .env status
    if [[ -f "$MAIN_ENV_FILE" ]]; then
        local var_count=$(grep -c "^[A-Za-z_][A-Za-z0-9_]*=" "$MAIN_ENV_FILE" 2>/dev/null || echo "0")
        print_success "Main .env: $var_count variables"
    else
        print_error "Main .env: not found"
    fi
    
    echo ""
    print_info "Service .env files:"
    
    for service in "${SERVICES[@]}"; do
        local service_dir="$PROJECT_ROOT/$service"
        # Use .env.local for automagik-ui, .env for others
        if [[ "$service" == "automagik-ui" ]]; then
            local service_env_file="$service_dir/.env.local"
        else
            local service_env_file="$service_dir/.env"
        fi
        
        if [[ -f "$service_env_file" ]]; then
            local vars_count=$(grep -c "^[A-Za-z_][A-Za-z0-9_]*=" "$service_env_file" 2>/dev/null || echo "0")
            local mod_time=$(stat -c "%y" "$service_env_file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
            print_success "$service: $vars_count variables (modified: $mod_time)"
        else
            print_warning "$service: .env not found"
        fi
    done
}

# Main function
main() {
    local command="${1:-help}"
    
    # Initialize variable mappings
    init_variable_mappings
    
    case "$command" in
        "sync")
            if check_main_env; then
                sync_all_services
            fi
            ;;
        "sync-strict")
            if check_main_env; then
                export STRICT_SYNC=true
                print_warning "Running in STRICT mode - will comment out variables not in master"
                sync_all_services
            fi
            ;;
        "check")
            check_env_status
            ;;
        "status")
            show_env_status
            ;;
        "help"|"-h"|"--help")
            echo "Automagik Suite Environment Value Sync"
            echo ""
            echo "Usage: $0 COMMAND"
            echo ""
            echo "Commands:"
            echo "  sync         Update values in service .env files from master"
            echo "  sync-strict  Strict sync - also comments out vars not in master"
            echo "  check        Check for value differences between master and services"
            echo "  status       Show environment file statistics"
            echo "  help         Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 sync         # Update values (keeps extra vars)"
            echo "  $0 sync-strict  # Strict sync (comments out extra vars)"
            echo "  $0 check        # Check for differences"
            echo "  $0 status       # Show file statistics"
            echo ""
            echo "Notes:"
            echo "  - Variable mappings are applied automatically"
            echo "  - Old variable names are mapped to new standardized names"
            echo "  - See ENV_VARIABLE_MAPPING.md for mapping details"
            echo ""
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Usage: $0 {sync|sync-strict|check|status|help}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi