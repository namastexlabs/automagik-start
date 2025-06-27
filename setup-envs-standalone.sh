#!/bin/bash

# ===================================================================
# 🔧 Automagik Environment Setup - Standalone Version
# ===================================================================
# This script can be curled and run from any directory containing 
# automagik repositories to generate environment files
# 
# Usage: curl -fsSL https://raw.githubusercontent.com/namastexlabs/automagik-start/main/setup-envs-standalone.sh | bash
# ===================================================================

set -euo pipefail

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}ℹ️${NC} $1"; }
log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

# Repository environment configurations
declare -A REPO_CONFIGS=(
    ["am-agents-labs"]="PostgreSQL mode with agents configuration"
    ["automagik-spark"]="Workflow engine with PostgreSQL and Redis"
    ["automagik-tools"]="MCP tools with API configurations"
    ["automagik-evolution"]="WhatsApp integration with Evolution API"
    ["automagik-omni"]="Multi-tenant hub configuration"
    ["automagik-ui-v2"]="Frontend application configuration"
)

# Load main .env file if available
load_main_env() {
    if [ -f "./.env" ]; then
        log_success "Found main .env file: ./.env"
        set -a  # Automatically export all variables
        source "./.env"
        set +a  # Turn off automatic export
        return 0
    fi
    
    log_warning "No main .env file found - will use example values"
    return 1
}

# Get mapped value from main .env based on project needs
get_mapped_value() {
    local var_name="$1"
    local repo_name="$2"
    local value=""
    
    # Direct mapping from loaded environment variables (only if set)
    case "$var_name" in
        # AI Service Keys
        "OPENAI_API_KEY") value="${OPENAI_API_KEY:-}" ;;
        "OPENAI_ORG_ID") value="${OPENAI_ORG_ID:-}" ;;
        "ANTHROPIC_API_KEY") value="${ANTHROPIC_API_KEY:-}" ;;
        "GOOGLE_API_KEY") value="${GOOGLE_API_KEY:-}" ;;
        "GOOGLE_CSE_ID") value="${GOOGLE_CSE_ID:-}" ;;
        "GEMINI_API_KEY") value="${GEMINI_API_KEY:-}" ;;
        "GROQ_API_KEY") value="${GROQ_API_KEY:-}" ;;
        "TOGETHER_API_KEY") value="${TOGETHER_API_KEY:-}" ;;
        "PERPLEXITY_API_KEY") value="${PERPLEXITY_API_KEY:-}" ;;
        
        # Security Keys
        "JWT_SECRET") value="${JWT_SECRET:-}" ;;
        "ENCRYPTION_KEY") value="${ENCRYPTION_KEY:-}" ;;
        "AM_API_KEY") value="${AM_API_KEY:-}" ;;
        "API_KEY") value="${API_KEY:-}" ;;
        "AUTOMAGIK_API_KEY") value="${AUTOMAGIK_API_KEY:-}" ;;
        
        # Communication Services
        "EVOLUTION_API_KEY") value="${EVOLUTION_API_KEY:-}" ;;
        "EVOLUTION_WEBHOOK_URL") value="${EVOLUTION_WEBHOOK_URL:-}" ;;
        "DISCORD_BOT_TOKEN") value="${DISCORD_BOT_TOKEN:-}" ;;
        
        # Database URLs (Docker-internal)
        "DATABASE_URL")
            case "$repo_name" in
                "am-agents-labs") value="postgresql://postgres:postgres@am-agents-labs-postgres:5432/am_agents_labs" ;;
                "automagik-spark") value="postgresql+asyncpg://automagik:automagik@automagik-spark-postgres:5432/automagik" ;;
            esac ;;
        "DATABASE_CONNECTION_URI")
            case "$repo_name" in
                "automagik-evolution") value="postgresql://postgres:postgres@automagik-evolution-postgres:5432/evolution_api" ;;
            esac ;;
        
        # Redis URLs (Docker-internal)
        "CACHE_REDIS_URI")
            case "$repo_name" in
                "automagik-evolution") value="redis://automagik-evolution-redis:6379" ;;
            esac ;;
        
        # Celery Configuration
        "CELERY_BROKER_URL")
            case "$repo_name" in
                "automagik-spark") value="redis://automagik-spark-redis:6379/0" ;;
            esac ;;
        "CELERY_RESULT_BACKEND")
            case "$repo_name" in
                "automagik-spark") value="redis://automagik-spark-redis:6379/0" ;;
            esac ;;
        
        # Service URLs
        "AUTOMAGIK_BASE_URL")
            case "$repo_name" in
                "automagik-tools") value="http://automagik-spark-api:8883" ;;
            esac ;;
        "AGENT_API_URL")
            case "$repo_name" in
                "automagik-omni") value="http://am-agents-labs:8881" ;;
            esac ;;
        "AGENT_API_KEY")
            case "$repo_name" in
                "automagik-omni") value="${AM_API_KEY:-namastex888}" ;;
            esac ;;
        
        # Authentication for Evolution API
        "AUTHENTICATION_API_KEY")
            case "$repo_name" in
                "automagik-evolution") value="${EVOLUTION_API_KEY:-namastex888}" ;;
            esac ;;
        
    esac
    
    echo "$value"
}

# Generate port and database configuration
generate_config() {
    local repo_name="$1"
    local config=""
    
    case "$repo_name" in
        "am-agents-labs")
            config+="# Application Configuration\n"
            config+="AM_PORT=\"8881\"\n"
            config+="AM_HOST=\"0.0.0.0\"\n"
            config+="DATABASE_URL=\"postgresql://postgres:postgres@am-agents-labs-postgres:5432/am_agents_labs\"\n"
            ;;
        "automagik-spark")
            config+="# Application Configuration\n"
            config+="AUTOMAGIK_API_PORT=\"8883\"\n"
            config+="AUTOMAGIK_API_HOST=\"0.0.0.0\"\n"
            config+="DATABASE_URL=\"postgresql+asyncpg://automagik:automagik@automagik-spark-postgres:5432/automagik\"\n"
            config+="CELERY_BROKER_URL=\"redis://automagik-spark-redis:6379/0\"\n"
            config+="CELERY_RESULT_BACKEND=\"redis://automagik-spark-redis:6379/0\"\n"
            ;;
        "automagik-tools")
            config+="# Application Configuration\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="PORT=\"8000\"\n"
            config+="AUTOMAGIK_BASE_URL=\"http://automagik-spark-api:8883\"\n"
            ;;
        "automagik-evolution")
            config+="# Application Configuration\n"
            config+="SERVER_PORT=\"9000\"\n"
            config+="DATABASE_CONNECTION_URI=\"postgresql://postgres:postgres@automagik-evolution-postgres:5432/evolution_api\"\n"
            config+="CACHE_REDIS_URI=\"redis://automagik-evolution-redis:6379\"\n"
            config+="RABBITMQ_URI=\"amqp://rabbitmq:rabbitmq@automagik-evolution-rabbitmq:5672\"\n"
            config+="AUTHENTICATION_API_KEY=\"${EVOLUTION_API_KEY:-namastex888}\"\n"
            ;;
        "automagik-omni")
            config+="# Application Configuration\n"
            config+="API_HOST=\"0.0.0.0\"\n"
            config+="API_PORT=\"8882\"\n"
            config+="AGENT_API_URL=\"http://am-agents-labs:8881\"\n"
            config+="AGENT_API_KEY=\"${AM_API_KEY:-namastex888}\"\n"
            ;;
        "automagik-ui-v2")
            config+="# Application Configuration\n"
            config+="PORT=\"8888\"\n"
            config+="NODE_ENV=\"production\"\n"
            config+="NEXT_PUBLIC_API_URL=\"http://localhost:8881\"\n"
            config+="NEXT_PUBLIC_SPARK_URL=\"http://localhost:8883\"\n"
            config+="NEXT_PUBLIC_OMNI_URL=\"http://localhost:8882\"\n"
            ;;
    esac
    
    echo -e "$config"
}

# Process environment file for a repository
process_env_file() {
    local repo_name="$1"
    local env_example=""
    local env_file=""
    
    # Skip if repository directory doesn't exist
    if [ ! -d "./$repo_name" ]; then
        return 1
    fi
    
    log_info "Processing $repo_name environment..."
    
    # Determine the correct env example file and target file
    case "$repo_name" in
        "automagik-ui-v2")
            env_example="./$repo_name/.env.local.example"
            env_file="./$repo_name/.env.local"
            ;;
        "automagik-omni")
            env_example="./$repo_name/.env-example"
            env_file="./$repo_name/.env"
            ;;
        *)
            env_example="./$repo_name/.env.example"
            env_file="./$repo_name/.env"
            ;;
    esac
    
    if [ ! -f "$env_example" ]; then
        log_warning "No env example file found in $repo_name"
        return 1
    fi
    
    # Create environment file
    {
        echo "# Automagik Suite Environment Configuration"
        echo "# Repository: $repo_name"
        echo "# Generated: $(date)"
        echo "# Description: ${REPO_CONFIGS[$repo_name]}"
        echo ""
        
        # Add generated configuration
        generate_config "$repo_name"
        echo ""
        
        echo "# Variables from .env.example"
        
        # Process .env.example line by line
        while IFS= read -r line; do
            # Skip empty lines and comments
            if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
                echo "$line"
                continue
            fi
            
            # Extract variable name
            var_name=$(echo "$line" | cut -d'=' -f1)
            
            # Get mapped value from main .env
            local mapped_value=$(get_mapped_value "$var_name" "$repo_name")
            
            # Use mapped value if available, otherwise keep example
            if [ -n "$mapped_value" ]; then
                echo "$var_name=\"$mapped_value\""
            else
                echo "$line"
            fi
            
        done < "$env_example"
        
    } > "$env_file"
    
    log_success "Generated environment file for $repo_name"
    return 0
}

# Main function
main() {
    echo -e "${CYAN}Automagik Environment Setup${NC}"
    echo -e "${CYAN}===========================${NC}"
    
    # Load main .env if available (ignore exit code)
    load_main_env || true
    
    local processed_repos=()
    local failed_repos=()
    
    # Process each repository that exists
    for repo_name in "${!REPO_CONFIGS[@]}"; do
        if process_env_file "$repo_name"; then
            processed_repos+=("$repo_name")
        else
            if [ -d "./$repo_name" ]; then
                failed_repos+=("$repo_name")
            fi
        fi
    done
    
    # Report results
    echo ""
    if [ ${#processed_repos[@]} -gt 0 ]; then
        log_success "Generated environment files for: ${processed_repos[*]}"
    fi
    
    if [ ${#failed_repos[@]} -gt 0 ]; then
        log_warning "Failed to process: ${failed_repos[*]}"
    fi
    
    if [ ${#processed_repos[@]} -eq 0 ] && [ ${#failed_repos[@]} -eq 0 ]; then
        log_error "No Automagik repositories found in current directory"
        echo "Make sure you're running this script from a directory containing cloned Automagik repositories"
        exit 1
    fi
    
    log_success "Environment setup complete!"
}

# Run main function
main "$@"