#!/bin/bash

# ===================================================================
# 📝 Logging Utilities
# ===================================================================

# Source colors
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Configuration
LOG_FILE="${LOG_FILE:-automagik-install.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_TIMESTAMP="${LOG_TIMESTAMP:-true}"

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
)

# Current log level
CURRENT_LOG_LEVEL=${LOG_LEVELS[$LOG_LEVEL]}

# Initialize log file
init_logging() {
    local log_dir="$(dirname "$LOG_FILE")"
    mkdir -p "$log_dir"
    
    if [ "$LOG_TIMESTAMP" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Automagik Suite Installation Started" > "$LOG_FILE"
    else
        echo "Automagik Suite Installation Started" > "$LOG_FILE"
    fi
}

# Get timestamp
get_timestamp() {
    if [ "$LOG_TIMESTAMP" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
    else
        echo ""
    fi
}

# Core logging function
_log() {
    local level="$1"
    local message="$2"
    local color="$3"
    local symbol="$4"
    
    # Check if we should log this level
    if [ ${LOG_LEVELS[$level]} -lt $CURRENT_LOG_LEVEL ]; then
        return 0
    fi
    
    local timestamp="$(get_timestamp)"
    local log_entry="$timestamp [$level] $message"
    
    # Write to log file
    echo "$log_entry" >> "$LOG_FILE"
    
    # Print to console with color
    echo -e "${color}${symbol}${NC} ${message}"
}

# Log functions
log_debug() {
    _log "DEBUG" "$1" "$GRAY" "${INFO}"
}

log_info() {
    _log "INFO" "$1" "$CYAN" "${INFO}"
}

log_success() {
    _log "INFO" "$1" "$GREEN" "${CHECKMARK}"
}

log_warning() {
    _log "WARN" "$1" "$YELLOW" "${WARNING}"
}

log_error() {
    _log "ERROR" "$1" "$RED" "${ERROR}"
}

log_step() {
    local step="$1"
    local message="$2"
    _log "INFO" "Step $step: $message" "$BLUE" "${GEAR}"
}

log_progress() {
    local message="$1"
    _log "INFO" "$message" "$PURPLE" "${MAGIC}"
}

# Log command execution
log_command() {
    local command="$1"
    local description="$2"
    
    log_debug "Executing: $command"
    log_info "$description"
    
    if eval "$command" >> "$LOG_FILE" 2>&1; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Log with timeout
log_with_timeout() {
    local timeout="$1"
    local command="$2"
    local description="$3"
    
    log_info "$description (timeout: ${timeout}s)"
    
    if timeout "$timeout" bash -c "$command" >> "$LOG_FILE" 2>&1; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed or timed out"
        return 1
    fi
}

# Log section separator
log_section() {
    local title="$1"
    local separator=$(printf "%*s" ${#title} | tr ' ' '=')
    
    {
        echo ""
        echo "$title"
        echo "$separator"
        echo ""
    } >> "$LOG_FILE"
    
    print_section "$title"
}

# Log system info
log_system_info() {
    log_section "System Information"
    
    {
        echo "OS: $(uname -s)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Working Directory: $(pwd)"
        echo "Shell: $SHELL"
        echo "Date: $(date)"
        
        if [ -f /etc/os-release ]; then
            echo ""
            echo "OS Release Information:"
            cat /etc/os-release
        fi
        
        echo ""
        echo "Environment Variables:"
        env | grep -E "(HOME|PATH|USER|SHELL)" | sort
        
    } >> "$LOG_FILE"
    
    log_info "System information logged"
}

# Log error with stack trace
log_error_trace() {
    local error_message="$1"
    local line_number="${2:-$LINENO}"
    local function_name="${3:-main}"
    
    {
        echo ""
        echo "ERROR TRACE:"
        echo "Message: $error_message"
        echo "Line: $line_number"
        echo "Function: $function_name"
        echo "Script: ${BASH_SOURCE[1]}"
        echo "Call Stack:"
        
        local i=1
        while caller $i >> "$LOG_FILE" 2>&1; do
            ((i++))
        done
        
        echo ""
    } >> "$LOG_FILE"
    
    log_error "$error_message (line $line_number in $function_name)"
}

# Cleanup log files
cleanup_logs() {
    local days_to_keep="${1:-7}"
    local log_dir="$(dirname "$LOG_FILE")"
    
    if [ -d "$log_dir" ]; then
        find "$log_dir" -name "*.log" -type f -mtime +$days_to_keep -delete 2>/dev/null || true
        log_info "Cleaned up log files older than $days_to_keep days"
    fi
}

# Show log tail
show_log_tail() {
    local lines="${1:-50}"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "\n${CYAN}Last $lines lines from log file:${NC}"
        tail -n "$lines" "$LOG_FILE"
    else
        log_warning "Log file not found: $LOG_FILE"
    fi
}

# Export log file location
export_log_info() {
    export AUTOMAGIK_LOG_FILE="$LOG_FILE"
    log_info "Log file: $LOG_FILE"
}

# Handle script exit
handle_exit() {
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "Script completed successfully"
    else
        log_error "Script exited with code $exit_code"
    fi
    
    echo "$(get_timestamp) - Script ended with exit code $exit_code" >> "$LOG_FILE"
}

# Set up exit trap
trap 'handle_exit' EXIT

# Initialize logging when sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    init_logging
    export_log_info
fi