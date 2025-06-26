#!/bin/bash

# ===================================================================
# 🔧 Environment Generation and Configuration with Complete Mapping
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

# Load collected API keys
load_api_keys() {
    log_info "Loading collected API keys..."
    
    # First try main .env file
    local main_env_file="$BASE_DIR/.env"
    if [ -f "$main_env_file" ]; then
        log_success "Found main .env file: $main_env_file"
        set -a  # Automatically export all variables
        source "$main_env_file"
        set +a  # Turn off automatic export
        return 0
    fi
    
    # Fallback to temporary keys file
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

# Get mapped value from main .env based on project needs
get_mapped_value() {
    local var_name="$1"
    local repo_name="$2"
    local value=""
    
    # Direct mapping from loaded environment variables
    case "$var_name" in
        # AI Service Keys
        "OPENAI_API_KEY") value="$OPENAI_API_KEY" ;;
        "OPENAI_ORG_ID") value="$OPENAI_ORG_ID" ;;
        "ANTHROPIC_API_KEY") value="$ANTHROPIC_API_KEY" ;;
        "GOOGLE_API_KEY") value="$GOOGLE_API_KEY" ;;
        "GOOGLE_CSE_ID") value="$GOOGLE_CSE_ID" ;;
        "GEMINI_API_KEY") value="$GEMINI_API_KEY" ;;
        "GROQ_API_KEY") value="$GROQ_API_KEY" ;;
        "TOGETHER_API_KEY") value="$TOGETHER_API_KEY" ;;
        "PERPLEXITY_API_KEY") value="$PERPLEXITY_API_KEY" ;;
        
        # Search & Web Services
        "SERPER_API_KEY") value="$SERPER_API_KEY" ;;
        "TAVILY_API_KEY") value="$TAVILY_API_KEY" ;;
        "BROWSERLESS_TOKEN") value="$BROWSERLESS_TOKEN" ;;
        
        # Communication Services
        "EVOLUTION_API_KEY") value="$EVOLUTION_API_KEY" ;;
        "EVOLUTION_WEBHOOK_URL") value="$EVOLUTION_WEBHOOK_URL" ;;
        "EVOLUTION_INSTANCE") value="$EVOLUTION_INSTANCE" ;;
        "DEFAULT_EVOLUTION_INSTANCE") value="$DEFAULT_EVOLUTION_INSTANCE" ;;
        "DEFAULT_WHATSAPP_NUMBER") value="$DEFAULT_WHATSAPP_NUMBER" ;;
        "DISCORD_BOT_TOKEN") value="$DISCORD_BOT_TOKEN" ;;
        "MEETING_BOT_URL") value="$MEETING_BOT_URL" ;;
        
        # Security Keys
        "JWT_SECRET") value="$JWT_SECRET" ;;
        "ENCRYPTION_KEY") value="$ENCRYPTION_KEY" ;;
        "AM_API_KEY") value="$AM_API_KEY" ;;
        "API_KEY") value="$API_KEY" ;;
        "AUTOMAGIK_API_KEY") value="$AUTOMAGIK_API_KEY" ;;
        "TEST_API_KEY") value="$TEST_API_KEY" ;;
        "AUTOMAGIK_ENCRYPTION_KEY") value="$AUTOMAGIK_ENCRYPTION_KEY" ;;
        
        # External Services
        "NOTION_TOKEN") value="$NOTION_TOKEN" ;;
        "AIRTABLE_TOKEN") value="$AIRTABLE_TOKEN" ;;
        "AIRTABLE_DEFAULT_BASE_ID") value="$AIRTABLE_DEFAULT_BASE_ID" ;;
        "BLACKPEARL_TOKEN") value="$BLACKPEARL_TOKEN" ;;
        "BLACKPEARL_API_URL") value="$BLACKPEARL_API_URL" ;;
        "BLACKPEARL_DB_URI") value="$BLACKPEARL_DB_URI" ;;
        "OMIE_TOKEN") value="$OMIE_TOKEN" ;;
        "GOOGLE_DRIVE_TOKEN") value="$GOOGLE_DRIVE_TOKEN" ;;
        "FLASHED_API_KEY") value="$FLASHED_API_KEY" ;;
        "FLASHED_API_URL") value="$FLASHED_API_URL" ;;
        "SUPABASE_URL") value="$SUPABASE_URL" ;;
        "SUPABASE_SERVICE_ROLE_KEY") value="$SUPABASE_SERVICE_ROLE_KEY" ;;
        "FIGMA_API_KEY") value="$FIGMA_API_KEY" ;;
        
        # Monitoring
        "LOGFIRE_TOKEN") value="$LOGFIRE_TOKEN" ;;
        "LOGFIRE_IGNORE_NO_CONFIG") value="$LOGFIRE_IGNORE_NO_CONFIG" ;;
        
        # Claude Code
        "CLAUDE_LOCAL_WORKSPACE") value="$CLAUDE_LOCAL_WORKSPACE" ;;
        "CLAUDE_LOCAL_CLEANUP") value="$CLAUDE_LOCAL_CLEANUP" ;;
        "CLAUDE_CODE_API_URL") value="$CLAUDE_CODE_API_URL" ;;
        
        # Application Settings (project-specific)
        "AM_ENV") 
            case "$repo_name" in
                "am-agents-labs") value="$AM_ENV" ;;
            esac ;;
        "AUTOMAGIK_ENV")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_ENV" ;;
            esac ;;
        "AM_HOST")
            case "$repo_name" in
                "am-agents-labs") value="$AM_HOST" ;;
            esac ;;
        "AM_PORT")
            case "$repo_name" in
                "am-agents-labs") value="$AM_PORT" ;;
            esac ;;
        "AM_TIMEZONE")
            case "$repo_name" in
                "am-agents-labs") value="$AM_TIMEZONE" ;;
            esac ;;
        "AUTOMAGIK_TIMEZONE")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_TIMEZONE" ;;
            esac ;;
        
        # Logging Configuration
        "AM_LOG_LEVEL")
            case "$repo_name" in
                "am-agents-labs") value="$AM_LOG_LEVEL" ;;
            esac ;;
        "AM_VERBOSE_LOGGING")
            case "$repo_name" in
                "am-agents-labs") value="$AM_VERBOSE_LOGGING" ;;
            esac ;;
        "AM_LOG_TO_FILE")
            case "$repo_name" in
                "am-agents-labs") value="$AM_LOG_TO_FILE" ;;
            esac ;;
        "AM_LOG_FILE_PATH")
            case "$repo_name" in
                "am-agents-labs") value="$AM_LOG_FILE_PATH" ;;
            esac ;;
        "AUTOMAGIK_LOG_LEVEL")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_LOG_LEVEL" ;;
            esac ;;
        "AUTOMAGIK_WORKER_LOG")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_WORKER_LOG" ;;
            esac ;;
        "LOG_LEVEL")
            case "$repo_name" in
                "automagik-evolution") value="info" ;;
            esac ;;
        
        # Performance Settings
        "LLM_MAX_CONCURRENT_REQUESTS")
            case "$repo_name" in
                "am-agents-labs") value="$LLM_MAX_CONCURRENT_REQUESTS" ;;
            esac ;;
        "LLM_RETRY_ATTEMPTS")
            case "$repo_name" in
                "am-agents-labs") value="$LLM_RETRY_ATTEMPTS" ;;
            esac ;;
        "UVICORN_LIMIT_CONCURRENCY")
            case "$repo_name" in
                "am-agents-labs") value="$UVICORN_LIMIT_CONCURRENCY" ;;
            esac ;;
        "UVICORN_LIMIT_MAX_REQUESTS")
            case "$repo_name" in
                "am-agents-labs") value="$UVICORN_LIMIT_MAX_REQUESTS" ;;
            esac ;;
        
        # Agent Configuration
        "AM_AGENTS_NAMES")
            case "$repo_name" in
                "am-agents-labs") value="$AM_AGENTS_NAMES" ;;
            esac ;;
        
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
        
        # RabbitMQ URLs (Docker-internal)
        "RABBITMQ_URI")
            case "$repo_name" in
                "automagik-evolution") value="amqp://rabbitmq:rabbitmq@automagik-evolution-rabbitmq:5672" ;;
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
        "CELERY_TASK_SERIALIZER")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_TASK_SERIALIZER" ;;
            esac ;;
        "CELERY_RESULT_SERIALIZER")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_RESULT_SERIALIZER" ;;
            esac ;;
        "CELERY_ACCEPT_CONTENT")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_ACCEPT_CONTENT" ;;
            esac ;;
        "CELERY_WORKER_PREFETCH_MULTIPLIER")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_WORKER_PREFETCH_MULTIPLIER" ;;
            esac ;;
        "CELERY_TASK_TRACK_STARTED")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_TASK_TRACK_STARTED" ;;
            esac ;;
        "CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP" ;;
            esac ;;
        "CELERY_BEAT_MAX_LOOP_INTERVAL")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_BEAT_MAX_LOOP_INTERVAL" ;;
            esac ;;
        "CELERY_TASK_ALWAYS_EAGER")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_TASK_ALWAYS_EAGER" ;;
            esac ;;
        "CELERY_TASK_EAGER_PROPAGATES")
            case "$repo_name" in
                "automagik-spark") value="$CELERY_TASK_EAGER_PROPAGATES" ;;
            esac ;;
        
        # Python Configuration
        "PYTHONWARNINGS")
            case "$repo_name" in
                "am-agents-labs") value="$PYTHONWARNINGS" ;;
            esac ;;
        
        # Langflow Configuration
        "LANGFLOW_API_URL")
            case "$repo_name" in
                "automagik-spark") value="$LANGFLOW_API_URL" ;;
            esac ;;
        "LANGFLOW_API_KEY")
            case "$repo_name" in
                "automagik-spark") value="$LANGFLOW_API_KEY" ;;
            esac ;;
        
        # Automagik Spark specific
        "AUTOMAGIK_REMOTE_URL")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_REMOTE_URL" ;;
            esac ;;
        "AUTOMAGIK_API_HOST")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_API_HOST" ;;
            esac ;;
        "AUTOMAGIK_API_PORT")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_API_PORT" ;;
            esac ;;
        "AUTOMAGIK_API_CORS")
            case "$repo_name" in
                "automagik-spark") value="$AUTOMAGIK_API_CORS" ;;
            esac ;;
        
        # Automagik Tools specific
        "AUTOMAGIK_BASE_URL")
            case "$repo_name" in
                "automagik-tools") value="http://automagik-spark-api:8883" ;;
            esac ;;
        "AUTOMAGIK_OPENAPI_URL")
            case "$repo_name" in
                "automagik-tools") value="http://am-agents-labs:8881/api/v1/openapi.json" ;;
            esac ;;
        "AUTOMAGIK_WORKFLOWS_BASE_URL")
            case "$repo_name" in
                "automagik-tools") value="http://am-agents-labs:8881" ;;
            esac ;;
        "GENIE_MODEL")
            case "$repo_name" in
                "automagik-tools") value="gpt-4o" ;;
            esac ;;
        
        # Evolution API specific mappings
        "AUTHENTICATION_API_KEY")
            case "$repo_name" in
                "automagik-evolution") value="${EVOLUTION_API_KEY:-namastex888}" ;;
            esac ;;
        "WA_BUSINESS_TOKEN_WEBHOOK")
            case "$repo_name" in
                "automagik-evolution") value="$EVOLUTION_API_KEY" ;;
            esac ;;
        "SERVER_URL")
            case "$repo_name" in
                "automagik-evolution") value="http://localhost:9000" ;;
            esac ;;
        "SERVER_PORT")
            case "$repo_name" in 
                "automagik-evolution") value="9000" ;;
            esac ;;
        
    esac
    
    echo "$value"
}

# Add project-specific variables that don't exist in .env.example
add_project_specific_vars() {
    local repo_name="$1"
    local config=""
    
    case "$repo_name" in
        "am-agents-labs")
            config+="# AM Agents Labs Specific Configuration\n"
            config+="DATABASE_TYPE=postgresql\n"
            config+="POSTGRES_HOST=am-agents-labs-postgres\n"
            config+="POSTGRES_PORT=5432\n"
            config+="POSTGRES_USER=postgres\n"
            config+="POSTGRES_PASSWORD=postgres\n"
            config+="POSTGRES_DB=am_agents_labs\n"
            config+="POSTGRES_POOL_MIN=10\n"
            config+="POSTGRES_POOL_MAX=25\n"
            ;;
        "automagik-spark")
            config+="# Automagik Spark Specific Configuration\n"
            config+="POSTGRES_USER=automagik\n"
            config+="POSTGRES_PASSWORD=automagik\n"
            config+="POSTGRES_DB=automagik\n"
            ;;
        "automagik-tools")
            config+="# Automagik Tools Specific Configuration\n"
            config+="HOST=127.0.0.1\n"
            config+="PORT=8000\n"
            config+="AUTOMAGIK_TIMEOUT=30\n"
            config+="AUTOMAGIK_ENABLE_MARKDOWN=true\n"
            config+="AUTOMAGIK_WORKFLOWS_TIMEOUT=7200\n"
            config+="AUTOMAGIK_WORKFLOWS_POLLING_INTERVAL=8\n"
            config+="AUTOMAGIK_WORKFLOWS_MAX_RETRIES=3\n"
            config+="GENIE_MEMORY_DB=genie_memory.db\n"
            config+="GENIE_STORAGE_DB=genie_storage.db\n"
            config+="GENIE_SESSION_ID=global_genie_session\n"
            config+="GENIE_HISTORY_RUNS=3\n"
            config+="GENIE_SHOW_TOOL_CALLS=true\n"
            config+="GENIE_MCP_CLEANUP_TIMEOUT=2.0\n"
            config+="GENIE_SSE_CLEANUP_DELAY=0.2\n"
            config+="GENIE_AGGRESSIVE_CLEANUP=true\n"
            config+="WAIT_MAX_DURATION=3600\n"
            config+="WAIT_DEFAULT_PROGRESS_INTERVAL=1.0\n"
            ;;
        "automagik-evolution")
            config+="# Evolution API Specific Configuration\n"
            config+="SERVER_TYPE=http\n"
            config+="CORS_ORIGIN=*\n"
            config+="CORS_METHODS=GET,POST,PUT,DELETE\n"
            config+="CORS_CREDENTIALS=true\n"
            config+="LOG_COLOR=true\n"
            config+="LOG_BAILEYS=error\n"
            config+="DEL_INSTANCE=false\n"
            config+="EVENT_EMITTER_MAX_LISTENERS=50\n"
            config+="DATABASE_ENABLED=true\n"
            config+="DATABASE_PROVIDER=postgresql\n"
            config+="DATABASE_CONNECTION_CLIENT_NAME=evolution_db\n"
            config+="DATABASE_SAVE_DATA_INSTANCE=true\n"
            config+="DATABASE_SAVE_DATA_NEW_MESSAGE=true\n"
            config+="DATABASE_SAVE_MESSAGE_UPDATE=true\n"
            config+="DATABASE_SAVE_DATA_CONTACTS=true\n"
            config+="DATABASE_SAVE_DATA_CHATS=true\n"
            config+="DATABASE_SAVE_DATA_LABELS=true\n"
            config+="DATABASE_SAVE_DATA_HISTORIC=true\n"
            config+="DATABASE_SAVE_IS_ON_WHATSAPP=true\n"
            config+="DATABASE_SAVE_IS_ON_WHATSAPP_DAYS=365\n"
            config+="DATABASE_DELETE_MESSAGE=false\n"
            config+="CACHE_REDIS_ENABLED=true\n"
            config+="CACHE_REDIS_PREFIX_KEY=evolution\n"
            config+="CACHE_REDIS_SAVE_INSTANCES=false\n"
            config+="CACHE_LOCAL_ENABLED=false\n"
            config+="CACHE_REDIS_TTL=604800\n"
            config+="RABBITMQ_ENABLED=true\n"
            config+="RABBITMQ_EXCHANGE_NAME=evolution\n"
            config+="RABBITMQ_GLOBAL_PREFIX=evolution\n"
            config+="RABBITMQ_EVENTS_WEBSOCKET=true\n"
            config+="WEBSOCKET_ENABLED=true\n"
            config+="WEBSOCKET_GLOBAL_EVENTS=false\n"
            config+="WA_BUSINESS_URL=https://graph.facebook.com\n"
            config+="WA_BUSINESS_VERSION=v20.0\n"
            config+="WA_BUSINESS_LANGUAGE=pt_BR\n"
            config+="S3_ENABLED=false\n"
            config+="AUTHENTICATION_TYPE=apikey\n"
            config+="AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true\n"
            config+="LANGUAGE=en\n"
            config+="API_DOCS_ENABLED=true\n"
            config+="API_DOCS_PATH=/docs\n"
            config+="CONFIG_SESSION_PHONE_VERSION=2.3000.1023204200\n"
            config+="QRCODE_LIMIT=30\n"
            config+="QRCODE_COLOR='#175197'\n"
            config+="CONFIG_SESSION_PHONE_CLIENT=Evolution API\n"
            config+="CONFIG_SESSION_PHONE_NAME=Chrome\n"
            config+="WEBHOOK_GLOBAL_ENABLED=false\n"
            config+="WEBHOOK_GLOBAL_URL=\n"
            config+="WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false\n"
            config+="INSTANCE_MAX_RETRY_QR=3\n"
            config+="INSTANCE_EXPIRATION_TIME=false\n"
            config+="TYPEBOT_ENABLED=false\n"
            config+="CHATWOOT_ENABLED=false\n"
            config+="OPENAI_ENABLED=false\n"
            config+="DIFY_ENABLED=false\n"
            config+="FILE_SIZE_MB=10\n"
            config+="WEBHOOK_EVENTS=all\n"
            ;;
    esac
    
    echo -e "$config"
}

# Generate database configuration
generate_database_config() {
    local repo_name="$1"
    local config=""
    
    case "$repo_name" in
        "am-agents-labs")
            config+="# Database Configuration (PostgreSQL mode)\n"
            config+="DATABASE_URL=\"postgresql://postgres:postgres@am-agents-labs-postgres:5432/am_agents_labs\"\n"
            ;;
        "automagik-spark")
            config+="# Database Configuration\n"
            config+="DATABASE_URL=\"postgresql+asyncpg://automagik:automagik@automagik-spark-postgres:5432/automagik\"\n"
            config+="\n"
            config+="# Celery Configuration\n"
            config+="CELERY_BROKER_URL=\"redis://automagik-spark-redis:6379/0\"\n"
            config+="CELERY_RESULT_BACKEND=\"redis://automagik-spark-redis:6379/0\"\n"
            ;;
        "automagik-evolution")
            config+="# Database Configuration\n"
            config+="DATABASE_CONNECTION_URI=\"postgresql://postgres:postgres@automagik-evolution-postgres:5432/evolution_api\"\n"
            config+="\n"
            config+="# Redis Configuration\n"
            config+="CACHE_REDIS_URI=\"redis://automagik-evolution-redis:6379\"\n"
            config+="\n"
            config+="# RabbitMQ Configuration\n"
            config+="RABBITMQ_URI=\"amqp://rabbitmq:rabbitmq@automagik-evolution-rabbitmq:5672\"\n"
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
            config+="AM_PORT=\"8881\"\n"
            config+="AM_HOST=\"0.0.0.0\"\n"
            ;;
        "automagik-spark")
            config+="# Application Configuration\n"
            config+="AUTOMAGIK_API_PORT=\"8883\"\n"
            config+="AUTOMAGIK_API_HOST=\"0.0.0.0\"\n"
            ;;
        "automagik-tools")
            config+="# Application Configuration\n"
            config+="HOST=\"0.0.0.0\"\n"
            config+="PORT=\"8000\"\n"
            ;;
        "automagik-evolution")
            config+="# Application Configuration\n"
            config+="SERVER_PORT=\"9000\"\n"
            config+="SERVER_URL=\"http://localhost:9000\"\n"
            ;;
    esac
    
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
    
    # Add project-specific variables from main .env
    add_project_specific_vars "$repo_name" >> "$env_file"
    echo "" >> "$env_file"
    
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
        
        # Get mapped value from main .env or use collected value
        local mapped_value=$(get_mapped_value "$var_name" "$repo_name")
        
        # Use mapped value if available, otherwise keep example
        if [ -n "$mapped_value" ]; then
            echo "$var_name=\"$mapped_value\"" >> "$env_file"
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