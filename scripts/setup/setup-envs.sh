#!/bin/bash

# ===================================================================
# 🔧 Environment Generation and Configuration
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Repository paths
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Repository environment configurations
declare -A REPO_CONFIGS=(
    ["am-agents-labs"]="PostgreSQL mode with agents configuration"
    ["automagik-spark"]="Workflow engine with PostgreSQL and Redis"
    ["automagik-tools"]="MCP tools with API configurations"
    ["automagik-evolution"]="WhatsApp integration with Evolution API"
    ["automagik-omni"]="Multi-tenant hub configuration"
    ["automagik-ui-v2"]="Frontend application configuration"
)

# Variables to exclude (Neo4j/Graphiti related)
EXCLUDED_VARIABLES=(
    "NEO4J_USERNAME"
    "NEO4J_PASSWORD" 
    "NEO4J_URI"
    "NEO4J_DATABASE"
    "GRAPHITI_USERNAME"
    "GRAPHITI_PASSWORD"
    "GRAPHITI_URI"
    "GRAPHITI_DATABASE"
    "GRAPH_DATABASE_URL"
    "GRAPH_DB_USERNAME"
    "GRAPH_DB_PASSWORD"
)

# Load collected API keys
load_api_keys() {
    log_info "Loading collected API keys..."
    
    if [ -n "$AUTOMAGIK_KEYS_FILE" ] && [ -f "$AUTOMAGIK_KEYS_FILE" ]; then
        log_success "Found API keys file: $AUTOMAGIK_KEYS_FILE"
        source "$AUTOMAGIK_KEYS_FILE"
        return 0
    fi
    
    # Try to find keys in collect-keys output
    local keys_file="/tmp/automagik-keys.env"
    if [ -f "$keys_file" ]; then
        log_success "Found API keys file: $keys_file"
        source "$keys_file"
        export AUTOMAGIK_KEYS_FILE="$keys_file"
        return 0
    fi
    
    log_warning "No API keys file found - will use example values"
    return 1
}

# Check if variable should be excluded
is_excluded_variable() {
    local var_name="$1"
    
    for excluded in "${EXCLUDED_VARIABLES[@]}"; do
        if [ "$var_name" = "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

# Generate database configuration
generate_database_config() {
    local repo_name="$1"
    local config=""
    
    case "$repo_name" in
        "am-agents-labs")
            config+="# Database Configuration (PostgreSQL mode)\n"
            config+="DATABASE_URL=\"postgresql://postgres:postgres@localhost:5401/am_agents_labs\"\n"
            config+="DB_HOST=\"localhost\"\n"
            config+="DB_PORT=\"5401\"\n"
            config+="DB_NAME=\"am_agents_labs\"\n"
            config+="DB_USER=\"postgres\"\n"
            config+="DB_PASSWORD=\"postgres\"\n"
            config+="DB_TYPE=\"postgresql\"\n"
            ;;
        "automagik-spark")
            config+="# Database Configuration\n"
            config+="DATABASE_URL=\"postgresql://postgres:postgres@localhost:5402/automagik_spark\"\n"
            config+="DB_HOST=\"localhost\"\n"
            config+="DB_PORT=\"5402\"\n"
            config+="DB_NAME=\"automagik_spark\"\n"
            config+="DB_USER=\"postgres\"\n"
            config+="DB_PASSWORD=\"postgres\"\n"
            config+="\n"
            config+="# Redis Configuration\n"
            config+="REDIS_URL=\"redis://localhost:5412\"\n"
            config+="REDIS_HOST=\"localhost\"\n"
            config+="REDIS_PORT=\"5412\"\n"
            config+="\n"
            config+="# Celery Configuration\n"
            config+="CELERY_BROKER_URL=\"redis://localhost:5412\"\n"
            config+="CELERY_RESULT_BACKEND=\"redis://localhost:5412\"\n"
            ;;
        "automagik-evolution")
            config+="# Database Configuration\n"
            config+="DATABASE_URL=\"postgresql://postgres:postgres@localhost:5403/evolution_api\"\n"
            config+="DB_HOST=\"localhost\"\n"
            config+="DB_PORT=\"5403\"\n"
            config+="DB_NAME=\"evolution_api\"\n"
            config+="DB_USER=\"postgres\"\n"
            config+="DB_PASSWORD=\"postgres\"\n"
            config+="\n"
            config+="# Redis Configuration\n"
            config+="REDIS_URL=\"redis://localhost:5413\"\n"
            config+="REDIS_HOST=\"localhost\"\n"
            config+="REDIS_PORT=\"5413\"\n"
            config+="\n"
            config+="# RabbitMQ Configuration\n"
            config+="RABBITMQ_URL=\"amqp://rabbitmq:rabbitmq@localhost:5431\"\n"
            config+="RABBITMQ_HOST=\"localhost\"\n"
            config+="RABBITMQ_PORT=\"5431\"\n"
            config+="RABBITMQ_USER=\"rabbitmq\"\n"
            config+="RABBITMQ_PASSWORD=\"rabbitmq\"\n"
            ;;
    esac
    
    echo -e "$config"
}

# Generate port configuration
generate_port_config() {
    local repo_name="$1"
    local config=""
    
    case "$repo_name" in
        "am-agents-labs")
            config+="# Application Configuration\n"
            config+="PORT=\"8881\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="APP_URL=\"http://localhost:8881\"\n"
            ;;
        "automagik-spark")
            config+="# Application Configuration\n"
            config+="PORT=\"8883\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="APP_URL=\"http://localhost:8883\"\n"
            ;;
        "automagik-tools")
            config+="# Application Configuration\n"
            config+="SSE_PORT=\"8884\"\n"
            config+="HTTP_PORT=\"8885\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            ;;
        "automagik-evolution")
            config+="# Application Configuration\n"
            config+="PORT=\"9000\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="SERVER_URL=\"http://localhost:9000\"\n"
            config+="EVOLUTION_API_URL=\"http://localhost:9000\"\n"
            ;;
        "automagik-omni")
            config+="# Application Configuration\n"
            config+="PORT=\"8882\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="APP_URL=\"http://localhost:8882\"\n"
            ;;
        "automagik-ui-v2")
            config+="# Application Configuration\n"
            config+="PORT=\"8888\"\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="NEXT_PUBLIC_API_URL=\"http://localhost:8881\"\n"
            config+="NEXT_PUBLIC_SPARK_URL=\"http://localhost:8883\"\n"
            config+="NEXT_PUBLIC_OMNI_URL=\"http://localhost:8882\"\n"
            config+="NEXT_PUBLIC_TOOLS_SSE_URL=\"http://localhost:8884\"\n"
            config+="NEXT_PUBLIC_TOOLS_HTTP_URL=\"http://localhost:8885\"\n"
            config+="NEXT_PUBLIC_EVOLUTION_URL=\"http://localhost:9000\"\n"
            ;;
    esac
    
    echo -e "$config"
}

# Generate Evolution API specific configuration
generate_evolution_config() {
    local config=""
    
    config+="# Evolution API Configuration\n"
    config+="EVOLUTION_API_KEY=\"${EVOLUTION_API_KEY:-evolution_api_key_here}\"\n"
    config+="AUTHENTICATION_TYPE=\"apikey\"\n"
    config+="AUTHENTICATION_API_KEY=\"${EVOLUTION_API_KEY:-evolution_api_key_here}\"\n"
    config+="AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=\"true\"\n"
    config+="\n"
    config+="# Webhook Configuration\n"
    config+="WEBHOOK_GLOBAL_URL=\"${EVOLUTION_WEBHOOK_URL:-}\"\n"
    config+="WEBHOOK_GLOBAL_ENABLED=\"false\"\n"
    config+="WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=\"false\"\n"
    config+="\n"
    config+="# Instance Configuration\n"
    config+="CONFIG_SESSION_PHONE_CLIENT=\"Automagik Evolution\"\n"
    config+="CONFIG_SESSION_PHONE_NAME=\"Chrome\"\n"
    config+="CONFIG_SESSION_PHONE_VERSION=\"4.0.0\"\n"
    config+="\n"
    config+="# QR Code Configuration\n"
    config+="QRCODE_LIMIT=\"30\"\n"
    config+="QRCODE_COLOR=\"#198754\"\n"
    config+="\n"
    config+="# File Storage (Base64 mode - no MinIO)\n"
    config+="STORE_MESSAGE_UP=\"true\"\n"
    config+="STORE_CONTACTS=\"true\"\n"
    config+="STORE_CHATS=\"true\"\n"
    config+="CLEAN_STORE_CLEANING_INTERVAL=\"7200\"\n"
    config+="CLEAN_STORE_MESSAGES=\"true\"\n"
    config+="CLEAN_STORE_MESSAGE_UP=\"true\"\n"
    config+="CLEAN_STORE_CONTACTS=\"true\"\n"
    config+="CLEAN_STORE_CHATS=\"true\"\n"
    config+="\n"
    config+="# Log Configuration\n"
    config+="LOG_LEVEL=\"ERROR\"\n"
    config+="LOG_COLOR=\"true\"\n"
    config+="LOG_BAILEYS=\"error\"\n"
    
    echo -e "$config"
}

# Process .env.example file and generate .env
process_env_file() {
    local repo_path="$1"
    local repo_name="$(basename "$repo_path")"
    local env_example="$repo_path/.env.example"
    local env_file="$repo_path/.env"
    
    log_info "Processing $repo_name environment..."
    
    if [ ! -f "$env_example" ]; then
        log_warning "No .env.example found in $repo_name"
        return 1
    fi
    
    # Start with header
    {
        echo "# Automagik Suite Environment Configuration"
        echo "# Repository: $repo_name"
        echo "# Generated: $(date)"
        echo "# Description: ${REPO_CONFIGS[$repo_name]}"
        echo ""
    } > "$env_file"
    
    # Add port configuration
    generate_port_config "$repo_name" >> "$env_file"
    echo "" >> "$env_file"
    
    # Add database configuration
    generate_database_config "$repo_name" >> "$env_file"
    echo "" >> "$env_file"
    
    # Add Evolution-specific configuration
    if [ "$repo_name" = "automagik-evolution" ]; then
        generate_evolution_config >> "$env_file"
        echo "" >> "$env_file"
    fi
    
    # Process .env.example line by line
    echo "# Variables from .env.example" >> "$env_file"
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$env_file"
            continue
        fi
        
        # Extract variable name
        var_name=$(echo "$line" | cut -d'=' -f1)
        
        # Skip excluded variables
        if is_excluded_variable "$var_name"; then
            echo "# $line  # Excluded: Neo4j/Graphiti not used in this deployment" >> "$env_file"
            continue
        fi
        
        # Check if we have a collected value for this variable
        local collected_value=""
        case "$var_name" in
            "OPENAI_API_KEY")
                collected_value="$OPENAI_API_KEY"
                ;;
            "OPENAI_ORG_ID")
                collected_value="$OPENAI_ORG_ID"
                ;;
            "ANTHROPIC_API_KEY")
                collected_value="$ANTHROPIC_API_KEY"
                ;;
            "GOOGLE_API_KEY")
                collected_value="$GOOGLE_API_KEY"
                ;;
            "GOOGLE_CSE_ID")
                collected_value="$GOOGLE_CSE_ID"
                ;;
            "GROQ_API_KEY")
                collected_value="$GROQ_API_KEY"
                ;;
            "TOGETHER_API_KEY")
                collected_value="$TOGETHER_API_KEY"
                ;;
            "PERPLEXITY_API_KEY")
                collected_value="$PERPLEXITY_API_KEY"
                ;;
            "SERPER_API_KEY")
                collected_value="$SERPER_API_KEY"
                ;;
            "TAVILY_API_KEY")
                collected_value="$TAVILY_API_KEY"
                ;;
            "BROWSERLESS_TOKEN")
                collected_value="$BROWSERLESS_TOKEN"
                ;;
            "EVOLUTION_API_KEY")
                collected_value="$EVOLUTION_API_KEY"
                ;;
            "JWT_SECRET")
                collected_value="$JWT_SECRET"
                ;;
            "ENCRYPTION_KEY")
                collected_value="$ENCRYPTION_KEY"
                ;;
        esac
        
        # Use collected value if available, otherwise keep example
        if [ -n "$collected_value" ]; then
            echo "$var_name=\"$collected_value\"" >> "$env_file"
        else
            echo "$line" >> "$env_file"
        fi
        
    done < "$env_example"
    
    log_success "Generated .env for $repo_name"
    return 0
}

# Setup environment files for all repositories
setup_all_environments() {
    log_section "Environment File Generation"
    
    # Load API keys first
    load_api_keys
    
    local processed_repos=()
    local failed_repos=()
    
    # Process each repository
    for repo_name in "${!REPO_CONFIGS[@]}"; do
        local repo_path="$BASE_DIR/$repo_name"
        
        if [ ! -d "$repo_path" ]; then
            log_warning "Repository $repo_name not found at $repo_path"
            failed_repos+=("$repo_name (not found)")
            continue
        fi
        
        if process_env_file "$repo_path"; then
            processed_repos+=("$repo_name")
        else
            failed_repos+=("$repo_name")
        fi
    done
    
    # Report results
    echo ""
    if [ ${#processed_repos[@]} -gt 0 ]; then
        log_success "Processed environments for: ${processed_repos[*]}"
    fi
    
    if [ ${#failed_repos[@]} -gt 0 ]; then
        log_warning "Failed to process: ${failed_repos[*]}"
    fi
    
    return $([ ${#failed_repos[@]} -eq 0 ])
}

# Verify environment files
verify_environments() {
    log_section "Environment Verification"
    
    local all_valid=true
    
    print_table_header
    
    for repo_name in "${!REPO_CONFIGS[@]}"; do
        local repo_path="$BASE_DIR/$repo_name"
        local env_file="$repo_path/.env"
        
        local status size vars
        
        if [ ! -f "$env_file" ]; then
            status="❌ Missing"
            size="-"
            vars="0"
            all_valid=false
        else
            local file_size=$(wc -c < "$env_file" 2>/dev/null || echo "0")
            local var_count=$(grep -c "^[A-Z].*=" "$env_file" 2>/dev/null || echo "0")
            
            if [ "$file_size" -gt 100 ] && [ "$var_count" -gt 5 ]; then
                status="✅ Valid"
                size="${file_size}B"
                vars="$var_count"
            else
                status="⚠️  Incomplete"
                size="${file_size}B"
                vars="$var_count"
                all_valid=false
            fi
        fi
        
        print_table_row "$repo_name" "$status" "$size" "$vars variables"
    done
    
    echo ""
    
    if [ "$all_valid" = true ]; then
        log_success "All environment files are valid"
        return 0
    else
        log_warning "Some environment files need attention"
        return 1
    fi
}

# Show environment summary
show_environment_summary() {
    log_section "Environment Configuration Summary"
    
    local total_vars=0
    local configured_vars=0
    
    for repo_name in "${!REPO_CONFIGS[@]}"; do
        local repo_path="$BASE_DIR/$repo_name"
        local env_file="$repo_path/.env"
        
        if [ -f "$env_file" ]; then
            echo -e "${CYAN}$repo_name:${NC}"
            echo "  ${REPO_CONFIGS[$repo_name]}"
            
            # Count variables
            local vars=$(grep -c "^[A-Z].*=" "$env_file" 2>/dev/null || echo "0")
            local configured=$(grep -c "^[A-Z].*=.*[^[:space:]]" "$env_file" 2>/dev/null || echo "0")
            
            echo "  Variables: $configured/$vars configured"
            echo ""
            
            total_vars=$((total_vars + vars))
            configured_vars=$((configured_vars + configured))
        fi
    done
    
    log_info "Total: $configured_vars/$total_vars variables configured across all services"
    
    # Show excluded variables info
    echo ""
    echo -e "${YELLOW}Excluded Variables (Neo4j/Graphiti):${NC}"
    for excluded in "${EXCLUDED_VARIABLES[@]}"; do
        echo "  • $excluded"
    done
    echo ""
    log_info "These variables are excluded as we're using PostgreSQL instead of Neo4j"
}

# Clean environment files
clean_environments() {
    log_section "Environment Cleanup"
    
    log_warning "This will remove all generated .env files"
    
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
    
    local removed_count=0
    
    for repo_name in "${!REPO_CONFIGS[@]}"; do
        local repo_path="$BASE_DIR/$repo_name"
        local env_file="$repo_path/.env"
        
        if [ -f "$env_file" ]; then
            log_info "Removing $repo_name/.env"
            if rm "$env_file"; then
                ((removed_count++))
            else
                log_error "Failed to remove $env_file"
            fi
        fi
    done
    
    log_success "Removed $removed_count environment files"
}

# Main function when script is run directly
main() {
    case "${1:-setup}" in
        "setup")
            setup_all_environments
            verify_environments
            show_environment_summary
            ;;
        "verify")
            verify_environments
            ;;
        "show")
            show_environment_summary
            ;;
        "clean")
            clean_environments
            ;;
        *)
            echo "Usage: $0 {setup|verify|show|clean}"
            echo "  setup   - Generate all environment files (default)"
            echo "  verify  - Verify existing environment files"
            echo "  show    - Show environment configuration summary"
            echo "  clean   - Remove all generated environment files"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi