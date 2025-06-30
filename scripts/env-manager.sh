#!/bin/bash
# ===================================================================
# 🔄 Automagik Suite - Environment Manager (Parallelized Distribution)
# ===================================================================
# Implements the parallelized environment distribution strategy from epic.md
# Part of the existing shell/Makefile infrastructure

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

# Service directories (following existing Makefile patterns)
SERVICES_DIR="$PROJECT_ROOT"
declare -A SERVICE_PATHS=(
    ["am-agents-labs"]="$SERVICES_DIR/am-agents-labs"
    ["automagik-spark"]="$SERVICES_DIR/automagik-spark"
    ["automagik-tools"]="$SERVICES_DIR/automagik-tools"
    ["automagik-omni"]="$SERVICES_DIR/automagik-omni"
    ["automagik-ui"]="$SERVICES_DIR/automagik-ui"
)

# Environment mappings based on epic.md categorization
declare -A ENV_MAPPINGS=(
    # AI Provider Keys (Category 1: Direct copy to all AI services)
    ["OPENAI_API_KEY"]="am-agents-labs,automagik-spark,automagik-tools"
    ["ANTHROPIC_API_KEY"]="am-agents-labs,automagik-spark,automagik-tools"
    ["GEMINI_API_KEY"]="am-agents-labs,automagik-spark,automagik-tools"
    
    # Service-Specific Config (Category 2: Prefixed variables)
    ["AUTOMAGIK_API_.*"]="am-agents-labs"
    ["AUTOMAGIK_SPARK_.*"]="automagik-spark"
    ["AUTOMAGIK_TOOLS_.*"]="automagik-tools"
    ["AUTOMAGIK_OMNI_.*"]="automagik-omni"
    ["AUTOMAGIK_UI_.*"]="automagik-ui"
    
    # Infrastructure URLs (Category 3: Transform to service-specific)
    ["DATABASE_URL"]="am-agents-labs:AUTOMAGIK_DATABASE_URL,automagik-spark:AUTOMAGIK_SPARK_DATABASE_URL"
    ["REDIS_URL"]="automagik-spark:AUTOMAGIK_SPARK_REDIS_URL"
    
    # Shared Secrets (Category 4: Copy to services that need auth)
    ["JWT_SECRET"]="am-agents-labs,automagik-omni"
    ["ENCRYPTION_KEY"]="am-agents-labs,automagik-omni,automagik-ui"
    
    # Integration Keys (Category 5: Service-specific distribution)
    ["EVOLUTION_API_KEY"]="am-agents-labs,automagik-omni"
    ["NOTION_TOKEN"]="am-agents-labs"
    ["DISCORD_BOT_TOKEN"]="am-agents-labs"
    ["AIRTABLE_.*"]="am-agents-labs"
    ["BLACKPEARL_.*"]="am-agents-labs"
    ["LANGFLOW_.*"]="automagik-spark"
)

# Symbols (following existing Makefile patterns)
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

# Load environment variables from main .env
load_main_env() {
    local env_vars=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Handle lines with = (environment variables)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*) ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            
            # Remove quotes if present
            var_value=$(echo "$var_value" | sed 's/^["'"'"']\(.*\)["'"'"']$/\1/')
            
            # Remove inline comments
            var_value=$(echo "$var_value" | sed 's/[[:space:]]*#.*$//')
            
            env_vars+=("$var_name=$var_value")
        fi
    done < "$MAIN_ENV_FILE"
    
    echo "${env_vars[@]}"
}

# Get variables for specific service based on mappings
get_service_vars() {
    local service="$1"
    local -a main_vars=($2)
    local service_vars=()
    
    for var_line in "${main_vars[@]}"; do
        local var_name="${var_line%%=*}"
        local var_value="${var_line#*=}"
        
        # Check each mapping rule
        for pattern in "${!ENV_MAPPINGS[@]}"; do
            local destinations="${ENV_MAPPINGS[$pattern]}"
            
            # Check if variable matches pattern
            if [[ "$var_name" =~ ^${pattern}$ ]]; then
                # Check if service is in destinations
                if [[ "$destinations" =~ (^|,)${service}(,|$|:) ]]; then
                    # Handle transformations (service:new_name format)
                    if [[ "$destinations" =~ ${service}:([^,]+) ]]; then
                        local new_name="${BASH_REMATCH[1]}"
                        service_vars+=("$new_name=$var_value")
                    else
                        service_vars+=("$var_name=$var_value")
                    fi
                fi
            fi
        done
    done
    
    echo "${service_vars[@]}"
}

# Generate .env file for specific service
generate_service_env() {
    local service="$1"
    local service_path="${SERVICE_PATHS[$service]}"
    local -a main_vars=($2)
    
    if [[ ! -d "$service_path" ]]; then
        print_warning "Service directory not found: $service_path"
        return 1
    fi
    
    local service_env_file="$service_path/.env"
    local -a service_vars=($(get_service_vars "$service" "${main_vars[*]}"))
    
    # Create backup if .env exists
    if [[ -f "$service_env_file" ]]; then
        cp "$service_env_file" "$service_env_file.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Generate new .env file
    {
        echo "# ====================================================================="
        echo "# 🤖 $service - Environment Configuration"
        echo "# ====================================================================="
        echo "# Auto-generated by env-manager.sh on $(date)"
        echo "# Source: $MAIN_ENV_FILE"
        echo ""
        
        # Write service-specific variables
        for var_line in "${service_vars[@]}"; do
            echo "$var_line"
        done
        
        echo ""
        echo "# ====================================================================="
        echo "# 📝 Configuration Notes"
        echo "# ====================================================================="
        echo "# This file was automatically generated from the main .env file"
        echo "# To make changes:"
        echo "#   1. Edit the main .env file: $MAIN_ENV_FILE"
        echo "#   2. Run: make env-sync"
        echo "# ====================================================================="
        
    } > "$service_env_file"
    
    print_success "Generated .env for $service (${#service_vars[@]} variables)"
    return 0
}

# Parallelized sync function
sync_all_services() {
    print_status "Starting parallelized environment sync..."
    
    local -a main_vars=($(load_main_env))
    print_info "Loaded ${#main_vars[@]} variables from main .env"
    
    local pids=()
    local temp_dir=$(mktemp -d)
    
    # Start parallel processes for each service
    for service in "${!SERVICE_PATHS[@]}"; do
        (
            generate_service_env "$service" "${main_vars[*]}"
            echo "$?" > "$temp_dir/$service.result"
        ) &
        pids+=($!)
    done
    
    # Wait for all processes to complete
    local success_count=0
    local total_count=${#SERVICE_PATHS[@]}
    
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Check results
    for service in "${!SERVICE_PATHS[@]}"; do
        local result=$(cat "$temp_dir/$service.result" 2>/dev/null || echo "1")
        if [[ "$result" == "0" ]]; then
            ((success_count++))
        else
            print_error "Failed to sync $service"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ "$success_count" == "$total_count" ]]; then
        print_success "Synced environment to all $total_count services"
        return 0
    else
        print_error "Synced $success_count out of $total_count services"
        return 1
    fi
}

# Check environment differences
check_env_status() {
    print_status "Checking environment status..."
    
    if ! check_main_env; then
        return 1
    fi
    
    local -a main_vars=($(load_main_env))
    local differences_found=false
    
    for service in "${!SERVICE_PATHS[@]}"; do
        local service_path="${SERVICE_PATHS[$service]}"
        local service_env_file="$service_path/.env"
        
        if [[ ! -f "$service_env_file" ]]; then
            print_warning "$service: .env file missing"
            differences_found=true
            continue
        fi
        
        # Check if service env is older than main env
        if [[ "$service_env_file" -ot "$MAIN_ENV_FILE" ]]; then
            print_warning "$service: .env file is older than main .env"
            differences_found=true
        else
            print_success "$service: .env file is up to date"
        fi
    done
    
    if [[ "$differences_found" == "true" ]]; then
        print_info "Run 'make env-sync' to update service .env files"
        return 1
    else
        print_success "All service .env files are up to date"
        return 0
    fi
}

# Validate environment configuration
validate_env() {
    print_status "Validating environment configuration..."
    
    if ! check_main_env; then
        return 1
    fi
    
    local errors=0
    local -a main_vars=($(load_main_env))
    
    # Check for required variables
    local required_vars=("OPENAI_API_KEY" "AUTOMAGIK_API_KEY")
    
    for var in "${required_vars[@]}"; do
        local found=false
        for var_line in "${main_vars[@]}"; do
            if [[ "$var_line" =~ ^${var}= ]]; then
                local value="${var_line#*=}"
                if [[ -n "$value" && "$value" != "your-key-here" && "$value" != "sk-your-" ]]; then
                    print_success "$var: configured"
                    found=true
                else
                    print_error "$var: missing or placeholder value"
                    ((errors++))
                fi
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            print_error "$var: not found in .env"
            ((errors++))
        fi
    done
    
    if [[ "$errors" == "0" ]]; then
        print_success "Environment validation passed"
        return 0
    else
        print_error "Environment validation failed with $errors error(s)"
        return 1
    fi
}

# Show environment status
show_env_status() {
    print_status "Environment Status Report"
    echo ""
    
    # Main .env status
    if [[ -f "$MAIN_ENV_FILE" ]]; then
        local main_vars_count=$(load_main_env | wc -w)
        print_success "Main .env: $main_vars_count variables loaded"
    else
        print_error "Main .env: not found"
    fi
    
    echo ""
    print_info "Service .env files:"
    
    for service in "${!SERVICE_PATHS[@]}"; do
        local service_path="${SERVICE_PATHS[$service]}"
        local service_env_file="$service_path/.env"
        
        if [[ -f "$service_env_file" ]]; then
            local vars_count=$(grep -c "^[A-Za-z_].*=" "$service_env_file" 2>/dev/null || echo "0")
            local age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$service_env_file" 2>/dev/null || stat -c "%y" "$service_env_file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
            print_success "$service: $vars_count variables (modified: $age)"
        else
            print_warning "$service: .env not found"
        fi
    done
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "sync")
            if check_main_env; then
                sync_all_services
            fi
            ;;
        "check")
            check_env_status
            ;;
        "validate")
            validate_env
            ;;
        "status")
            show_env_status
            ;;
        "help"|"-h"|"--help")
            echo "Automagik Suite Environment Manager"
            echo ""
            echo "Usage: $0 COMMAND"
            echo ""
            echo "Commands:"
            echo "  sync      Sync main .env to all service .env files (parallelized)"
            echo "  check     Check if service .env files need updates"
            echo "  validate  Validate environment configuration"
            echo "  status    Show detailed environment status"
            echo "  help      Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 sync      # Distribute main .env to all services"
            echo "  $0 check     # Check if sync is needed"
            echo "  $0 validate  # Validate configuration"
            echo ""
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Usage: $0 {sync|check|validate|status|help}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi