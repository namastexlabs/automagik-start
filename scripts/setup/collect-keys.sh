#!/bin/bash

# ===================================================================
# 🔑 Interactive API Key Collection System
# ===================================================================

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/colors.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# API Keys configuration
declare -A API_KEYS=(
    # OpenAI Configuration
    ["OPENAI_API_KEY"]="OpenAI API Key (required for AI functionality)"
    ["OPENAI_ORG_ID"]="OpenAI Organization ID (optional)"
    
    # Anthropic Configuration
    ["ANTHROPIC_API_KEY"]="Anthropic Claude API Key (optional but recommended)"
    
    # Google Configuration
    ["GOOGLE_API_KEY"]="Google AI API Key (optional)"
    ["GOOGLE_CSE_ID"]="Google Custom Search Engine ID (optional)"
    
    # Other AI Services
    ["GROQ_API_KEY"]="Groq API Key (optional)"
    ["TOGETHER_API_KEY"]="Together AI API Key (optional)"
    ["PERPLEXITY_API_KEY"]="Perplexity API Key (optional)"
    
    
    # External Services
    ["SERPER_API_KEY"]="Serper.dev API Key (for web search, optional)"
    ["TAVILY_API_KEY"]="Tavily API Key (for web search, optional)"
    ["BROWSERLESS_TOKEN"]="Browserless Token (for web scraping, optional)"
    
    # Evolution API (WhatsApp)
    ["EVOLUTION_API_KEY"]="Evolution API Key (for WhatsApp integration)"
    ["EVOLUTION_WEBHOOK_URL"]="Evolution Webhook URL (optional)"
    
    # Security Keys
    ["JWT_SECRET"]="JWT Secret Key (will be auto-generated if not provided)"
    ["ENCRYPTION_KEY"]="Encryption Key (will be auto-generated if not provided)"
)

# Required keys (cannot be empty) - Made optional for easier onboarding
REQUIRED_KEYS=(
    # All keys are now optional to allow users to set them up later
    # "OPENAI_API_KEY"  # Optional - users can configure later
    # "NEO4J_PASSWORD"  # Optional - will use default if not provided
)

# Keys with default values
declare -A DEFAULT_VALUES=(
)

# Collected keys storage
declare -A COLLECTED_KEYS=()

# Check if a key looks valid (simplified validation)
validate_api_key() {
    local key_name="$1"
    local key_value="$2"
    
    # Just check that the key is not empty - no strict format validation
    if [ -z "$key_value" ]; then
        log_warning "$key_name cannot be empty"
        return 1
    fi
    
    # All non-empty keys are considered valid
    return 0
}

# Generate secure random key
generate_secure_key() {
    local length="${1:-64}"
    
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex "$length"
    elif [ -f /dev/urandom ]; then
        head -c "$length" /dev/urandom | base64 | tr -d "=+/" | cut -c1-"$length"
    else
        # Fallback to a combination of date and random
        echo "${RANDOM}$(date +%s)${RANDOM}" | sha256sum | cut -d' ' -f1
    fi
}

# Collect a single API key
collect_api_key() {
    local key_name="$1"
    local description="$2"
    local is_required=false
    
    # Check if this key is required
    for required_key in "${REQUIRED_KEYS[@]}"; do
        if [ "$key_name" = "$required_key" ]; then
            is_required=true
            break
        fi
    done
    
    echo ""
    if [ "$is_required" = true ]; then
        echo -e "${RED}*${NC} ${BOLD}$key_name${NC} ${RED}(REQUIRED)${NC}"
    else
        echo -e "${CYAN}•${NC} ${BOLD}$key_name${NC} ${GRAY}(optional)${NC}"
    fi
    echo -e "  ${description}"
    
    # Show default value if available
    local default_value="${DEFAULT_VALUES[$key_name]}"
    if [ -n "$default_value" ]; then
        echo -e "  ${GRAY}Default: $default_value${NC}"
    fi
    
    # Special handling for auto-generated keys
    if [[ "$key_name" == "JWT_SECRET" || "$key_name" == "ENCRYPTION_KEY" ]]; then
        echo -e "  ${YELLOW}Press Enter to auto-generate a secure key${NC}"
    fi
    
    echo ""
    
    while true; do
        # In non-interactive mode, skip all key collection
        if [ "$INSTALL_MODE" = "automated" ]; then
            # Use default value if available
            if [ -n "$default_value" ]; then
                key_value="$default_value"
                log_info "Using default value: $default_value"
            # Auto-generate for security keys
            elif [[ "$key_name" == "JWT_SECRET" || "$key_name" == "ENCRYPTION_KEY" ]]; then
                key_value=$(generate_secure_key)
                log_success "Generated secure key (64 characters)"
            # Skip all other keys in automated mode
            else
                log_info "Skipping $key_name (automated mode)"
                return 0
            fi
        else
            # Prompt for input in interactive mode
            if [ "$is_required" = true ]; then
                read -p "Enter $key_name: " key_value
            else
                read -p "Enter $key_name (or press Enter to skip): " key_value
            fi
        fi
        
        # Handle empty input
        if [ -z "$key_value" ]; then
            # Use default value if available
            if [ -n "$default_value" ]; then
                key_value="$default_value"
                log_info "Using default value: $default_value"
            # Auto-generate for security keys
            elif [[ "$key_name" == "JWT_SECRET" || "$key_name" == "ENCRYPTION_KEY" ]]; then
                key_value=$(generate_secure_key)
                log_success "Generated secure key (64 characters)"
            # Skip if optional
            elif [ "$is_required" = false ]; then
                log_info "Skipping $key_name"
                return 0
            else
                log_error "$key_name is required and cannot be empty"
                continue
            fi
        fi
        
        # Validate the key
        if validate_api_key "$key_name" "$key_value"; then
            COLLECTED_KEYS["$key_name"]="$key_value"
            log_success "$key_name collected successfully"
            break
        else
            log_error "Invalid $key_name format. Please try again."
            if [ "$is_required" = false ]; then
                read -p "Skip this key? [y/N]: " skip_choice
                if [[ "$skip_choice" =~ ^[Yy] ]]; then
                    log_info "Skipping $key_name"
                    return 0
                fi
            fi
        fi
    done
}

# Load existing environment files
load_existing_keys() {
    log_section "Loading Existing Configuration"
    
    local env_files=(
        "$SCRIPT_DIR/../../am-agents-labs/.env"
        "$SCRIPT_DIR/../../automagik-spark/.env"
        "$SCRIPT_DIR/../../automagik-tools/.env"
        "$SCRIPT_DIR/../../automagik-evolution/.env"
    )
    
    local found_keys=()
    
    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            log_info "Loading keys from $(basename "$(dirname "$env_file")")/.env"
            
            # Read existing keys
            while IFS='=' read -r key value; do
                # Skip comments and empty lines
                [[ "$key" =~ ^#.*$ ]] && continue
                [[ -z "$key" ]] && continue
                
                # Remove quotes from value
                value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
                
                # Only load keys we're interested in
                if [[ -n "${API_KEYS[$key]}" && -n "$value" ]]; then
                    COLLECTED_KEYS["$key"]="$value"
                    found_keys+=("$key")
                fi
            done < "$env_file"
        fi
    done
    
    if [ ${#found_keys[@]} -gt 0 ]; then
        log_success "Found existing keys: ${found_keys[*]}"
        
        echo ""
        echo -e "${YELLOW}Found existing API keys. What would you like to do?${NC}"
        echo "1) Keep existing keys and only collect missing ones"
        echo "2) Re-enter all keys (overwrite existing)"
        echo "3) Review and selectively update keys"
        
        while true; do
            read -p "Choose option [1-3]: " choice
            case $choice in
                1)
                    log_info "Keeping existing keys, will only collect missing ones"
                    return 0
                    ;;
                2)
                    log_info "Will re-enter all keys"
                    COLLECTED_KEYS=()
                    return 0
                    ;;
                3)
                    review_existing_keys
                    return 0
                    ;;
                *)
                    print_warning "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    else
        log_info "No existing keys found"
    fi
}

# Review and selectively update existing keys
review_existing_keys() {
    log_section "Review Existing Keys"
    
    for key_name in "${!COLLECTED_KEYS[@]}"; do
        local key_value="${COLLECTED_KEYS[$key_name]}"
        local masked_value
        
        # Mask the key value for display
        if [ ${#key_value} -gt 10 ]; then
            masked_value="${key_value:0:6}...${key_value: -4}"
        else
            masked_value="***masked***"
        fi
        
        echo ""
        echo -e "${CYAN}$key_name${NC}: $masked_value"
        
        while true; do
            read -p "Keep this key? [Y/n/s(show)]: " choice
            case $choice in
                [Yy]|"")
                    log_info "Keeping existing $key_name"
                    break
                    ;;
                [Nn])
                    log_info "Will re-enter $key_name"
                    unset COLLECTED_KEYS["$key_name"]
                    break
                    ;;
                [Ss])
                    echo -e "${YELLOW}Full key: $key_value${NC}"
                    ;;
                *)
                    print_warning "Please enter Y (keep), N (re-enter), or S (show full key)."
                    ;;
            esac
        done
    done
}

# Collect all API keys interactively
collect_all_keys() {
    log_section "API Key Collection"
    
    log_info "This will collect API keys needed for the Automagik Suite"
    log_info "Required keys are marked with * and cannot be skipped"
    log_info "Optional keys can be added later by editing .env files"
    
    # Load existing keys first
    load_existing_keys
    
    echo ""
    log_info "Starting interactive key collection..."
    
    # Collect keys in logical groups
    local key_groups=(
        "OPENAI_API_KEY OPENAI_ORG_ID"
        "ANTHROPIC_API_KEY"
        "GOOGLE_API_KEY GOOGLE_CSE_ID"
        "GROQ_API_KEY TOGETHER_API_KEY PERPLEXITY_API_KEY"
        "NEO4J_USERNAME NEO4J_PASSWORD NEO4J_URI"
        "SERPER_API_KEY TAVILY_API_KEY BROWSERLESS_TOKEN"
        "EVOLUTION_API_KEY EVOLUTION_WEBHOOK_URL"
        "JWT_SECRET ENCRYPTION_KEY"
    )
    
    for group in "${key_groups[@]}"; do
        local group_keys=($group)
        local group_name="${group_keys[0]%_*}"
        
        echo ""
        echo -e "${BOLD}${BLUE}━━━ ${group_name} Configuration ━━━${NC}"
        
        for key_name in "${group_keys[@]}"; do
            # Skip if we already have this key
            if [[ -n "${COLLECTED_KEYS[$key_name]}" ]]; then
                log_info "Already have $key_name, skipping"
                continue
            fi
            
            # Skip if key is not in our configuration
            if [[ -z "${API_KEYS[$key_name]}" ]]; then
                continue
            fi
            
            collect_api_key "$key_name" "${API_KEYS[$key_name]}"
        done
    done
    
    # Verify all required keys are collected
    verify_required_keys
}

# Verify all required keys are present
verify_required_keys() {
    log_section "Key Verification"
    
    local missing_keys=()
    
    for required_key in "${REQUIRED_KEYS[@]}"; do
        if [[ -z "${COLLECTED_KEYS[$required_key]}" ]]; then
            missing_keys+=("$required_key")
        fi
    done
    
    if [ ${#missing_keys[@]} -gt 0 ]; then
        log_error "Missing required keys: ${missing_keys[*]}"
        
        echo ""
        echo -e "${YELLOW}Would you like to collect the missing keys now?${NC}"
        read -p "Collect missing keys? [Y/n]: " collect_choice
        
        if [[ ! "$collect_choice" =~ ^[Nn] ]]; then
            for key_name in "${missing_keys[@]}"; do
                collect_api_key "$key_name" "${API_KEYS[$key_name]}"
            done
            
            # Re-verify
            verify_required_keys
        else
            log_warning "Proceeding without required keys - some features may not work"
        fi
    else
        log_success "All required keys collected!"
    fi
}

# Display collected keys summary
show_keys_summary() {
    log_section "Collected Keys Summary"
    
    local collected_count=0
    local total_count=${#API_KEYS[@]}
    
    print_table_header
    
    for key_name in "${!API_KEYS[@]}"; do
        local status description
        
        if [[ -n "${COLLECTED_KEYS[$key_name]}" ]]; then
            status="✅ Collected"
            ((collected_count++))
        else
            status="⭕ Not Set"
        fi
        
        # Check if required
        local is_required=false
        for required_key in "${REQUIRED_KEYS[@]}"; do
            if [ "$key_name" = "$required_key" ]; then
                is_required=true
                break
            fi
        done
        
        if [ "$is_required" = true ]; then
            description="${API_KEYS[$key_name]} (REQUIRED)"
        else
            description="${API_KEYS[$key_name]}"
        fi
        
        print_table_row "$key_name" "$status" "-" "$description"
    done
    
    echo ""
    log_info "Collected $collected_count out of $total_count possible keys"
}

# Export keys to environment files
export_keys() {
    log_section "Exporting Configuration"
    
    if [ ${#COLLECTED_KEYS[@]} -eq 0 ]; then
        log_warning "No keys to export"
        return 0
    fi
    
    # Create a temporary file with all collected keys
    local temp_keys_file=$(mktemp)
    
    {
        echo "# Automagik Suite API Keys"
        echo "# Generated on $(date)"
        echo ""
        
        for key_name in "${!COLLECTED_KEYS[@]}"; do
            local key_value="${COLLECTED_KEYS[$key_name]}"
            echo "$key_name=\"$key_value\""
        done
    } > "$temp_keys_file"
    
    log_success "Keys exported to temporary file: $temp_keys_file"
    
    # Save the file path for the next script to use
    export AUTOMAGIK_KEYS_FILE="$temp_keys_file"
    
    log_info "Keys will be distributed to appropriate .env files in the next step"
    
    return 0
}

# Test API key connectivity (optional)
test_api_connectivity() {
    log_section "API Connectivity Testing"
    
    local test_results=()
    
    # Test OpenAI API
    if [[ -n "${COLLECTED_KEYS[OPENAI_API_KEY]}" ]]; then
        log_info "Testing OpenAI API connectivity..."
        
        local response=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer ${COLLECTED_KEYS[OPENAI_API_KEY]}" \
            -H "Content-Type: application/json" \
            "https://api.openai.com/v1/models" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            log_success "OpenAI API: Connected"
            test_results+=("OpenAI: ✅")
        else
            log_warning "OpenAI API: Connection failed (HTTP $response)"
            test_results+=("OpenAI: ❌")
        fi
    fi
    
    # Test Anthropic API
    if [[ -n "${COLLECTED_KEYS[ANTHROPIC_API_KEY]}" ]]; then
        log_info "Testing Anthropic API connectivity..."
        
        local response=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "x-api-key: ${COLLECTED_KEYS[ANTHROPIC_API_KEY]}" \
            -H "Content-Type: application/json" \
            "https://api.anthropic.com/v1/messages" \
            -d '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)
        
        if [ "$response" = "200" ] || [ "$response" = "400" ]; then
            log_success "Anthropic API: Connected"
            test_results+=("Anthropic: ✅")
        else
            log_warning "Anthropic API: Connection failed (HTTP $response)"
            test_results+=("Anthropic: ❌")
        fi
    fi
    
    # Show results
    if [ ${#test_results[@]} -gt 0 ]; then
        echo ""
        log_info "API Test Results: ${test_results[*]}"
    else
        log_info "No API keys to test"
    fi
}

# Main function when script is run directly
main() {
    case "${1:-collect}" in
        "collect")
            collect_all_keys
            show_keys_summary
            export_keys
            ;;
        "test")
            # Load keys first
            load_existing_keys
            test_api_connectivity
            ;;
        "show")
            load_existing_keys
            show_keys_summary
            ;;
        "export")
            load_existing_keys
            export_keys
            ;;
        *)
            echo "Usage: $0 {collect|test|show|export}"
            echo "  collect - Collect API keys interactively (default)"
            echo "  test    - Test API connectivity"
            echo "  show    - Show collected keys summary"
            echo "  export  - Export keys to temporary file"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi